function [myCQN, entryObj, entryGraphs, processors, providers, providerClasses] = LQN2CQN(myLQN, verbose)
% Q = LQN2CQN(A) transforms an LQN object A into a Closed Multi-Class Queueing 
% Network with Class Switching (Q) for analysis. 
%
% Parameters:
% myLQN:        LQN object 
% verbose:      1 for screen output
% 
% Output:
% myCQN:    Queueing Network model for analysis
% classMatch:   0-1 matrix that describes how artificial classes correspond
%               to the original classes in the model. These artificial
%               classes are created for analysis.
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin == 1; verbose = 0; end

%[processors, tasks, entries, actProcs, ~, providers] = parseXML_LQN(filename,verbose);
processors = myLQN.processors; 
tasks = myLQN.tasks; 
entries = myLQN.entries; 
actProcs = myLQN.actProcs; 
providers = myLQN.providers; 


if ~isempty(processors) && ~isempty(tasks) && ~isempty(entries) && ~isempty(actProcs) && ~isempty(providers) 
%% build CQN model
% M: number of stations
% N: population
% S: number of servers
% rates: service rate at each node
% sched: scheduling policy in each node  \in {'inf'; 'fcfs'}; 
% nodeNames: {'delay', 'CPU'};%node names
% P: routing probabilities 

M = size(actProcs,1); % number of stations: #actual processors: processing and delay stations
S = zeros(M,1);
sched = cell(M,1);
nodeNames = cell(M,1);

check = zeros(1,M); %check nodes corresponding to processing, leaving delay as zero
for k = 1:M
    if ~isempty( find(cell2mat({providers{:,5}}) == actProcs{k,2},1 ) ) % if the proc is a provider (processing, not delay)
        procIndex = actProcs{k,2}; %index according to procID
        myProc = processors(procIndex);
        nodeNames{k} = myProc.name;
        S(k) = myProc.multiplicity;
        sched{k} = myProc.scheduling;
        check(k) = 1;
    end
end

% number of initial classes = number of delay (ref) nodes (reference tasks)
K = M - sum(check);
NK = zeros(K,1);
classNames = cell(K,1); %a name for each job class

% delay nodes
delayNodesIndex = find(check==0);
for k = 1:K
    delayProcIndex = actProcs{delayNodesIndex(k),2};
    myDelay = processors(delayProcIndex);
    NK(k) = myDelay.tasks(1).multiplicity;
    S(delayNodesIndex(k)) = -1;
    sched{delayNodesIndex(k)} = 'inf';
    nodeNames{delayNodesIndex(k)} = myDelay.name;
    classNames{k,:} = processors(delayProcIndex).name;
end
N = sum(NK);

% assume single class initially, new classes are added as the model is built 
branchProbs = 1;

%at this point: missing rates per class and station, and routing matrices per class
fullP = zeros(M*K,M*K);
fullMeanDemands = zeros(M,K);
actK = K; %actual number of classes, initially = K, may increase
classMatch = eye(K); % matching between original classes (rows) and all 
                     % classes (cols)
refNodes = zeros(K,1); 
entryObj = [];
entryGraphs = [];
for i = 1:size(processors,1)
    % num of calls to this entryObj
    thisEntry.numCalls = 0;
    %list of calls BY each of the activities of this entryObj
    thisEntry.actCalls = [];
    for j = 1:size(processors(i).tasks(1).actNames ,1)
        % name of the activity called
        thisActCall.actNames = cell(0);
        % processors called
        thisActCall.procs = [];
        % classes called
        thisActCall.classes = [];
        % probabilities of each call
        thisActCall.probs = [];
        thisEntry.actCalls = [thisEntry.actCalls; thisActCall];
    end
    entryObj = [entryObj; thisEntry]; 
    
    % initialize entryObj graphs
    thisEntryGraph = lqn.entryGraph(processors(i).name, M, K, processors(i).tasks(1).initActID);
    entryGraphs = [entryGraphs; thisEntryGraph]; 
end

