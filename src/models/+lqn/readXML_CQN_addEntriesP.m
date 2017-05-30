function [fullP, fullMeanDemands, curProcID, visited, currentClass, classMatch,entryObj, entryGraphs, providerClasses, actGraph] = ...
    readXML_CQN_addEntriesP(...
    actGraph, processors, tasks, entries, actCalls, actProcs, K,...
    fullP, fullMeanDemands, visited, currentClass, classMatch, origClass,...
    curActIdx, curProcID, pBranch,...
    LQNprocIdx,LQNactIdx, entryObj, entryGraphs, providerNames, providerClasses, verbose, level)
% READXML_CQN_ADDENTRIESP is a recursive function that helps to build
% the queueing network model for analysis, starting from the XML file
% that describes an LQN model.
%
% Parameters:
% actGraph:         activity graph linking the activities currently under analysis
% processors:       full list and characterization of the processors
% tasks:            list of task names and their corresponding processors
% entries:          list of entries and their corresponding tasks
% actCalls:         calls made by each of the activities under analysis
% actProcs:         actual (hardware) processors
% K:                total number of classes (may vary along the search)
% fullP:            full routing matrix (for all classes)
% fullMeanDemands:  mean demands for all classes
% visited:          boolean vector with 1 if entry i if processor i was already
%                   visited by the current class
% currentClass:     current class under analysis
% curActIdx:        index of the current activity
% curProcID:        ID of the current processor
% pBranch:          last known probability of a branch
%
% Copyright (c) 2012-2017, Imperial College London
% All rights reserved.

if ~exist('verbose','var')
    verbose=false;
end
if ~exist('level','var')
    level=0;
end

M = size(visited,1); %number of stations

