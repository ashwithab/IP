function solveLQN(XMLfile, EXTfile, options)
% SOLVELQN solves an LQN model specified by the LQN XML file XMLFILE 
% and, optionally, the XML extension file EXTFILE. The (extended) LQN model is 
% transformed into an LQN model, solved and the results are saved in 
% XML format in the same folder as the input file, and with the same 
% name adding the suffix '-line.xml' 
% 
% Input:
% XMLfile:              filepath of the LQN XML file with the model to solve
% EXTfile:              (optional) filepath of the XML extension file for the model to solve 
% options.outputFolder: path of an alternative output folder
% options.RTdist:       1 if the response-time distribution is to be
%                       computed, 0 otherwise
% options.RTrange:      array of double in (0,1) with the percentiles to 
%                       evaluate the response-time distribution
% options.solver:       solver to use: 1 (fluid) or 2 (qd-amva)
% options.maxIter:      maximum number of iterations for the fluid solver
% options.verbose:      1 for screen output, 0 otherwise  

%    
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

[outputFolder, RT, RTrange, maxIter, solver, verbose] = parseOptions(options);

import lqn.readXML_CQN;
import lqn.extendCQN;
delta_max = 1e-3;
REflag = 0;  %indicates if a random environment is specified
REPHflag = 0;  %indicates if a random environment with PH holding times is specified
COXflag = 0; %indicates if a coxian distribution is specified

%% parse XML files and build CQN object 
if ~isempty(XMLfile)
    if verbose > 0
        fprintf('\nReading input file(s)\n');
    end
    %load basic LQN model
    [myCQN, entry, entryGraphs, processors, activitiesProcs, activitiesClass] = readXML_CQN(XMLfile, verbose);

    % apply extensions: currently RE and Cox supported
    if ~isempty(EXTfile)
        % extend model
        [myCQN, REflag, COXflag, REPHflag] = extendCQN(myCQN, EXTfile, activitiesProcs, activitiesClass, verbose);
    end
end

%% define solver
if solver == 0 % 'AUTO'
    solver = 1; % set default solver to fluid
elseif solver == 2 % 'AMVA'
    if RT > 0 % response time distribution requested
        fprintf(['Response time distribution requested with solver QD-AMVA. \n', ...
                 'Solver AMVA cannot compute response time distributions. \n', ...
                 'Response time distributions wont be computed. \n', ...
                 'To compute response time distributions please select AUTO or FLUID solvers. \n']);
        RT = 0;
    end

    if REflag + COXflag + REPHflag > 0 % COX or RE extensions defined
        fprintf(['Coxian distributions and/or random environment requested with solver QD-AMVA. \n', ...
                 'Solver QD-AMVA cannot consider Coxian distributions nor random environments. \n', ...
                 'Solver will be modified to FLUID (1) to consider the Coxian and/or random environment. \n']);
        solver = 1;
    end

    if myCQN.C ~= myCQN.K % class switching present
        fprintf(['The queueing network features class-switching with solver QD-AMVA. \n', ...
                 'Solver QD-AMVA cannot consider queueing networks with class-switching. \n', ...
                 'Solver will be modified to FLUID (1) to consider the class-switching behavior. \n']);
        solver = 1;
    end
elseif solver == 3 % 'JMT'

    if REflag + REPHflag > 0 % COX or RE extensions defined
        fprintf(['Coxian distributions and/or random environment requested with solver JMT. \n', ...
                 'Solver JMT cannot consider random environments. \n', ...
                 'Solver will be modified to FLUID (1) to consider the random environment. \n']);
        solver = 1;
    end

elseif solver ~= 1    
    fprintf(['Solver option ', num2str(solver), ' not recognized. \n', ...
             'Using default solver: FLUID (1). \n' ]);
    solver = 1;
end

%% solve model (fluid solver and analysis)
if verbose > 0
    fprintf('\nInitializing performance solver\n');
end
if ~COXflag
    if ~REflag
        [~, U, R, X, resEntry,RT_CDF, resEntry_CDF] = CQN_analysis(myCQN, entry, entryGraphs, processors, maxIter, delta_max, RT, RTrange, solver, verbose);
    else
        [~, U, R, X, resEntry,RT_CDF, resEntry_CDF] = CQN_RE_analysis(myCQN, entry, entryGraphs, processors, maxIter, delta_max, RT, RTrange, verbose);
    end
else
    if ~REflag
        [~, U, R, X, resEntry,RT_CDF, resEntry_CDF] = CQN_Cox_analysis(myCQN, entry, entryGraphs, processors, maxIter, delta_max, RT, RTrange, verbose);
    elseif ~REPHflag
        [~, U, R, X, resEntry,RT_CDF, resEntry_CDF] = CQN_Cox_RE_analysis(myCQN, entry, entryGraphs, processors, maxIter, delta_max, RT, RTrange, verbose);
    else
        [~, U, R, X, resEntry,RT_CDF, resEntry_CDF] = CQN_Cox_REPH_analysis(myCQN, entry, entryGraphs, processors, maxIter, delta_max, RT, RTrange, verbose);
    end
end
for i = 1:myCQN.M
    if strcmp(myCQN.sched{i},'inf')
        meanRT = sum(R([1:i-1 i+1:myCQN.M],:),1);
        break;
    end
end

%% write results
% write results to output file
if ~isempty(outputFolder)
    [inputFolder, name, ~] = fileparts(filename);
    shortName = [name, '.xml']; 
    outPath = fullfile(inputFolder, shortName); 
else
    outPath = XMLfile; 
end

if REflag+COXflag == 0 
    writeXMLresults(outPath, '', myCQN, U, X, meanRT, R, resEntry, RT_CDF, resEntry_CDF, verbose );
else
    writeXMLresults(outPath, EXTfile, myCQN, U, X, meanRT, R, resEntry, RT_CDF, resEntry_CDF, verbose );
end
end
