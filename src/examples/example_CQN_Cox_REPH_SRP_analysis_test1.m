% EXAMPLE_CQN_COX_REPH_ANALYSIS_1 exemplifies the use of LINE to analize CQN models 
% with Cox processing times and a random environment with phase-type 
% holding times. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

% test simpleCQN
clear;

M = 2;
Mp = 1; 
K = 2; 

NK = [  10;
        40];
N = sum(NK);

procTimes =  [  20 15];
procTimes2 =  [  2 1.5];
think = 80*ones(1,K);
rates{1} = [   1./think;
            1./procTimes];
rates{2} = [   1./think;
            1./procTimes2];

scv = [ 1 1;
        2 5];

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


% Coxian processing times for each class, station, and environmental stage
phi = cell(E,M,K);
mu = cell(E,M,K);

phi_e1 = cell(M,K);
mu_e1 = cell(M,K);

%phases = 1; % number of exp phases
for e = 1:E
    for l = 1:M
        for k = 1:K
            %mu{e,l,k} = ones(phases,1)*phases*rates(l,k); % accelerate rate
            %phi{e,l,k} = [zeros(phases-1,1); 1]; % temination only at last phase
            [mu{e,l,k}, phi{e,l,k}] = getCoxian(1/rates{e}(l,k), scv(l,k));
        end
    end
end

for l = 1:M
    for k = 1:K
        [mu_e1{l,k}, phi_e1{l,k}] = getCoxian(1/rates{1}(l,k), scv(l,k));
    end
end


Se = [   -1; 
          4];
Spe = [1]; % number of servers in passive resources
W = zeros(M, Mp, K);    % requirement of passive resources (dim 2) for each execution 
                        % of each job class (dim 3) in each active resource (dim 1)
W(2,1,1) = 1; 
%W(2,1,2) = 1; 

sched = {'inf';'ps'}; 
Pe = [zeros(K)       eye(K);
     eye(K)         zeros(K)];

S = cell(E,1);
Sp = cell(E,1);
P = cell(E,1);
for e = 1:E
    S{e} = Se;
    Sp{e} = Spe;
    P{e} = Pe;
end

classMatch = eye(K);
refNodes = ones(K,1);
nodeNames = {'delay'; 'proc1'};
classNames = cell(K,1);
for j = 1:K
    classNames{j} = ['class',int2str(j)]; 
end

%% w/out RE
myCQN = CQNCoxSRP(M, Mp, K, N, Se, Spe, W, mu_e1, phi_e1, sched, Pe, NK, classMatch, refNodes, nodeNames, classNames);
max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 1;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_Cox_SRP_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
Q
U
R(2,:)

%% with RE

myCQNREPH = CQNREPHCoxSRP(M, Mp, K, E, N, ENV, S, Sp, W, mu, phi, sched, P, NK, classMatch, refNodes, resetRules, nodeNames, classNames); 
max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 0;
[Q, U, R, X, ~, RT_CDF, ~] = CQN_Cox_REPH_SRP_analysis(myCQNREPH, [], [], [], max_iter, delta_max, RT, RTrange, verbose);
Q
U
R(2,:)
plot(RT_CDF{1,1}, RT_CDF{1,2}); hold on;
plot(RT_CDF{2,1}, RT_CDF{2,2}, 'r'); hold off;


