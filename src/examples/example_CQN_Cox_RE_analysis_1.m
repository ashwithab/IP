% EXAMPLE_CQN_COX_RE_ANALYSIS_1 exemplifies the use of LINE to analize CQN models 
% with Cox processing times and a random environment. 
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

% random environment       
E = 2;
ENV = [-3 3;
        1 -1]; 
resetRules = {  '', 'noReset';
                'noReset', ''};

% Coxian processing times for each class, station, and environmental stage
phi = cell(E,M,K);
mu = cell(E,M,K);
phases = 1; % number of exp phases
for e = 1:E
    for l = 1:M
        for k = 1:K
            mu{e,l,k} = ones(phases,1)*phases*rates(l,k); % accelerate rate
            phi{e,l,k} = [zeros(phases-1,1); 1]; % temination only at last phase
        end
    end
end

Se = [   -1; 
        ones(3,1)];

sched = {'inf';'ps';'ps';'ps'}; 
Pe = [zeros(K)       eye(K) zeros(K,2*K);
     zeros(K,2*K)   0.5*eye(K) 0.5*eye(K);
     eye(K) zeros(K,3*K);
     eye(K) zeros(K,3*K)];

S = cell(E,1);
P = cell(E,1);
for e = 1:E
    S{e} = Se;
    P{e} = Pe;
end

classMatch = eye(K);
refNodes = ones(K,1);
nodeNames = {'delay'; 'proc1';'proc2';'proc3'};
classNames = cell(K,1);
for j = 1:K
    classNames{j} = ['class',int2str(j)]; 
end

myCQN = CQN(M, K, N, Se, rates, sched, Pe, NK, classMatch, refNodes, nodeNames, classNames);
myCQNCoxRE = CQNRECox(M, K, E, N, ENV, S, mu, phi, sched, P, NK, classMatch, refNodes, resetRules, nodeNames, classNames); 
max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_Cox_RE_analysis(myCQNCoxRE, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
solver = 1;
[Q2, U2, R2, X2, ~, RT_CDF2, ~] = CQN_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, solver, verbose);

