% EXAMPLE_AIRPORT_BPMN exemplifies the use of LINE to analize BPMN models. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

clear; 
clc;

%% input files: bpmn + extensions
filename = fullfile(pwd,'data','BPMN','parallel_2.bpmn');
extFilename = fullfile(pwd,'data', 'BPMN','parallel_2_ext.xml');

% options 
options.RTdist = 1;
options.RTrange = 0.1:0.1:0.9;
options.verbose = 1;
options.outputFolder = fullfile( pwd, 'data', 'BPMN', 'output'); 
%options.solver = 'FLUID';
options.solver = 'JMT';
[Q, U, R, X]=bpmn.solveBPMN(filename, extFilename, options);
