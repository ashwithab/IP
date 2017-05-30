classdef LINE_obj
% LINE_OBJ defines the LINE object that processes the models, calling
% the necessary scripts to parse the XML description, solve the performance
% model, and export the resuls to an XML file
% 
% Properties:
% myCluster:    cluster to solve models in parallel
% myJobs:       list of jobs submitted to the cluster
% jobTasks:     list of file names of the tasks in each job 
% jobTaskREs:   filenames (RE-XML) of tasks (models) in each job
% maxIter:      maximum number of iterations of the blending algorithm
% RT            1 if response time distribution is to be computed; 0 otherwise
% RTrange:      range for the computation of RT distribution
% PARALLEL:     0 for sequential execution, 1 for job-based parallel execution, 2 for parfor execution
% verbose:      1 for screen output, 0 otherwise
%    
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.
    
properties
    myCluster;      % parallel cluster
    myJobs;         % list of jobs submitted to the cluster
    jobTasks;       % filenames (LQN-XML) of tasks (models) in each job
    jobTaskREs;     % filenames (RE-XML) of tasks (models) in each job
    maxIter;        % maximum number of iterations of the blending algorithm
    RT = 0;         % 1 if response time distribution is to be computed; 0 otherwise
    RTrange = [];   % range for the computation of RT distribution
    PARALLEL = 0;   % 0 for sequential execution, 1 for job-based parallel execution, 2 for parfor execution
    solver = 0;     % 0 for automatic selection, 1 for fluid solver, 2 for amva solver
    verbose;        % 1 for screen output, 0 otherwise
end
    
methods
    %% constructor
    function obj = LINE_obj(maxIter, PARALLEL, RT, RTrange, solver, verbose)
        %parallel.importProfile('lineClusterProfile.settings');
        obj.myCluster = parcluster();
        obj.myJobs = cell(0);
        obj.maxIter = maxIter;
        obj.RT = RT;
        obj.RTrange = RTrange;
        obj.PARALLEL = PARALLEL;
        obj.solver = solver;
        obj.verbose = verbose;
        if obj.PARALLEL == 2
            matlabpool(obj.myCluster);
        end
            
    end
    
    %% clean 
    function obj = clean(obj)
        n = size(obj.myJobs,1);
        for j = 1:n
            delete(obj.myJobs{j});
        end
        obj.myJobs = cell(0);
        obj.jobTasks = cell(0);
        obj.jobTaskREs = cell(0);
    end
    
    %% close cluster 
    function obj = closeCluster(obj)
        if obj.PARALLEL == 2
            matlabpool close;
        end
    end

    %% General function to solve a set of models
    function obj = solve(obj, XMLfiles, REfiles)
        switch obj.PARALLEL
            % sequential
            case 0
                obj.solveSeq(XMLfiles, REfiles);
            % parallel using the cluster engine    
            case 1
                obj = obj.solvePara(XMLfiles, REfiles);
            % parallel using the parfor
            case 2
                obj.solveParaParfor(XMLfiles, REfiles);
        end
    end
    
    %% Function to solve models in parallel
    function obj = solvePara(obj, XMLfiles, REfiles)
        myJob = createJob(obj.myCluster);
        createTask(myJob,@solve_multi,0,{{XMLfiles, REfiles, obj.maxIter, obj.RT, obj.RTrange, obj.solver, obj.verbose}});
        
        submit(myJob);
        obj.myJobs{end+1,1} = myJob;
        obj.jobTasks{end+1,1} = XMLfiles;
        obj.jobTaskREs{end+1,1} = REfiles;
    end
    
    %% Function to solve models sequentially 
    function obj = solveSeq(obj, XMLfiles, REfiles)
        solve_multi(XMLfiles, REfiles, obj.maxIter, obj.RT, obj.RTrange, obj.solver, obj.verbose);
    end
    
    %% Function to solve models sequentially 
    function obj = solveParaParfor(obj, XMLfiles, REfiles)
        solve_multi_parfor(XMLfiles, REfiles, obj.maxIter, obj.RT, obj.RTrange, obj.solver, obj.verbose);
    end
    
end
    
end

%% solves multiple LQN models sequentially 
function solve_multi(XMLfiles, EXTfiles, maxIter,RT,RTrange,solver,verbose)
    n = size(XMLfiles,1);
    for j = 1:n
        XMLfile = XMLfiles{j};
        EXTfile = EXTfiles{j};
        solve(XMLfile, EXTfile, maxIter,RT,RTrange,solver,verbose);
    end
end

%% solves multiple LQN models in parallel using parfor
function solve_multi_parfor(XMLfiles, EXTfiles, maxIter,RT,RTrange,solver,verbose)
    n = size(XMLfiles,1);
    parfor j = 1:n
        XMLfile = XMLfiles{j};
        EXTfile = EXTfiles{j};
        solve(XMLfile, EXTfile, maxIter,RT,RTrange,solver,verbose);
    end
end

%% solves an LQN model from a serialized XML
function solve(XMLfile, EXTfile, maxIter,RT,RTrange,solver,verbose)
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
            fprintf(['Warning: Response time distribution requested with solver QD-AMVA. ', ...
                     'Solver QD-AMVA cannot compute response time distributions. ', ...
                     'Response time distributions wont be computed. ', ...
                     'To compute response time distributions please select AUTO or FLUID solvers. ']);
            RT = 0;
        end
        
        if REflag + COXflag + REPHflag > 0 % COX or RE extensions defined
            fprintf(['Warning: Coxian distributions and/or random environment requested with solver QD-AMVA. ', ...
                     'Solver QD-AMVA cannot consider Coxian distributions nor random environments. ', ...
                     'Solver will be modified to FLUID (1) to consider the Coxian and/or random environment. ']);
            solver = 1;
        end
        
        if myCQN.C ~= myCQN.K % class switching present
            fprintf(['Warning: The queueing network features class-switching with solver QD-AMVA. ', ...
                     'Solver QD-AMVA cannot consider queueing networks with class-switching. ', ...
                     'Solver will be modified to FLUID (1) to consider the class-switching behavior. ']);
            solver = 1;
        end
        
    elseif solver ~= 1
        fprintf(['Warning: Solver option ', num2str(solver), ' not recognized. ', ...
                 'Using default solver: FLUID (1). ' ]);
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
    if REflag+COXflag == 0 
        writeXMLresults(XMLfile, '', myCQN, U, X, meanRT, R, resEntry, RT_CDF, resEntry_CDF, verbose );
    else
        writeXMLresults(XMLfile, EXTfile, myCQN, U, X, meanRT, R, resEntry, RT_CDF, resEntry_CDF, verbose );
    end
end