isJoin = actGraph(curActIdx,curActIdx) < -1;
if isJoin
    actGraph(curActIdx,curActIdx) = actGraph(curActIdx,curActIdx) + 1;
    nextActIdx = actGraph(curActIdx,:)>0;
    for j = find(nextActIdx>0)
        
        if ~isempty(actCalls{j,1})
            targetEntry = actCalls{j,1};
            targetEntryIdx = getIndexCellString({entries{:,1}}', targetEntry);
            targetTaskID = entries{targetEntryIdx,2};
            targetProcID = tasks{targetTaskID,4};
        end
    end
    fullP((curProcID-1)*K+currentClass, (targetProcID-1)*K+currentClass ) = -1;
else
    if ~isempty(curActIdx)
        %next activities to visit - columns
        nextActIdx = actGraph(curActIdx,:)>0;
        
        newPBranch = zeros(1,length(find(nextActIdx>0)));
        nextProcID = [];
        k = 1;
        for j = find(nextActIdx>0)
            LQNactIdx(end) = j; %updates activity that is being called in the current processor
            %            if verbose
            %                fprintf(1,'curActIdx=%s nextActIdx=%s currentClass=%s level=%d \n',num2str(curActIdx),num2str(j),num2str(currentClass),level);
            %            end
            
            if ~isempty(actCalls{j,1})
                targetEntry = actCalls{j,1};
                targetEntryIdx = getIndexCellString({entries{:,1}}', targetEntry);
                targetTaskID = entries{targetEntryIdx,2};
                targetProcID = tasks{targetTaskID,4};
                % if target processor is a physical processor
                if find( cell2mat( {actProcs{:,2}}) == targetProcID)
                    % proceed to determine mean demand and transition probs
                    
                    targetProcIdx = find(cell2mat({actProcs{:,2}}) == targetProcID);
                    
                    numCurProcs = length(curProcID);
                    
                    curProcIdx = zeros(numCurProcs,1);
                    for p = 1:numCurProcs
                        curProcIdx(p) = find(cell2mat({actProcs{:,2}}) == curProcID(p));
                    end
                    
                    % if next processor already visited by the current class - consider multiple current classes
                    if sum(visited(targetProcIdx,currentClass),2) == size(currentClass,1)
                        
                        % create a new class, and tie the two classes
                        %CS def
                        newClass = K+1;
                        
                        newIdx = 1:M*(K+1);
                        newIdx = reshape(newIdx,K+1,M);
                        newIdx = reshape(newIdx(1:K,:) ,1,[]);
                        newfullP = zeros(M*(K+1), M*(K+1));
                        newfullP(newIdx,newIdx) = fullP;
                        fullP = newfullP;
                        
                        for p = 1:numCurProcs
                            if actGraph(curActIdx,curActIdx) < 0 % if not a join
                                fullP((curProcIdx(p)-1)*(K+1)+currentClass(p), (targetProcIdx-1)*(K+1)+newClass ) = pBranch; %*ones(size(currentClass));
                            else
                                fullP((curProcIdx(p)-1)*(K+1)+currentClass(p), (targetProcIdx-1)*(K+1)+newClass ) = -pBranch; %*ones(size(currentClass));
                            end
                        end
                        
                        fullMeanDemands = [fullMeanDemands zeros(M,1)];
                        %just mean host demand
                        %fullMeanDemands(targetProcIdx,newClass) =...
                        %    processors(targetProcID).tasks(1).getMeanHostDemand(targetEntry);
                        % mean host demand augmented with the processor speed factor
                        fullMeanDemands(targetProcIdx,newClass) =...
                            processors(targetProcID).tasks(1).getMeanHostDemand(targetEntry)/processors(targetProcID).speedFactor;
                        
                        % update entryObj graphs - add new class
                        for procs = 1:length(processors)
                            entryGraphs( procs ) = entryGraphs( procs ).addClass();
                        end
                        
                        % mark new entryObj
                        % include calls in all higher-level entryObj to the current
                        % activity/processor only if the call is synchronous
                        if ~isempty(processors(LQNprocIdx(end)).tasks.activities(LQNactIdx(end)).synchCallDests)
                            probVisit = 1;
                            for procs = length(LQNprocIdx):-1:1
                                if isempty(entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).actNames)
                                    entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).actNames{1,1}    = ...
                                        processors(LQNprocIdx(end)).tasks.actNames{j} ;
                                else
                                    entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).actNames{end+1,1}    = ...
                                        processors(LQNprocIdx(end)).tasks.actNames{j} ;
                                end
                                entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).procs       = ...
                                    [ entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).procs;
                                    targetProcIdx ];
                                entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).classes     = ...
                                    [ entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).classes;
                                    newClass];
                                % determine probability of visit in this call,
                                % multiplying the prob of visit of all the
                                % activities in the chain of calls
                                entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).probs       = ...
                                    [ entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).probs;
                                    probVisit ];
                                probVisit = probVisit * processors(LQNprocIdx(procs)).tasks.actProbs(LQNactIdx(procs));
                                
                                % update entryObj graphs
                                for p = 1:numCurProcs
                                    entryGraphs( LQNprocIdx(procs) ) = entryGraphs( LQNprocIdx(procs) ).addConnection(...
                                        curProcIdx(p), currentClass(p), targetProcIdx, newClass, pBranch);
                                end
                            end
                            
                        end
                        
                        %add class to providers list
                        %determine activity index in providers list
                        actIndex = getIndexCellString( providerNames, targetEntry);
                        if actIndex ~= -1
                            if isempty(providerClasses{actIndex})
                                providerClasses{actIndex} = newClass;
                            else
                                providerClasses{actIndex} = [providerClasses{actIndex}; newClass];
                            end
                        end
                        
                        %if the probability is used, reset it to 1
                        pBranch = 1;
                        % update current Class and class number
                        currentClass = newClass;
                        K = K+1;
                        %update visited
                        visited = [visited zeros(M,1)];
                        visited(targetProcIdx,end) = 1;
                        
                        
                        %update matching between classes
                        classMatch = [classMatch zeros(size(classMatch,1),1)];
                        classMatch(origClass,end) = 1;
                    else %next processor different from current processor
                        
                        %CD def
                        nonVis = find(visited(targetProcIdx,currentClass) == 0); %indices of the current classes that have not visited the current processor
                        newClass = currentClass(nonVis(end)); %choose the last class among the current classes - it's enough to keep this one as the current one from now on
                        for p = 1:numCurProcs
                            if actGraph(curActIdx,curActIdx) < 0 % if not a join
                                fullP((curProcIdx(p)-1)*K+currentClass(p), (targetProcIdx-1)*K+newClass ) = -pBranch;
                            else
                                fullP((curProcIdx(p)-1)*K+currentClass(p), (targetProcIdx-1)*K+newClass ) = pBranch;
                            end
                        end
                        
                        
                        % just mean host demand
                        %fullMeanDemands(targetProcIdx,currentClass) = processors(targetProcID).tasks(1).getMeanHostDemand(targetEntry);
                        % mean host demand augmented with processor speed factor
                        fullMeanDemands(targetProcIdx,newClass) = processors(targetProcID).tasks(1).getMeanHostDemand(targetEntry)/processors(targetProcID).speedFactor;
                        
                        
                        %visited(targetProcIdx) = 1;
                        visited(targetProcIdx,newClass) = 1;
                        
                        % mark new entryObj
                        % include calls in all higher-level entryObj to the current
                        % activity/processor only if the call is synchronous
                        if ~isempty(processors(LQNprocIdx(end)).tasks.activities(LQNactIdx(end)).synchCallDests)
                            probVisit = 1;
                            for procs = length(LQNprocIdx):-1:1
                                if isempty(entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).actNames)
                                    entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).actNames{1,1}    = ...
                                        processors(LQNprocIdx(end)).tasks.actNames{j} ;
                                else
                                    entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).actNames{end+1,1}    = ...
                                        processors(LQNprocIdx(end)).tasks.actNames{j} ;
                                end
                                entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).procs       = ...
                                    [ entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).procs;
                                    targetProcIdx ];
                                entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).classes     = ...
                                    [ entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).classes;
                                    newClass];
                                
                                entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).probs       = ...
                                    [ entryObj(LQNprocIdx(procs)).actCalls(LQNactIdx(procs)).probs;
                                    probVisit ];
                                % determine probability of visit for the call one level above,
                                % multiplying the prob of visit of all the
                                % activities in the chain of calls
                                probVisit = probVisit * processors(LQNprocIdx(procs)).tasks.actProbs(LQNactIdx(procs));
                                
                                % update entryObj graphs
                                for p = 1:numCurProcs
                                    entryGraphs( LQNprocIdx(procs) ) = entryGraphs( LQNprocIdx(procs) ).addConnection(...
                                        curProcIdx(p), currentClass(p), targetProcIdx, newClass, pBranch);
                                end
                            end
                        end
                        currentClass = newClass;
                        
                        % add class to providers list
                        %determine activity index in providers list
                        actIndex = getIndexCellString( providerNames, targetEntry);
                        if actIndex ~= -1
                            if isempty(providerClasses{actIndex})
                                providerClasses{actIndex} = newClass;
                            else
                                providerClasses{actIndex} = [providerClasses{actIndex}; newClass];
                            end
                        end
                        
                        %if the probability is used, reset it to 1
                        pBranch = 1;
                    end
                    nextProcID = [nextProcID; targetProcID];
                else
                    % target processor is not a physical processor
                    % an additional layer must be covered
                    
                    myProc = processors(targetProcID);
                    myActGraph = myProc.tasks.actGraph;
                    myActCalls = myProc.tasks.actCalls;
                    myInitAct = myProc.tasks.initActID;
                    myPrecedences = myProc.tasks.precedences;
                    myCurActIdx = myInitAct; %current activities - rows
                    myCurProcID = curProcID; %delayNodeIndex;
                    
                    % save LQN info at this level
                    LQNprocIdxThisLevel = LQNprocIdx;
                    LQNactIdxThisLevel = LQNactIdx;
                    % add LQN info when going into the next level;
                    if ~isempty(processors(LQNprocIdx(end)).tasks.activities(LQNactIdx(end)).synchCallDests) % synch call -> carry indices all LQN procs involves to count for remote exec time
                        LQNprocIdx = [LQNprocIdx targetProcID];
                        LQNactIdx = [LQNactIdx myInitAct];
                    else % asynch call -> carry indices of the target processor only
                        LQNprocIdx = targetProcID;
                        LQNactIdx = myInitAct;
                    end
                    % count this call to this processor
                    entryObj(targetProcID).numCalls = entryObj(targetProcID).numCalls + 1;
                    
                    %pBranch = 1;
                    [fullP, fullMeanDemands, curProcID, visited, currentClass, classMatch, entryObj, entryGraphs, providerClasses] =...
                        lqn.readXML_CQN_addEntriesP(...
                        myActGraph, processors, tasks, entries, myActCalls, actProcs, K, ...
                        fullP, fullMeanDemands, visited, currentClass, classMatch, origClass,...
                        myCurActIdx, myCurProcID, pBranch,...
                        LQNprocIdx,LQNactIdx,entryObj, entryGraphs, providerNames, providerClasses, verbose);
                    K = size(fullP,1)/M;
                    pBranch = 1;
                    
                    %get back LQN info for this level
                    LQNprocIdx = LQNprocIdxThisLevel;
                    LQNactIdx = LQNactIdxThisLevel;
                end
            end
            newPBranch(k) = actGraph(curActIdx,j);
            k = k + 1;
        end % for j=find(nextAcdIdx>0)
        
        if ~isempty(nextProcID)
            curProcID = nextProcID;
        end
        
        %recursion for each "next" activity in the graph
        %baseClass is the currentClass that is the basis for all the next activities
        baseClass = currentClass;
        %baseProcID is the curProcID that is the basis for all the next activities
        baseProcID = curProcID;
        
        % experimental code for the fork
        %if  strcmp(precedences(curActIdx).postType,'AND') % if this activity is a fork
        isFork = sum(actGraph(curActIdx,:))>1;
        if isFork  % if this activity is a fork
            %baseClass = ones(length(baseProcID),1)*baseClass;
            curActIdx = find(nextActIdx(1,:)>0);
            %finalClasses of each branch
            finalClasses = [];
            finalProcIDs = [];
            
            for j = 1:length(curActIdx)
                [fullP, fullMeanDemands, curProcID, visited, currentClass, classMatch, entryObj, entryGraphs, providerClasses, actGraph] =...
                    lqn.readXML_CQN_addEntriesP(...
                    actGraph, processors, tasks, entries, actCalls, actProcs, K,...
                    fullP, fullMeanDemands, visited, baseClass, classMatch, origClass,...
                    curActIdx(j), baseProcID(j), pBranch*newPBranch(j),...
                    LQNprocIdx,LQNactIdx, entryObj, entryGraphs, providerNames, providerClasses, verbose,level+1);
                if ~isempty(currentClass)
                    finalClasses = [finalClasses; currentClass]; %consider multiple current classes
                    finalProcIDs = [finalProcIDs; curProcID];
                else
                    finalClasses = [finalClasses; baseClass];
                    finalProcIDs = [finalProcIDs; baseProcID(p)];
                end
                K = size(fullP,1)/M;
            end
            % return all the final classes as the current class
            currentClass = finalClasses;
            curProcID = finalProcIDs;
            %end
        else %isFork
            curActIdx = find(nextActIdx(1,:)>0);
            %finalClasses of each branch
            finalClasses = [];
            finalProcIDs = [];
            
            for j = 1:length(curActIdx)
                [fullP, fullMeanDemands, curProcID, visited, currentClass, classMatch, entryObj, entryGraphs, providerClasses, actGraph] =...
                    lqn.readXML_CQN_addEntriesP(...
                    actGraph, processors, tasks, entries, actCalls, actProcs, K,...
                    fullP, fullMeanDemands, visited, baseClass, classMatch, origClass,...
                    curActIdx(j), baseProcID, pBranch*newPBranch(j),...
                    LQNprocIdx,LQNactIdx, entryObj, entryGraphs, providerNames, providerClasses, verbose,level+1);
                if ~isempty(currentClass)
                    finalClasses = [finalClasses; currentClass]; %consider multiple current classes
                    finalProcIDs = [finalProcIDs; curProcID];
                else
                    finalClasses = [finalClasses; baseClass];
                    finalProcIDs = [finalProcIDs; baseProcID];
                end
                K = size(fullP,1)/M;
            end
            % return all the final classes as the current class
            currentClass = finalClasses;
            curProcID = finalProcIDs;
        end
    end
end

end