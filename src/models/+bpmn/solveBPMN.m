function [Q, U, R, X]=solveBPMN(filename, extFilename, options)
% SOLVEBPMN solves a BPMN model specified by the BPMN XML file FILENAME
% and the XML extension file EXTFILENAME. The extended BPMN model is
% transformed into an LQN model, solvedm and the results are saved in
% XML format in the same folder as the input file, and with the same
% name adding the suffix '-line.xml'
%
% Input:
% filename:             filepath of the BPMN XML file with the model to solve
% extFilename:          filepath of the XML extension file for the model to solve
% options.outputFolder: path of an alternative output folder
% options.RTdist:       1 if the response-time distribution is to be
%                       computed, 0 otherwise
% options.RTrange:      array of double in (0,1) with the percentiles to
%                       evaluate the response-time distribution
% options.verbose:      1 for screen output, 0 otherwise
%
% Copyright (c) 2012-2017, Imperial College London
% All rights reserved.

import bpmn.*;

if nargin < 3
    options = [];
end
[outputFolder, RT, RTrange, maxIter, solver, verbose] = parseOptions(options);
%% input files parsing
model = bpmn.parseXML_BPMN(filename, verbose);
% LINE identifies BPMN element by ID, whereas in LQN we use names. We force
% in BPMN that names and IDs are identical.
model = bpmn.replaceNamesWithIDs(model);
modelExt = bpmn.parseXML_BPMNextensions(extFilename, verbose);

if ~isempty(model) && ~isempty(modelExt)
    %% create lqn model from bpmn
    myLQN = bpmn.BPMN2LQN(model, modelExt, verbose);
    
    %% obtain line performance model from lqn
    [myCQN, entryObj, entryGraphs, processors] = lqn.LQN2CQN(myLQN, verbose);
    
    %% check solver
    [solver,RT] = checkLINESolver(solver,RT,myCQN);
   
    %% solve
    %maxIter = 1000;
    delta_max = 0.001;
    [Q, U, R, X, resEntry,RT_CDF, resSEFF_CDF] = CQN_analysis(myCQN, entryObj, entryGraphs, processors, maxIter, delta_max, RT, RTrange, solver, verbose);
    
    %% process and export results
    for i = 1:myCQN.M
        if strcmp(myCQN.sched{i},'inf')
            meanRT = sum(R([1:i-1 i+1:myCQN.M],:),1);
            break;
        end
    end
    
    %% write results
    % write results to output file
    [inputFolder, name, ~] = fileparts(filename);
    shortName = [name, '.xml'];
    if isempty(outputFolder)
        outPath = fullfile(inputFolder, shortName);
        writeXMLresults(outPath, '', myCQN, U, X, meanRT, R, resEntry, RT_CDF, resSEFF_CDF, verbose );
    else
        outPath = fullfile(outputFolder, shortName);
        writeXMLresults(outPath, '', myCQN, U, X, meanRT, R, [], RT_CDF, [], verbose );
    end
elseif isempty(model)
    disp('BPMN Model could not be created');
elseif isempty(modelExt)
    disp('BPMN Extension Model could not be created');
end
end