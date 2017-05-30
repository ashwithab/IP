% EXAMPLE_CQN_COX_ANALYSIS_1 exemplifies the use of LINE to analize CQN models 
% with Cox processing times. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

% CQN_SCB: synchronous calls with blocking
clear;
addpath(genpath('C:\Juan\line\branches\dev\src'))

M = 3;
K = 2; 

NK = [  10;
        60];
N = sum(NK);

% random environment
E = 2;
ENV = cell(E,3);
ENV{1,1} = [0.5 0.5];
ENV{1,2} = [-5 5; 0 -5];
ENV{1,3} = [0 1];
ENV{2,1} = [1 0];
ENV{2,2} = [-5 2; 0 -5];
ENV{2,3} = [1 0];

resetRules = {  '', 'noReset';
                'noReset', ''};



procTimes =  [  20   15;
                1    5];
procTimes2 = [  2    1.5;
                1    5];

think = 80*ones(1,K);
rates{1} = [   1./think;
            1./procTimes];
rates{2} = [   1./think;
            1./procTimes2];

scv = [ 1 1;
        2 5;
        1 4];
       
% Coxian processing times for each class, station, and environmental stage
phi = cell(E,M,K);
mu = cell(E,M,K);
%phases = 1; % number of exp phases
for e = 1:E
    for l = 1:M
        for k = 1:K
            [mu{e,l,k}, phi{e,l,k}] = getCoxian(1/rates{e}(l,k), scv(l,k));
        end
    end
end
% for stage 1 only
phi_e1 = cell(M,K);
mu_e1 = cell(M,K);
for l = 1:M
    for k = 1:K
        [mu_e1{l,k}, phi_e1{l,k}] = getCoxian(1/rates{1}(l,k), scv(l,k));
    end
end


Se = [   -1; 
        4;
        4];

V = zeros(M, M, K);     % resources blocked (dim 2) when executing 
                        % jobs of each class (dim 3) in station (dim 1)

V(2,3,1) = 1; % class-1 jobs block 1 resource in station 3 when executing in station 2


sched = {'inf';'ps';'ps'}; 
Pe = [zeros(K)       eye(K)   zeros(K);
     [1 0;
      0 0]          zeros(K) [0 0;
                              0 1]; 
     [0 0;
      0 1]         zeros(K,2*K)];
  
% other environmentally dependent parameters
S = cell(E,1);
P = cell(E,1);
for e = 1:E
    S{e} = Se;
    P{e} = Pe;
end

classMatch = eye(K);
refNodes = ones(K,1);
nodeNames = {'delay'; 'proc1'; 'proc1'};
classNames = cell(K,1);
for j = 1:K
    classNames{j} = ['class',int2str(j)]; 
end


%% with blocking 
myCQN = CQNREPHCoxSCB(M, K, E, N, ENV, S, V, mu, phi, sched, P, NK, classMatch, refNodes, resetRules, nodeNames, classNames);
    
max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Qb, Ub, Rb, Xb, ~, RT_CDFb, ~] = CQN_Cox_REPH_SCB_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
Qb
R1b = sum(Rb(2:3,1))
R2b = sum(Rb(2:3,2))
figure
plot(RT_CDFb{1,1}, RT_CDFb{1,2},'bx'); hold on;
plot(RT_CDFb{2,1}, RT_CDFb{2,2},'rx'); hold on;



%% without blocking
myCQN = CQNREPHCox(M, K, E, N, ENV, S, mu, phi, sched, P, NK, classMatch, refNodes, resetRules, nodeNames, classNames);

[Q, U, R, X, ~, RT_CDF, ~] = CQN_Cox_REPH_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
Q
R1 = sum(R(2:3,1))
R2 = sum(R(2:3,2))

plot(RT_CDF{1,1}, RT_CDF{1,2},'b-'); hold on;
plot(RT_CDF{2,1}, RT_CDF{2,2},'r-'); hold off;
legend('Class 1 block', 'Class 2 block', 'Class 1', 'Class 2', 'Location', 'SouthEast')
xlabel('Response Time')
ylabel('CDF')




