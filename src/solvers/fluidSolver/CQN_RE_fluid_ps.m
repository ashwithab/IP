function [QN, ymean_emb, piemb, iters,runtime] = CQN_RE_fluid_ps(myCQN, max_iter, delta_max, yinit, verbose)
% Q = CQN_RE_FLUID_PS(myCQN) computes the fixed point Q of the ODE 
% system that describes a Closed Multi-Class Queueing Network with Class Switching
% in a Random Environment with Coxian processing times (CQNRECox) myCQN. 
% 
% Parameters: 
% myCQN:        CQNRECox model to analyze
% max_iter:     maximum number of iterations
% delta_max:    max change in the mean vector accepted for termination
% yinit:        initial state
% verbose:      1 for screen output
% 
% Output:
% QN:           expected number of jobs of each class in each station (fixed point)
% ymean_emb:    steady state vector at epochs of environmental transition
% piemb:        stationary distribution of the environmental stage
% iters:        actual number of iterations
% runtime:      execution time in ms
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

M = myCQN.M;        %number of stations
K = myCQN.K;        %number of classes
E = myCQN.E;        %number of stages
N = myCQN.N;        %population
ENV = myCQN.ENV;    %environmental MC
Lambda = myCQN.mu;
Pi = myCQN.phi;
P = myCQN.P;
S = myCQN.S;
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
max_time = 3600; %
Tstart = tic;

if nargin < 2 || isempty(max_iter) max_iter = 100; end
if nargin < 3 || isempty(delta_max) delta_max = 1e-3; end

phases = zeros(M,K,E);
for e =1:E
    for i = 1:M;
        for k = 1:K
            phases(i,k,e) = length(Lambda{e,i,k});
        end
    end
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

%% Reset matrix: how to change service phase when the random environment changes
R = cell(E,E);
defaultRule = 'fullReset';
for h=1:E %source
    for e=[1:h-1 h+1:E] %sink
        if ENV(h,e) > 0 
            if ~strcmp(resetRules{h,e}, 'fullReset') && ~strcmp(resetRules{h,e}, 'noReset') && ~strcmp(resetRules{h,e},'adhoc') 
                disp(sprintf('Reset rule %s not supported. Replacing by %s', resetRules{h,e}, defaultRule));
                resetRules{h,e} = defaultRule;
            elseif strcmp(resetRules{h,e},'adhoc')
                if isempty(myCQN.adhocResetRules)
                    disp(['adhoc reset rule from stage ',int2str(h),' to stage ', int2str(e),' not found']);
                    disp(['Replacing by ', defaultRule]);
                    resetRules{h,e} = defaultRule;
                elseif ~iscell(myCQN.adhocResetRules) && ~size(myCQN.adhocResetRules,1) == sum(sum(phases(:,:,h))) && ~size(myCQN.adhocResetRules,2) == sum(sum(phases(:,:,e)))
                    disp(['adhoc reset rule from stage ',int2str(h),' to stage ', int2str(e),' badly specified\n. It must be a cell array of size', int2str(sum(sum(phases(:,:,h)))), ' x ', sum(sum(phases(:,:,e)))]);
                    disp(['Replacing by ', defaultRule]);
                    resetRules{h,e} = defaultRule;
                end    
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
            elseif strcmp(resetRules{h,e}, 'adhoc')
                if verbose > 0
                    disp(['Using adhoc reset rule from stage ',int2str(h),' to stage ', int2str(e)]);
                end
                R{h,e} = myCQN.adhocResetRules{h,e};
            else % no-reset
                R{h,e} = eye(sum(sum(phases(:,:,h))), sum(sum(phases(:,:,e))) );
            end
        end
    end
end
% R = cell(E,E);
% defaultRule = 'fullReset';
% for h=1:E %source
%     for e=[1:h-1 h+1:E] %sink
%         if ENV(h,e) > 0 
%             if ~strcmp(resetRules{h,e}, 'fullReset') && ~strcmp(resetRules{h,e}, 'noReset')
%                 disp(sprintf('Reset rule %s not supported. Replacing by %s', resetRules{h,e}, defaultRule));
%                 resetRules{h,e} = defaultRule;
%             end
%             if strcmp(resetRules{h,e}, 'fullReset')
%                 R{h,e} = zeros(sum(sum(phases(:,:,h))), sum(sum(phases(:,:,e)))); % size = number of queues + total number of service phases in that stage 
%                                                                             % (source stage to sink stage)
%                 indexOrig = 0; %multi source (all phases)
%                 indexDest = 1; %single dest (first phase)
%                 for i=1:M
%                     for k = 1:K
%                         R{h,e}(indexOrig+1:indexOrig+phases(i,k,h),indexDest) = ones(phases(i,k,h),1);
%                         indexDest = indexDest+phases(i,k,e);
%                         indexOrig = indexOrig+phases(i,k,e);
%                     end
%                 end
%             else % no-reset
%                 R{h,e} = eye(sum(sum(phases(:,:,h))), sum(sum(phases(:,:,e))) );
%             end
%         end
%     end
% end


%% init blending
piemb = ctmc_solve(ENV); % equilibrium dist of random environment
embweight = zeros(E,E); % embweight(e,h) is the embedded probability that the environment came from stage h when entering stage e
for e=1:E
    for h=[1:e-1,e+1:E]
        embweight(e,h) = ENV(h,e) * piemb(h);
    end
    if piemb(e) > 0
        embweight(e,:) = embweight(e,:) / sum(embweight(e,:));
    end
end


%% init vector
iters = 0;
ymean_emb = {};

for e = 1:E
    if nargin < 10 || isempty('yinit')
%         y0 = [];
%         assigned = zeros(1,K); %number of jobs of each class already assigned
%         for i = 1:M;
%             for k = 1:K
%                 if match(i,k) > 0
%                     toAssign = floor(NK(k)/sum(match(:,k)));
%                     if sum( match(i+1:end, k) ) == 0 %this is the last station for this job class
%                         toAssign = NK(k) - assigned(k);
%                     end
%                     y0 = [y0, toAssign, zeros(1,phases(i,k)-1)];
%                     assigned(k) = assigned(k) + toAssign;
%                 else
%                     y0 = [y0, zeros(1,phases(i,k))];
%                 end
%             end
% 
%         end
        y0 = zeros(1,sum(sum(phases(:,:,e)))); 
        for k = 1:K
            if myCQN.refNodes(k) > 0 && NK(k) > 0 
                idx = sum(sum( phases(1:myCQN.refNodes(k)-1,:,e) )) + sum( phases(myCQN.refNodes(k),1:k-1,e) ); 
                y0(idx+1) = NK(k);
            end
        end
        ymean_emb{iters +1,e} = y0; % average state embedded at stage change transitions out of e
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
    [ode_h{e}, ~] = CQN_RE_fluid_analysis_ps(N, reshape({Lambda{e,:,:}},M,K), reshape({Pi{e,:,:}},M,K), P{e}, S{e});
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
                if ENV(h,e) > 0
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
            T = abs(100/ENV(e,e));
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
        weight = -diff(exp(ENV(e,e) * t));
        mean_y = (yt_e(1:end-1,:)+yt_e(2:end,:))/2; 

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
            QN(i,k,e) = sum(ymean_emb{end,e}(shiftik:shiftik+phases(i,k,e)-1)) * piemb(e);
            % computes queue length in each node and stage, suming the total
            % number in service and waiting in that station
            % results are weighted with the stat prob of the stage
        end
    end
end

return
end