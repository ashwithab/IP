% EXAMPLE_LQN_2 exemplifies the use of LINE to analize LQN models 
% with an extension file to model Coxian processing times and 
% random environments (REs) that have phase-type (PH) holding times 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

clear; 
clc;

%% input files: bpmn + extensions
filename = fullfile(pwd,'data','LQN','ofbizExample.xml');
extFilename = fullfile(pwd,'data', 'LQN','ofbizExample_REPHCox.xml');

% options 
options.RTdist = 2;
options.RTrange = 0.1:0.1:0.9;
options.verbose = 1;
options.solver = 'FLUID';
lqn.solveLQN(filename, extFilename, options);

