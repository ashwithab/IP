function [QN, ymean_emb, piENVsum, iters,runtime] = CQN_REPH_SCB_fluid_ps(myCQN, max_iter, delta_max, yinit, verbose)
% Q = CQN_REPH_FLUID_PS(myCQN) computes the fixed point Q of the ODE 
% system that describes a Closed Multi-Class Queueing Network with Class Switching
% in a Random Environment with PH holding times, and Coxian processing times 
% (CQNREPHCox) myCQN. 
% 
% Parameters: 
% myCQN:        CQNREPHCox model to analyze
% max_iter:     maximum number of iterations
% delta_max:    max change in the mean vector accepted for termination
% y_init:       initial state
% verbose:      1 for screen output
% 
% Output:
% QN:           expected number of jobs of each class in each station (fixed point)
% ymean_emb:    steady state vector at epochs of environmental transition
% piENVsum:     stationary distribution of the environmental stages
% iters:        actual number of iterations
% runtime:      execution time
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

M = myCQN.M;        % number of stations
K = myCQN.K;        % number of classes
E = myCQN.E;        % number of stages
N = myCQN.N;        % population
ENV = myCQN.ENV;    % environment
Lambda = myCQN.mu;
Pi = myCQN.phi;
P = myCQN.P;
S = myCQN.S;
V = myCQN.V;
NK = myCQN.NK;      %initial population
resetRules = myCQN.resetRules;

match = zeros(M,K,E); % indicates whether a class is served at a station in each stage
for e=1:E
    for i = 1:M
        for k = 1:K
            match(i,k,e) = sum(P{e}(:, (i-1)*K+k)) > 0;
        end
        %Set number of servers in delay station = population
        if S{e}(i) == -1;
            S{e}(i) = N;
        end
    end
end


%% initialization
max_time = 30; %
Tstart = tic;

if nargin < 2 || isempty(max_iter) max_iter = 100; end
if nargin < 3 || isempty(delta_max) delta_max = 1e-3; end

phases = zeros(M,K,E);
q_indices = cell(E,1);
nx = zeros(E,1);
for e =1:E
    q_indices{e} = zeros(M,K); 
    idx = 1;
    for i = 1:M;
        for k = 1:K
            phases(i,k,e) = length(Lambda{e,i,k});
            q_indices{e}(i,k) = idx;
            idx = idx + phases(i,k,e); 
        end
    end
    nx(e) = idx - 1; % total vector length
end



slowrate = zeros(M,K,E);
for e =1:E
    for i = 1:M;
        for k = 1:K
            slowrate(i,k,e) = Inf;
            slowrate(i,k,e) = min(slowrate(i,k,e),min(Lambda{e,i,k}(:))); %service completion (exit) rates in each phase
        end
    end
end
%% Build stage transition probability matrix and environment CTMC from ENV description
% environment transition probs
envP = zeros(E);
for e = 1:E
    vec = ENV{e,3}; 
    % delete nonzero diagonal entries
    if vec(e) > 0 
        vec = vec/(1-vec(e));
        vec(e) = 0;
    end
    envP(e,:) = vec; 
end
% environmental generator (size \sum_{e=1}^E m_e)
me = zeros(E,1);
for e = 1:E
    me(e) = size(ENV{e,2},1); 
end
envQ = zeros(sum(me));
for e = 1:E
    idxBase = sum(me(1:e-1));
    envQ(idxBase+1:idxBase+me(e),idxBase+1:idxBase+me(e)) = ENV{e,2};
    for h = 1:E
        if h ~= e
            envQ(idxBase+1:idxBase+me(e), sum(me(1:h-1))+1:sum(me(1:h))) = -sum(ENV{e,2},2)*ENV{h,1}*envP(e,h);
        end
    end
end




