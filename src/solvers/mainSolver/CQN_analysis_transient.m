function [Qt, U, R, X, RT_CDF, t] = CQN_analysis_transient(myCQN, y0, maxT, RT, RTrange, verbose)
% [Q, U, R, X] = CQN_ANALYSIS_TRANSIENT(myCQN) computes the transient performance
% measures of a Closed Multi-Class Queueing Network with Class Switching
% (CQN) myCQN. 
% More details on this type of queueing networks can be found 
% on the LINE documentation
% 
% Parameters: 
% myCQN:        a CQN model to analyze
% processors:   list of LQN processors in the model 
% max_iter:     maximum number of iterations (termination condition)
% delta_max:    maximum difference between two succesive iterations (termination condition)
% RT:           1 if response time percentiles must be computed; 0 otherwise
% RTrange:      percentiles of the response time distribution to be  computed, if any
% verbose:      1 for screen output
% 
% Ouput:
% Q:            mean queue-length for each station and job class 
% U:            utilization for each server
% R:            response time for each job class
% X:            throughput for each job class
% RT_CDF:       response time CDF for the main classes in the LQN
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin < 4
    verbose = 0; % default no screen output 
end


myCQNCSCox = CQN2CQNCox(myCQN);
if verbose > 1 
    disp(myCQNCSCox.toString());
end

[Qt, t, yt] = CQN_fluid_ps_transient(myCQNCSCox, y0, maxT, verbose);

%% assumes the existence of a delay node through which all classes pass
delayNodes = zeros(1,myCQN.M); 
for i = 1:myCQN.M
    if strcmp(myCQN.sched{i},'inf')
        delayNodes(i) = 1;
    end
end

%% computing tput - simpler version: no chain analysis - effective throughput Tput
K = myCQN.K;
M = myCQN.M;
rates = myCQN.rates;
S = myCQN.S;
S(delayNodes>0) = myCQN.N*ones(sum(delayNodes>0),1); 

n = length(t); 
X = zeros(n,M*K);
R = zeros(n,M*K);
U = zeros(n,M);
for l = 1:n
    Q = reshape(Qt(l,:),K,M)';
    
    %tput for all classes in each station
    xi = sum(Q,2); %number of jobs in each station
    minxi = min(xi,S); %minimum between number of jobs and servers in each station

    minxi(xi>0) = minxi(xi>0)./xi(xi>0); %ratio to determine effective rate
    Xfull = Q.*rates.*(minxi*ones(1,K));
    

    %% response times + utilizations
    Rfull = zeros(myCQN.M, myCQN.K);
    for i = 1:myCQN.M
        Rfull(i, Xfull(i,:)>0) = Q(i,Xfull(i,:)>0)./Xfull(i,Xfull(i,:)>0);
    end

    UN = zeros(myCQN.M*myCQN.K,1);
    UN(myCQN.rates>0) = Xfull(myCQN.rates>0) ./ myCQN.rates(myCQN.rates>0);
    UN = reshape(UN, myCQN.M, myCQN.K);

    Ufull = sum(UN,2);
    Ufull(delayNodes==0) = Ufull(delayNodes==0)./myCQN.S(delayNodes==0);
    
    X(l,:) = reshape(Xfull', 1, []); 
    R(l,:) = reshape(Rfull', 1, []); 
    U(l,:) = Ufull'; 
end


if RT >= 1
    RT_CDF = cell(n,1);
    for l = 1:n
        max_iter = 1000;
        delta_max = 1E3; 
        RT_CDF{l} = CQN_fluid_ps_RT(myCQNCSCox, max_iter, delta_max, yt(l,:) , RTrange, verbose);
    end
else
    RT_CDF = [];
end

