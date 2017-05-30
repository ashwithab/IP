% EXAMPLE_SIMPLEQN_1 exemplifies the use of LINE to analize QN models 
% using the simpleQN script.  
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


% test simpleCQN
L = [1 2;
     2 1];
N = [3 4];
Z = [3 3];

[Q, U, R, X, RT_CDF] = simpleCQN(L,N,Z)

options.RTdist = 1;
[Q, U, R, X, RT_CDF] = simpleCQN(L,N,Z,options)

options.RTdist = 1;
options.RTrange = 0.1:0.1:0.9;
[Q, U, R, X, RT_CDF] = simpleCQN(L,N,Z,options)

% options 
options.RTdist = 1;
options.RTrange = 0.1:0.1:0.9;
options.verbose = 1;
[Q, U, R, X, RT_CDF] = simpleCQN(L,N,Z,options)

