% EXAMPLE_PMIF_solvePMIF exemplifies the use of LINE to analize PMIF models. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

clear; 

% example 1: folder with multiple files - full options 
PMIFfilepath = fullfile( pwd,'data', 'PMIF'); 

options.RTdist = 0;
options.RTrange = 0.1:0.1:0.9;
options.verbose = 1;
options.outputFolder = fullfile( pwd, 'data', 'PMIF', 'output'); 
options.solver = 'QDAMVA'; 
solvePMIF(PMIFfilepath, options)

