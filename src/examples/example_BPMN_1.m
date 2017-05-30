% EXAMPLE_BPMN_1 exemplifies the use of LINE to analize BPMN models. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

clear; 
clc;

%% input files: bpmn + extensions
filename = fullfile(pwd,'data','BPMN','bpmn_gateways.bpmn');
extFilename = fullfile(pwd,'data', 'BPMN','bpmn_ext_gateways.xml');

% options 
options.RTdist = 1;
options.RTrange = 0.1:0.1:0.9;
options.verbose = 1;
options.outputFolder = fullfile( pwd, 'data', 'BPMN', 'output'); 
options.solver = 'FLUID';
bpmn.solveBPMN(filename, extFilename, options);
