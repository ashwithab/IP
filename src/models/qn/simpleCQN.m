function [Q, U, R, X, RT_CDF] = simpleCQN(L,N,Z,options)
% SIMPLECQN solves a Closed Queueing Network with LINE. 
%
% Input:
% L:            demand matrix (MxK double), where M is the number of
%               (non-reference) nodes, and K is the number of classes
% N:            number of jobs of each classes (1xK integer)
% Z:            think times  for each class (1xK double) - Optional
% options.outputFolder: path of an alternative output folder
% options.RTdist:       1 if the response-time distribution is to be
%                       computed, 0 otherwise
% options.RTrange:      array of double in (0,1) with the percentiles to 
%                       evaluate the response-time distribution
% options.solver:       solver to use: 1 (fluid) or 2 (qd-amva)
% options.maxIter:      maximum number of iterations for the fluid solver
% options.verbose:      1 for screen output, 0 otherwise  
% 
% Output:
%
% Q:            mean queue-length for each station and job class 
% U:            utilization for each server
% R:            response time for each job class
% X:            throughput for each job class
% RT_CDF:       response time CDF for each chain in the CQN
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin < 4
    options = [];
end
[~, RT, RTrange, maxIter, solver, verbose] = parseOptions(options);

if nargin < 3 
    disp('Not enough input parameters specified');
    Q=0; U=0; R=0; X=0; RT_CDF = [];
    return;
elseif nargin < 4
    RT = 0;
    RTrange =[];
    verbose = 0;
elseif nargin < 5
    RTrange = 0.05:0.05;0.95;
    verbose = 0;
elseif nargin <6
    verbose = 0;
end
    
[M,K] = size(L); 
% add delay node (first)
M = M + 1;
NK = N';
N = sum(N); 

% servers and scheduling
S = [   -1;
        ones(M-1,1)];
rates = [Z; L];
sched = cell(M,1);
sched{1} = 'inf';
for i = 2:M
    sched{i} = 'ps';
end
classMatch = eye(K); 
refNodes = ones(K,1); 

% routing
P = zeros(M*K, M*K);
for k = 1:K
    myP = zeros(M);
    visited = find(rates(:,k)>0);
    orig = visited(1);
    for i = 2:length(visited);
        dest = visited(i);
        myP(orig,dest) = 1;
        orig = dest;
    end
    % complete the cycle
    dest = visited(1);
    myP(orig,dest) = 1;
    
    P(k:K:end,k:K:end) = myP;
end 

% naming
nodeNames = cell(M,1);
classNames = cell(K,1);

nodeNames{1} = 'delay';
for i = 2:M
    nodeNames{i} = ['stat',int2str(i-1)];
end
for k = 1:K
    classNames{i} = ['class',int2str(k)];
end

myCQN = CQN(M, K, N, S, rates, sched, P, NK, classMatch, refNodes, nodeNames, classNames); 

% check solver 
[solver,RT] = checkLINESolver(solver,RT,myCQN);
        
delta_max=0.01;
[Q, U, R, X,~,RT_CDF,~] = CQN_analysis(myCQN, [], [], [], maxIter, delta_max, RT, RTrange, solver, verbose);