%% Reset matrix: how to change service phase when the random environment changes
R = cell(E,E);
defaultRule = 'fullReset';
for h=1:E %source
    for e=[1:h-1 h+1:E] %sink
        if envP(h,e) > 0 
            if ~strcmp(resetRules{h,e}, 'fullReset') && ~strcmp(resetRules{h,e}, 'noReset')
                disp(sprintf('Reset rule %s not supported. Replacing by %s', resetRules{h,e}, defaultRule));
                resetRules{h,e} = defaultRule;
            end
            if strcmp(resetRules{h,e}, 'fullReset')
                R{h,e} = zeros(sum(sum(phases(:,:,h))), sum(sum(phases(:,:,e)))); % size = number of queues + total number of service phases in that stage 
                                                                                        % (source stage to sink stage)
                indexOrig = 0; %multi source (all phases)
                indexDest = 1; %single dest (first phase)
                for i=1:M
                    for k = 1:K
                        R{h,e}(indexOrig+1:indexOrig+phases(i,k,h),indexDest) = ones(phases(i,k,h),1);
                        indexDest = indexDest+phases(i,k,e);
                        indexOrig = indexOrig+phases(i,k,e);
                    end
                end
            else % no-reset
                R{h,e} = eye(sum(sum(phases(:,:,h))), sum(sum(phases(:,:,e))) );
            end
        end
    end
end


%% init blending
piENV = ctmc_solve(envQ); % equilibrium dist of random environment
statCompRates = zeros(1,E); % stationary rates at which each stage completes
piENVsum = zeros(1,E); % equilibrium distribution of random environment, without considering phases 
for e=1:E
    statCompRates(e) = - piENV( sum(me(1:e-1))+1:sum(me(1:e)) ) * sum(ENV{e,2},2); % stationary stage change rates 
    piENVsum(e) = sum(piENV( sum(me(1:e-1))+1:sum(me(1:e)) )); % total stat prob in stage e
end
embweight = zeros(E,E); % embweight(e,h) is the embedded probability that the environment came from stage h when entering stage e
for e=1:E
    if piENVsum(e) > 0 
        embweight(e,:) = statCompRates'.*envP(:,e); 
        embweight(e,:) = embweight(e,:) / sum(embweight(e,:));
    end
end


%% init vector
iters = 0;
ymean_emb = {};

for e = 1:E
    if nargin < 10 || isempty('yinit')
        y0 = [];
        z0 = zeros(nx(e),1); % state of blocking jobs in station where blocking occurs
        assigned = zeros(1,K); %number of jobs of each class already assigned
        for i = 1:M;
            for k = 1:K
                if match(i,k) > 0
                    toAssign = floor(NK(k)/sum(match(:,k)));
                    if sum( match(i+1:end, k) ) == 0 %this is the last staion for this job class
                        toAssign = NK(k) - assigned(k);
                    end
                    y0 = [y0; toAssign; zeros(phases(i,k)-1,1)];
                    for w = find(V(i,:,k)>0)
                        z0(q_indices{e}(w,k)) = z0(q_indices{e}(w,k)) + toAssign; 
                    end
                    assigned(k) = assigned(k) + toAssign;
                else
                    y0 = [y0; zeros(1,phases(i,k))];
                end
            end

        end
        y0 = y0+ z0; 
        ymean_emb{iters +1,e} = y0'; % average state embedded at stage change transitions out of e
    else
        ymean_emb{iters +1,e} = yinit';
    end
end


if verbose > 0
    fprintf('\nRunning fluid analysis\n');
end
DELTA = zeros(E,1);
usestiff = 1;
odesolver={'ode15s','ode45','ode45'};
%% iterative algorithm
goon = usestiff ; % max stiff solver
iters = 0;
solveiters = 1;
ode_h = cell(E,1); %array of handlers
for e =1:E
    [ode_h{e}, ~] = CQN_SCB_fluid_analysis_ps(N, reshape({Lambda{e,:,:}},M,K), reshape({Pi{e,:,:}},M,K), P{e}, S{e}, V);
