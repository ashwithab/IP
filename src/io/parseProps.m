function [portNumber, maxIter, maxJobSize, verbose, parallel, timeoutConn, RT, RTrange, solver ] = parseProps(props)
% PARSEPROPS(A) parses and validates the configuration properties specified in
% the struct A
%
% Parameters:
% props:  properties struct with configuration properties
% 
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


% port number
if sum(ismember(fieldnames(props),'port')) > 0
    portNumber = props.port;
else
    disp('Port not specified. Using default: 5463.');
    portNumber = 5463;
end 

% max number of iterations
if sum(ismember(fieldnames(props),'maxIter')) > 0
    if props.maxIter >= 0
        maxIter = props.maxIter;
    else
        disp('Max Number of Iterations not recognized. Using default: 1000.');
        maxIter = 1000;
    end
else
    disp('Max Number of Iterations not specified. Using default: 1000.');
    maxIter = 1000;
end 

% max job size (number of models)
if sum(ismember(fieldnames(props),'maxJobSize')) > 0
    if props.maxJobSize >= 0
        maxJobSize = props.maxJobSize;
    else
        disp('Max Job Size not recognized. Using default: 24.');
        maxJobSize = 24;
    end
else
    disp('Max Job Size not specified. Using default: 24.');
    maxJobSize = 24;
end 

% verbose 
if sum(ismember(fieldnames(props),'verbose')) > 0
    if props.verbose == 0 || props.verbose == 1
        verbose = props.verbose;
    else
        disp('Verbose option not recognized. Using default: 0.');
        verbose = 0;
    end
else
    disp('Verbose option. Using default: 0.');
    verbose = 0;
end 

% parallel processing option 
if sum(ismember(fieldnames(props),'parallel')) > 0
    if strcmp(props.parallel,'SEQ')
        parallel = 0;
    elseif strcmp(props.parallel,'JOB')
        parallel = 1;
    elseif strcmp(props.parallel,'PARFOR')
        parallel = 2;
    else
        disp(['Parallel processing option ', props.parallel, ' non recognized. Using default: SEQ - sequential solver.']);
        parallel = 0;
    end
else
    disp('Parallel processing not specified. Using default: SEQ - sequential solver.');
    parallel = 0;
end 

% connection timeout
if sum(ismember(fieldnames(props),'timeoutConn')) > 0
    if props.timeoutConn > 0 
        timeoutConn = props.timeoutConn;
    else
        disp(['Connection timeout value ', num2str(props.timeoutConn), 'not supported. Using default: 30 s.']);
        timeoutConn = 30;
    end
else
    disp('Connection timeout not specified. Using default: 30 s.');
    timeoutConn = 30;
end 

%response time distribution 
RT=0;
RTrange=[];
if sum(ismember(fieldnames(props),'respTimePerc')) 
    if strcmp(props.respTimePerc, 'NONE') 
        RT = 0;
    elseif strcmp(props.respTimePerc, 'WORKLOAD')
        RT = 1;
    elseif strcmp(props.respTimePerc, 'ENTRY')
        RT = 2;
    else
        disp(['Response time percentile option ', props.respTimePerc, ' not recognized. Not computing percentiles.']);
    end
else
    disp('Response time percentile option not specified. Not computing percentiles.');
end 
% only parse response time percentile min, max, and step, if RT distribution is required
if RT >= 1 
    if sum(ismember(fieldnames(props),'respTimePercMin')) + sum(ismember(fieldnames(props),'respTimePercMax')) + sum(ismember(fieldnames(props),'respTimePercStep')) > 2
        if props.respTimePercMin >= 0 && props.respTimePercMax <= 1 && 0 < props.respTimePercStep && props.respTimePercStep <= 1
            RTrange = [props.respTimePercMin:props.respTimePercStep:props.respTimePercMax]';
        else
            disp('Response time percentiles parameters out of range. Not computing percentiles.');
        end
    else
        disp('Not (all) response time percentiles specified. Not computing percentiles.');
    end 
end

% solver (auto - fluid - amva)
if sum(ismember(fieldnames(props),'solver')) > 0
    if strcmp(props.solver,'AUTO')
        solver = 0;
    elseif strcmp(props.solver,'FLUID')
        solver = 1;
    elseif strcmp(props.solver,'QDAMVA')
        solver = 2;
    elseif strcmp(props.solver,'JMT')
        solver = 3;
    else
        disp(['Solver option ', props.solver, ' non recognized. Using default: AUTO - automatically selected solver.']);
        solver = 0;
    end
else
    disp('Solver not specified. Using default: AUTO - automatically selected solver.');
    solver = 0;
end 