% stations visited by each class
visited = zeros(M,K); 
% name of entries that provide effective resource usage
providerNames = {providers{:,2}}'; 
% QN classes associated to each of the provider entries
providerClasses = cell(1,size(providerNames,1)); 
for k = 1:K
    delayProcIndex = actProcs{delayNodesIndex(k),2};
    visited(delayNodesIndex(k),k) = 1;
    currentClass = k;
    myCurProcID = actProcs{delayNodesIndex(k),2}; %delayProcIndex;    
    myDelay = processors(delayProcIndex);
    pBranch = 1;
    refNodes(k) = delayNodesIndex(k);

    myProc = myDelay;
    myActGraph = myProc.tasks.actGraph;
    myActCalls = myProc.tasks.actCalls;
    
    % make sure that precedences are sorted identically to activity names
    % so that readXML_CQN_addEntriesP can match precedence to its internal
    % variable curActIdx
    %tmpPrecedences = myProc.tasks.precedences;
    %myPrecedences = myProc.tasks.precedences;
    %for p=1:length(tmpPrecedences)
    %    precIdx = cellfun(@(c) find(strcmp(c,tmpPrecedences(p).name)), {myProc.tasks.actNames});
    %    myPrecedences(precIdx)= tmpPrecedences(p);
    %end
 
    myInitAct = myProc.tasks.initActID;
    myCurActIdx = myInitAct; %current activities - rows
    LQNprocIdx = delayProcIndex;
    LQNactIdx = myCurActIdx;
        
    myActGraph
    for i=1:length(myActGraph)
        fprintf(1,'%d %s\n',i,myProc.tasks.actNames{i});
    end
    
    fullMeanDemands(delayNodesIndex(k),k) = myDelay.tasks.thinkTime;
    [fullP, fullMeanDemands, myCurProcID, visited, currentClass, classMatch, entryObj, entryGraphs, providerClasses] = ...
                        lqn.readXML_CQN_addEntriesP(...
                        myActGraph, processors, tasks, entries, myActCalls, actProcs, actK, ...
                        fullP, fullMeanDemands, visited, currentClass, classMatch, k,...
                        myCurActIdx, myCurProcID, pBranch,...
                        LQNprocIdx, LQNactIdx, entryObj, entryGraphs, providerNames, providerClasses, verbose);                        
    % transitions back to the delay node - consider multiple final procs and
    % classes
    actK = size(fullP,1)/M;
    for j = 1:length(myCurProcID)
        lastProc = processors(myCurProcID(j));
        lastProcIdx = getIndexCellString({actProcs{:,1}}', lastProc.name);
        % transitions back to the delay node, into class k, completing chain representation
        if sum(fullP((lastProcIdx-1)*actK+currentClass(j), :))==0 % don't add for fork
            fullP((lastProcIdx-1)*actK+currentClass(j), (delayNodesIndex(k)-1)*actK+k ) = 1;
        end
    end
end

%total number of classes
fullK = size(fullP,1)/M;
%rates for all the classes
fullRates = zeros(M*fullK,1);
fullRates(fullMeanDemands > 0) = 1./fullMeanDemands(fullMeanDemands > 0);
fullRates = reshape(fullRates, M, fullK);
%numbers per class
fullNK = [NK;zeros(fullK-K,1)];
%classnames
fullClassNames = cell(fullK,1);
fullClassNames(1:K) = classNames;
for k = K+1:fullK
    fullClassNames{k} = ['artificialClass', int2str(k-K)];
end
%all reference nodes
fullRefNodes = zeros(fullK,1);
fullRefNodes(1:K) = refNodes;

% eliminate unnecessary classes (zero demand) - full representation
for j = 1:fullK
    % classes with routing probabilities == 0
    if max(max(fullP(:,j:fullK:fullK*M) )) == 0
        idx = [1:j-1 j+1:fullK];
        idx2 = [1:j-1 j+1:K];
        fullIdx = reshape(1:M*fullK,fullK,M);
        fullIdx = reshape(fullIdx(idx,:),1,[]);
        
        %new distribution of job numbers - no rounding
        fullNK = fullNK(idx);   % removing jobs from irrelevant classes
        branchProbs = branchProbs(idx2)/sum(branchProbs(idx2));
       
        fullRates = fullRates(:,idx);
        fullP = fullP(fullIdx,fullIdx);
        N = sum(fullNK);        % removing jobs from irrelevant classes
        fullClassNames = fullClassNames(idx,:);
        fullK = fullK - 1; 
       
        classMatch = [classMatch(idx2,idx2) classMatch(idx2,K+1:end)];
        K = K-1;
    end
end

%% final model
myCQN = CQN(M, fullK, N, S, fullRates, sched, fullP, fullNK, classMatch, fullRefNodes, nodeNames, fullClassNames);

else
   disp(['Error: Incomplete description for LQN model ', myLQN.name]);
   myCQN = [];
   entryObj = [];
   entryGraphs = [];
   processors = [];
   providers = [];
   providerClasses = [];
end

