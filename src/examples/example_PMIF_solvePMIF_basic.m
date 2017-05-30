% EXAMPLE_PMIF_solvePMIF exemplifies the use of LINE to analize PMIF models. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

clear; 

% example 1: folder with multiple files 
options.outputFolder = fullfile( pwd, 'data', 'PMIF', 'output'); 
PMIFfilepath = fullfile( pwd, 'data', 'PMIF'); 
solvePMIF(PMIFfilepath,options)

% example 2: single file
options.outputFolder = fullfile( pwd, 'data', 'PMIF', 'output'); 
PMIFfilepath = fullfile(pwd,'data', 'PMIF', 'pmif_example_closed.xml'); 
solvePMIF(PMIFfilepath,options); 


