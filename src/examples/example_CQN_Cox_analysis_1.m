% EXAMPLE_CQN_COX_ANALYSIS_1 exemplifies the use of LINE to analize CQN models 
% with Cox processing times. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

% test simpleCQN
clear;

M = 4;
K = 4; 

NK = [  100;
        200;
        400;
        800];
N = sum(NK);

procTimes =  [  1   0.5     0.25    0.125;
                2   1.0     0.50    0.250;
                4   2.0     1.00    0.500];
think = 80*ones(1,K);
rates = [   1./think;
            1./procTimes];
       
phi = cell(M,K);
mu = cell(M,K);
phases = 3; % number of exp phases
for l = 1:M
    for k = 1:K
        mu{l,k} = ones(phases,1)*phases*rates(l,k); % accelerate rate
        phi{l,k} = [zeros(phases-1,1); 1]; % temination only at last phase
    end
end

S = [   -1; 
        ones(3,1)];

sched = {'inf';'ps';'ps';'ps'}; 
P = [zeros(K)       eye(K) zeros(K,2*K);
     zeros(K,2*K)   0.5*eye(K) 0.5*eye(K);
     eye(K) zeros(K,3*K);
     eye(K) zeros(K,3*K)];
 classMatch = eye(K);
 refNodes = ones(K,1);
nodeNames = {'delay'; 'proc1';'proc2';'proc3'};
classNames = cell(K,1);
for j = 1:K
    classNames{j} = ['class',int2str(j)]; 
end

myCQN = CQN(M, K, N, S, rates, sched, P, NK, classMatch, refNodes, nodeNames, classNames);
myCQNCox = CQNCox(M, K, N, S, mu, phi, sched, P, NK, classMatch, refNodes, nodeNames, classNames);

max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_Cox_analysis(myCQNCox, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
solver = 1;
[Q2, U2, R2, X2, ~, RT_CDF2, ~] = CQN_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, solver, verbose);


