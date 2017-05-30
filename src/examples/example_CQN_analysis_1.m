% EXAMPLE_CQN_ANALYSIS_2 exemplifies the use of LINE to analize CQN models. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.
clear;

M = 4;
K = 4; 
NK = [  10;
        20;
        40;
        80]; 

N = sum(NK);
classNames = cell(K,1);
for j = 1:K
    classNames{j} = ['class',int2str(j)]; 
end


procTimes =  [  1   0.5     0.25    0.125;
                2   1.0     0.50    0.250;
                4   2.0     1.00    0.500];
think = 80*ones(1,K);
rates = [   1./think;
            1./procTimes];

S = [   -1; 
        ones(3,1)];
sched = {   'inf';
            'ps';
            'ps';
            'ps'}; 
nodeNames = {   'delay'; 
                'proc1';
                'proc2';
                'proc3'
                };

            
P = [zeros(K)       eye(K)          zeros(K,2*K);
     zeros(K,2*K)   0.5*eye(K)      0.5*eye(K);
     eye(K)         zeros(K,3*K);
     eye(K)         zeros(K,3*K)
     ];
 
classMatch = eye(K);
refNodes = ones(K,1);

myCQN = CQN(M, K, N, S, rates, sched, P, NK, classMatch, refNodes, nodeNames, classNames);

max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
solver = 1;  % fluid
%solver = 3; % JMT
verbose = 1;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, solver, verbose)


