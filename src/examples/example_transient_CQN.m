%% example transient analysis
% This example illustrates how to use the CQN_analysis_transient
% function in LINE to perform a transient analysis of a Multi-Class 
% Queueing Network with Class Switching
% 
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.



M = 2; 
K = 2;
N = 20; 
S = [-1;
      1];
rates = [   1   0.5;
            10  3]; 

sched = cell(M,1);
sched{1} = 'inf'; 
sched{2} = 'ps';

P = zeros(M*K, M*K); 
P(1:K, K+1:2*K) = eye(K);
P(K+1:2*K, 1:K) = eye(K);

NK = [15 5];
classMatch = eye(K);
refNodes = [1;
            1];

nodeNames = cell(M,1);
nodeNames{1} = 'delay'; 
nodeNames{2} = 'processor'; 
classNames = {  'class1'; 
                'class2'}; 

myCQN = CQN(M, K, N, S, rates, sched, P, NK, classMatch, refNodes, nodeNames, classNames); 

%% steady-state analysis
maxIter = 100;
delta_max = 10E-3; 
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Q, U, R, X, ~,RT_CDF, ~] = CQN_analysis(myCQN, [], [], [], maxIter, delta_max, RT, RTrange, verbose);


%% transient analysis
maxT = 1; 
yinit = [15 5 0 0]; % initial point (and results) specified as a row indexed 
                    % first by station and then by class -> entry j = (i-1)*K+k 
                    % refers to station i, class k 
[Qt, Ut, Rt, Xt, RT_CDFt, t] = CQN_analysis_transient(myCQN, yinit, maxT, RT, RTrange, verbose);

n = length(t); 
RT99 = zeros(n,K);
for j = 1:n
    for k = 1:K
        RT99(j,k) = RT_CDFt{j}{k,1}(end);
    end
end
plot(t,RT99)
xlabel('time')
ylabel('RT99')
legend('class1', 'class2', 'Location', 'NorthWest')





