function [QN, ymean,iters,runtime] = CQN_fluid_ps(myCQN, max_iter, delta_max, yinit, verbose)
% Q = CQN_FLUID_PS(myCQN) computes the fixed point Q of the ODE 
% system that describes a Closed Multi-Class Queueing Network with Class Switching
% and Coxian processing times (CQNCox) myCQN. 
% 
% Parameters: 
% myCQN:      CQN model to analyze
% max_iter:   maximum number of iterations
% delta_max:  max change in the mean vector accepted for termination
% y_init:        initial state
% 
% Output:
% QN:         expected number of jobs of each class in each station (fixed point)
% ymean_emb:  expected steady state vector
% iters:      actual number of iterations
% usesstiff:  indicator of whether stiff solvers were used or not
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

M = myCQN.M;    %number of stations
K = myCQN.K;    %number of classes
N = myCQN.N;    %population
Lambda = myCQN.mu;
Pi = myCQN.phi;
P = myCQN.P;
S = myCQN.S;
NK = myCQN.NK;  %initial population

match = zeros(M,K); % indicates whether a class is served at a station
for i = 1:M
    for k = 1:K
        match(i,k) = sum(P(:, (i-1)*K+k)) > 0;
    end
    %Set number of servers in delay station = population
    if S(i) == -1;
        S(i) = N;
    end
end



%% initialization
max_time = Inf; %30;%
Tstart = tic;

if nargin < 2 || isempty(max_iter) max_iter = 100; end
if nargin < 3 || isempty(delta_max) delta_max = 1e-3; end

phases = zeros(M,K);
for i = 1:M;
    for k = 1:K
        phases(i,k) = length(Lambda{i,k});
    end
end
slowrate = zeros(M,K);
for i = 1:M;
    for k = 1:K
        slowrate(i,k) = Inf;
        slowrate(i,k) = min(slowrate(i,k),min(Lambda{i,k}(:))); %service completion (exit) rates in each phase
    end
end


iters = 0;
ymean = {};
if nargin < 10 || isempty('yinit')
    y0 = [];
    assigned = zeros(1,K); %number of jobs of each class already assigned
    for i = 1:M;
        for k = 1:K
            if match(i,k) > 0
                toAssign = floor(NK(k)/sum(match(:,k)));
                if sum( match(i+1:end, k) ) == 0 %this is the last staion for this job class
                    toAssign = NK(k) - assigned(k);
                end
                y0 = [y0, toAssign, zeros(1,phases(i,k)-1)];
                assigned(k) = assigned(k) + toAssign;
            else
                y0 = [y0, zeros(1,phases(i,k))];
            end
        end

    end
    ymean{iters +1} = y0(:)'; % average state embedded at stage change transitions out of e
else
    ymean{iters +1} = yinit';
end


DELTA = 1e8;
usestiff = 1;
odesolver={'ode15s','ode45','ode45'};
%% iterative algorithm
goon = usestiff ; % max stiff solver
iters = 0;
solveiters = 1;
allt=[];
ally =[];
while goon > 0 && solveiters <= max_iter
    iters = iters + 1;
    if toc(Tstart) > max_time
        goon = 0;
        break;
    end
    % determine entry state vector in e
    y0 = ymean{iters-1 +1};

    % init ode
    [ode_h, ~] = CQN_fluid_analysis_ps(N, Lambda, Pi, P, S);

    if iters == 1
        nonZeroRates = slowrate(:);
        nonZeroRates = nonZeroRates( nonZeroRates >0 );
        T = abs(10/min(nonZeroRates)); % solve ode until T = 100 events with slowest exit rate

        opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3, 'NonNegative', 1:length(y0));
        [t, yt_e] = ode15s(ode_h, [0 T], y0, opt);

    else
        T = abs(10/min(nonZeroRates));
        % solve ode - yt_e is the transient solution in stage e
        if usestiff == 2
            opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3);
            [t, yt_e] = ode23s(ode_h, [0 T], y0, opt);
        elseif usestiff == 1
            opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3, 'NonNegative', 1:length(y0));
            [t, yt_e] = ode15s(ode_h, [0 T], y0, opt);
        else
            opt = odeset('AbsTol', 1e-8, 'RelTol', 1e-5, 'NonNegative', 1:length(y0));
            [t, yt_e] = ode15s(ode_h, [0 T], y0, opt);
        end
    end
    ymean{iters +1} = yt_e(end,:);
    DELTA = norm(ymean{iters +1} - ymean{iters-1 +1}, 1) / 2;
    
    if isempty(allt)
        allt = t;
    else
        allt = [allt; allt(end)+t];
    end
    ally = [ally; yt_e];
    
    % check termination condition
    movedJobs = DELTA;
    if verbose > 1
        if iters <= 2
            fprintf('it 0, init, mass change  %.2f\n', movedJobs/N);
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

QN = zeros(M,K);
for i=1:M
    for k = 1:K
        shiftik = sum(sum(phases(1:i-1,:))) + sum( phases(i,1:k-1) ) + 1; 
        QN(i,k) = sum(ymean{end}(shiftik:shiftik+phases(i,k)-1));
        % computes queue length in each node and stage, suming the total
        % number in service and waiting in that station
        % results are weighted with the stat prob of the stage
    end
end

return
end