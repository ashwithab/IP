function [outputFolder, RT, RTrange, maxIter, solver, verbose] = parseOptions(options)
% PARSEOPTIONS parses a structure with the options for the solvers of
% different models. Sets default values if not 
% 
% Input:
% options:              structure that defines the following options: 
% options.outputFolder: path of an alternative output folder
% options.RTdist:       1 if the response-time distribution is to be
%                       computed, 0 otherwise
% options.RTrange:      array of double in (0,1) with the percentiles to 
%                       evaluate the response-time distribution
% options.solver:       type of solver to use: FLUID or QDAMVA
% options.maxIter:      maximum number of iterations for the FLUID solver
% options.verbose:      1 for screen output, 0 otherwise  
%
% Output:
% outputFolder:         path of an alternative output folder
% RT:                   1 if the response-time distribution is to be
%                       computed, 0 otherwise
% RTrange:              array of double in (0,1) with the percentiles to 
%                       evaluate the response-time distribution
% solver:               type of solver to use: FLUID or QDAMVA
% maxIter:              maximum number of iterations for the FLUID solver
% verbose:              1 for screen output, 0 otherwise  
%    
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

%% read options - set defaults if no options are provided
if nargin == 0 || (nargin == 1 && isempty(options))
    options = [];
end
if isfield(options, 'outputFolder') && ~isempty(options.outputFolder)
    if exist(options.outputFolder, 'dir')
        outputFolder = options.outputFolder;
    else
        warning(['Output folder ', options.outputFolder,' not found']);
        disp('Using default folder.');
        outputFolder = []; 
    end
else 
    outputFolder = [];
end
% RT
if isfield(options, 'RTdist') && ~isempty(options.RTdist)
    RT = options.RTdist;
else 
    RT = 0;
end
if isfield(options, 'RTrange') && ~isempty(options.RTrange)
    RTrange = options.RTrange;
    if size(RTrange,2) > 1 && size(RTrange,1) == 1
        RTrange = RTrange'; 
    elseif size(RTrange,2) > 1 && size(RTrange,1) > 1
        warning('RTrange is not a vector. Ignoring input');
        RTrange = [];
        RT = 0;
    end
else 
    RTrange = [];
end
% verbose
if isfield(options, 'verbose') && ~isempty(options.verbose)
    verbose = options.verbose;
else 
    verbose = 0;
end
% solver (auto - fluid - amva)
if sum(isfield(options,'solver')) > 0
    if strcmp(options.solver,'AUTO')
        solver = 0;
    elseif strcmp(options.solver,'FLUID')
        solver = 1;
    elseif strcmp(options.solver,'QDAMVA')
        solver = 2;
    elseif strcmp(options.solver,'JMT')
        solver = 3;
    else
        warning(['Solver option ', options.solver, ' unrecognized. Using default: AUTO - automatically selected solver.']);
        solver = 0;
    end
else
    warning('Solver not specified. Using default: FLUID solver.');
    solver = 1;
end 
% max iter
if isfield(options, 'maxIter') && ~isempty(options.maxIter)
    maxIter = options.maxIter;
else 
    maxIter = 1000;
end
