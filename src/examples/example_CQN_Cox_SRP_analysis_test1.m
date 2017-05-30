% EXAMPLE_CQN_COX_ANALYSIS_1 exemplifies the use of LINE to analize CQN models 
% with Cox processing times. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

% test simpleCQN
clear;
addpath(genpath('C:\Juan\line\branches\dev\src'))

M = 2;
K = 2; 
Mp = 1; % number of passive resources 

NK = [  20;
        40];
N = sum(NK);

procTimes =  [  20   15];
think = 80*ones(1,K);
rates = [   1./think;
            1./procTimes];
scv = [ 1 1;
        2 5];
phi = cell(M,K);
mu = cell(M,K);
%phases = 1; % number of exp phases
% for l = 1:M
%     for k = 1:K
%         mu{l,k} = ones(phases,1)*phases*rates(l,k); % accelerate rate
%         phi{l,k} = [zeros(phases-1,1); 1]; % temination only at last phase
%     end
% end
for i = 1:M
    for j = 1:K
        [mu{i,j}, phi{i,j}] = getCoxian(1/rates(i,j), scv(i,j));
    end
end

S = [   -1; 
        4];
Sp = [1]; % number of servers in passive resources
W = zeros(M, Mp, K);    % requirement of passive resources (dim 2) for each execution 
                        % of each job class (dim 3) in each active resource (dim 1)
W(2,1,1) = 1; 
%W(2,1,2) = 1; 



sched = {'inf';'ps'}; 
P = [zeros(K)       eye(K);
     eye(K)         zeros(K)];
classMatch = eye(K);
refNodes = ones(K,1);
nodeNames = {'delay'; 'proc1'};
classNames = cell(K,1);
for j = 1:K
    classNames{j} = ['class',int2str(j)]; 
end

myCQN = CQNCoxSRP(M, Mp, K, N, S, Sp, W, mu, phi, sched, P, NK, classMatch, refNodes, nodeNames, classNames);
    
max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_Cox_SRP_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
Q
U
R(2,:)
plot(RT_CDF{1,1}, RT_CDF{1,2}); hold on;
plot(RT_CDF{2,1}, RT_CDF{2,2}, 'r'); hold off;
