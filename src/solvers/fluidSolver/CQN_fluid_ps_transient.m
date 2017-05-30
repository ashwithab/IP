function [Qt, t, yt] = CQN_fluid_ps_transient(myCQN, y0, maxT, verbose)
% Q = CQN_FLUID_PS_TRANSIENT(myCQN) computes the transient queue length QN of the ODE 
% system that describes a Closed Multi-Class Queueing Network with Class Switching
% and Coxian processing times (CQNCox) myCQN. 
% 
% Parameters: 
% myCQN:      CQN model to analyze
% y0:         initial state
% maxT:       time horizon for transient analysis
% verbose:    1 for screen output, 0 otherwise
% 
% Output:
% QN:         expected number of jobs of each class in each station (fixed point)
% ymean_emb:  expected steady state vector
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

for i = 1:M
    %Set number of servers in delay station = population
    if S(i) == -1;
        S(i) = N;
    end
end



%% initialization

phases = zeros(M,K);
for i = 1:M;
    for k = 1:K
        phases(i,k) = length(Lambda{i,k});
    end
end

usestiff = 1;
%% solve ODE


% init ode
[ode_h, ~] = CQN_fluid_analysis_ps(N, Lambda, Pi, P, S);

% solve ode - Qt is the transient solution 
if usestiff == 2
    opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3);
    [t, yt] = ode23s(ode_h, [0 maxT], y0, opt);
elseif usestiff == 1
    opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3, 'NonNegative', 1:length(y0));
    [t, yt] = ode15s(ode_h, [0 maxT], y0, opt);
else
    opt = odeset('AbsTol', 1e-8, 'RelTol', 1e-5, 'NonNegative', 1:length(y0));
    [t, yt] = ode15s(ode_h, [0 maxT], y0, opt);
end

   
    

Qt = zeros(length(t), M*K);
for i=1:M
    for k = 1:K
        shiftik = sum(sum(phases(1:i-1,:))) + sum( phases(i,1:k-1) ) + 1; 
        Qt(:, (i-1)*K+k) = sum(yt(:,shiftik:shiftik+phases(i,k)-1),2);
        % computes queue length in each node and stage, suming the total
        % number in service and waiting in that station
        % results are weighted with the stat prob of the stage
    end
end

return
end