end
while goon > 0 && solveiters <= max_iter
    %for solveriters = 1:max_iter % for each iteration
    iters = iters + 1;
    if toc(Tstart) > max_time
        goon = 0;
        break;
    end
   
     for e = 1:E % for each stage in the renv
        % determine entry state vector in e
        if iters == 1 % at first iteration solve in decomposition from balanced, then at the second iteration use this as initial point instead of balanced
            y0_e = ymean_emb{iters-1 +1, e};
        else
            y0_e = 0 * ymean_emb{iters-1 +1, e};
            for h=[1:e-1,e+1:E]
                %if ENV(h,e) > 0
                if envP(h,e) > 0
                y0_e = y0_e + embweight(e,h) * ymean_emb{iters, h} * R{h,e}; % initial state for this cycle is a combination 
                                                                                  % of the final states of the previous cycles, weighting for the probability
                                                                                  % of jumping from any of the other stages, and adjusting with the reset matrix (this to
                                                                                  % take care of transitions in the service phases due to the env stage change)
                end
            end
        end
            
        if iters == 1
            nonZeroRates = slowrate(:);
            nonZeroRates = nonZeroRates( nonZeroRates >0 );
            T = abs(100/min(nonZeroRates)); % solve ode until T = 100 events with slowest exit rate
            opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3, 'NonNegative', 1:length(y0_e));
            [t, yt_e] = ode15s(ode_h{e}, [0 T], y0_e, opt);
        else
            %T = abs(100/ENV(e,e));
            T = abs(100/min(-diag(ENV{e,2})));
            % solve ode - yt_e is the transient solution in stage e
            if usestiff == 2
                opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3);
                [t, yt_e] = ode23s(ode_h{e}, [0 T], y0_e, opt);
            elseif usestiff == 1
                opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3, 'NonNegative', 1:length(y0_e));
                [t, yt_e] = ode15s(ode_h{e}, [0 T], y0_e, opt);
            else
                opt = odeset('AbsTol', 1e-8, 'RelTol', 1e-5, 'NonNegative', 1:length(y0_e));
                [t, yt_e] = ode15s(ode_h{e}, [0 T], y0_e, opt);
            end
        end
        
        % determine jump density assuming renv to be Markovian
        %weight = [(-diff(exp(ENV(e,e) * t)));0];
        weight = zeros(size(t));
        mean_y = zeros(size(yt_e,1)-1, size(yt_e,2));
        for i = 1:size(t,1)-1
            %weight(i) = -ENV{e,1}*expm(ENV{e,2}*t(i))*sum(ENV{e,2},2);
            weight(i) = ENV{e,1}*expm(ENV{e,2}*t(i))*ones(size(ENV{e,2},1),1);
            
            mean_y(i,:) = (yt_e(i,:)+yt_e(i+1,:))/2;
        end
        weight(end) = ENV{e,1}*expm(ENV{e,2}*t(end))*ones(size(ENV{e,2},1),1);
        
        %weight = [-diff(weight); 0];
        weight = -diff(weight); %determine probability of env change in [t1,t2]
        

        if iters == 1
            ymean_emb{iters +1, e} = yt_e(end,:);
        else
            % compute mean state vector embedded at the time the stage changes
            %ymean_emb{iters +1, e} = sum(yt_e .* repmat(weight,1,size(yt_e,2)),1);
            ymean_emb{iters +1, e} = sum(mean_y .* repmat(weight,1,size(mean_y,2)),1);
        end

        % update converge metric
        DELTA(e) = norm(ymean_emb{iters+1, e} - ymean_emb{iters, e}, 1) / 2;
     end
    % check termination condition
    movedJobs = max(DELTA);
    if verbose > 0
        if iters <= 2
            fprintf('it 0, mass change %.2f\n', movedJobs/N);
        else
            fprintf('it %d, %s, mass change %.3f\n', iters-2, odesolver{1+usestiff}, movedJobs/N);
        end
    end
    if movedJobs/N < delta_max , % completed
        goon = 0;
        break;
    end
    solveiters = solveiters + 1;
end


runtime = toc(Tstart);
if verbose > 0
    fprintf('Fluid analysis completed in %d iterations [%f sec]\n',iters,runtime);
end



%% set mass distribution for return
QN = zeros(M,K,E);
for e = 1:E
    for i=1:M
        for k = 1:K
            shiftik = sum(sum(phases(1:i-1,:,e))) + sum( phases(i,1:k-1,e) ) + 1; 
            QN(i,k,e) = sum(ymean_emb{end,e}(shiftik:shiftik+phases(i,k,e)-1)) * piENVsum(e); %piemb(e);
            % computes queue length in each node and stage, suming the total
            % number in service and waiting in that station
            % results are weighted with the stat prob of the stage
        end
    end
end

return
end