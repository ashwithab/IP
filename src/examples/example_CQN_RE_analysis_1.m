% EXAMPLE_CQN_RE_ANALYSIS_1 exemplifies the use of LINE to analize CQN models 
% with a random environment. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

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
rates_base = [   1./think;
            1./procTimes];
        
E = 2;
ENV = [-3 3;
        1 -1]; 
resetRules = {  '', 'noReset';
                'noReset', ''};

S_base = [  -1; 
            ones(3,1)];
sched = {'inf';'ps';'ps';'ps'}; 


P_base = [  zeros(K)        eye(K)          zeros(K,2*K);
            zeros(K,2*K)    0.5*eye(K)      0.5*eye(K);
            eye(K)          zeros(K,3*K);
            eye(K)          zeros(K,3*K)];

rates = cell(E,1);
rates{1} = rates_base;
rates{2} = rates_base/2;


P = cell(E,1);
S = cell(E,1);
for e = 1:E
    S{e} = S_base;
    P{e} = P_base;
end

classMatch = eye(K);
refNodes = ones(K,1);
nodeNames = {'delay'; 'proc1';'proc2';'proc3'};
classNames = cell(K,1);
for j = 1:K
    classNames{j} = ['class',int2str(j)]; 
end


myCQN =     CQN(M, K, N, S_base, rates_base, sched, P_base, NK, classMatch, refNodes, nodeNames, classNames);
myCQNRE = CQNRE(M, K, E, N, ENV, S, rates, sched, P, NK, classMatch, refNodes, resetRules, nodeNames, classNames);

max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_RE_analysis(myCQNRE, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
solver = 1;
[Q2, U2, R2, X2, ~, RT_CDF2, ~] = CQN_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, solver, verbose);

