% EXAMPLE_LQN_1 exemplifies the use of LINE to analize LQN models. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

clear; 
clc;

%% input files: lqn model from OFBiz example with frontend and backend
filename = fullfile(pwd,'data','LQN','ofbizExampleFrontendBackend.xml');

% options 
options.RTdist = 2;
options.RTrange = 0.1:0.1:0.9;
options.verbose = 1;
options.solver = 'FLUID';
lqn.solveLQN(filename, '', options);

%% input files: lqn model from OFBiz example with frontend and backend - asynchronous calls to DB and payment service
filename = fullfile(pwd,'data','LQN','ofbizExampleFrontendBackendAsynch.xml');
lqn.solveLQN(filename, '', options);
