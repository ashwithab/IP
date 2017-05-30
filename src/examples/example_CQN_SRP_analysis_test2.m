% EXAMPLE_CQN_COX_ANALYSIS_1 exemplifies the use of LINE to analize CQN models 
% with Cox processing times. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

% test simpleCQN
clear;
addpath(genpath('C:\Juan\line\branches\dev\src'))

M = 4;
K = 4; 
Mp = 2; % number of passive resources 

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
phases = 1; % number of exp phases
for l = 1:M
    for k = 1:K
        mu{l,k} = ones(phases,1)*phases*rates(l,k); % accelerate rate
        phi{l,k} = [zeros(phases-1,1); 1]; % temination only at last phase
    end
end

S = [   -1; 
        ones(3,1)];
Sp = [  5;
        10]; % number of servers in passive resources
W = zeros(M, Mp, K);    % requirement of passive resources (dim 2) for each execution 
                        % of each job class (dim 3) in each active resource (dim 1)
W(2,1,1) = 1; 
W(2,1,2) = 1; 

W(3,2,1) = 1; 
W(3,2,2) = 1; 


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

myCQN = CQNCoxSRP(M, Mp, K, N, S, Sp, W, mu, phi, sched, P, NK, classMatch, refNodes, nodeNames, classNames);


max_iter = 1000;
delta_max = 0.01;
RT = 0;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_Cox_SRP_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
Q
U
R
X


