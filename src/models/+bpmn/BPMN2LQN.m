function myLQN = BPMN2LQN(bp, bp_ext, verbose)
% A = BPMN2LQN(B) transforms a BPMN (Business Process Model Notation) Collaboration model
% B into an LQN (Layered Queueing Network) model 
% 
% Parameters:
% bp:           BPMN model 
% bp_ext:       BPMN model extension - resources and task-resource list
% verbose:      1 for screen output
% 
% Output:
% lqn:          LQN model
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

    import bpmn.*;
    import lqn.*;

    if ~isempty(bp) && ~isempty(bp_ext)
        name = bp.name; 
        myLQN = lqn.lqn(name); 
        n = length(bp.process); % number of processes = initial number of processors and tasks
        %listBPMNTasks = []; % list of tasks: name - id - 
        
        % counters and indices for processors and tasks
        procID = 1;
        taskID = 1;
        
        %% 1. create one LQN processor and task for each resource defined in the BPMN extension
        m = length(bp_ext.resources);
        for i = 1:m 
            % processor constructor 
            name = bp_ext.resources(i).name;
            multiplicity = bp_ext.resources(i).multiplicity;
            scheduling = bp_ext.resources(i).scheduling; 
            quantum = 1E-3;     % default
            speedFactor = 1;    % default - should remain like this

            myProc = processor([name, '_processor'], multiplicity, scheduling, quantum, speedFactor); 
            myProc.ID = bp_ext.resources(i).id;

            % tasks constructor - default
            multiplicity = 1;       % default
            scheduling = 'inf';     % default
            thinkTime = 0;          % default
            activityGraph = 'YES';  % default
            myTask =  lqn.task([name, '_task'], multiplicity, scheduling, thinkTime, activityGraph);

            % create an Entry for each BPMN Task executed by this Resource
            numTasks = size(bp_ext.resources(i).assignments,1); 
            for j = 1:numTasks
                myEntry = entry([bp_ext.resources(i).assignments{j,1}, '_entry'], 'NONE');
                %name  = [bp_ext.resources(i).assignments{j,1}, '_activity']; 
                name  = [bp_ext.resources(i).assignments{j,1}]; 
                phase = 1; 
                boundToEntry = ''; 
                hostDemandMean = BPMNtime2sec(bp_ext.resources(i).assignments{j,2}); 
                myActivity = lqn.activity(name, phase, hostDemandMean, boundToEntry); 
                myEntry = myEntry.addActivity(myActivity); 
                myTask = myTask.addEntry(myEntry); 
                
                % add entry to list of entries 
                myLQN.entries{end+1,1} = myEntry.name;
                myLQN.entries{end,2} = taskID;
                
                % add activity to the list of providers - resource demanding activity 
                myLQN.providers{end+1,1} = myActivity.name;
                myLQN.providers{end,2} = myEntry.name;
                myLQN.providers{end,3} = myTask.name;
                myLQN.providers{end,4} = myProc.name;
                myLQN.providers{end,5} = procID;
            end

            myProc = myProc.addTask(myTask);
            myLQN = myLQN.addProcessor(myProc); 
            
            % add task to list of tasks
            myLQN.tasks{end+1,1} = myTask.name;
            myLQN.tasks{end,2} = taskID;
            myLQN.tasks{end,3} = myProc.name;
            myLQN.tasks{end,4} = procID;
            
            % add each of these processor as an actual processor (real resources)
            myLQN.actProcs{end+1,1} = myProc.name;
            myLQN.actProcs{end,2} = procID;
            myLQN.actProcs{end,3} = myTask.name;
            myLQN.actProcs{end,4} = taskID;
            
            % increase counters 
            procID = procID + 1;
            taskID = taskID + 1;
        end
        
        %% 2. create one LQN processor and task for each BPMN process
        % identify processes that generate workload and those that don't
        refProcesses = zeros(1,n);
        for i = 1:n 
            numSE = length(bp.process(i).startEvents); 
            if numSE == 1 
                refProcesses(i) = 1;
            end
        end
        % buils a list of all messages: ID - sourceProcess - sourceElement - targetProcess - targetElement
        msgList = createMsgList(bp); 
        
        % create a request-reply list, specifying, for each request message the corresponding reply message
        reqReply = createReqReplyList(bp, refProcesses, msgList); 
        
        % check there is only one reference process
        if sum(refProcesses) > 1
            % throw exception - more than one start event 
            errID =  'BPMN:NonSupportedFeature:MoreThanOneStartEvent'; 
            errMsg = 'There are %d processes with a start event. Maximum one Process with a Start Event is supported.';
            err = MException(errID, errMsg, sum(refProcesses));
            throw(err)
        elseif sum(refProcesses) < 1
            % throw exception - no start event specified 
            errID =  'BPMN:NonSupportedFeature:NoStartEvent'; 
            errMsg = 'There are no processes with a start event. One Start Event must be specified.';
            err = MException(errID, errMsg);
            throw(err)
        end
        
        %% 2.a. analyze BPMN processes WITHOUT start events - create entries
        for i = find(refProcesses==0) 
            % indexes of messages that point to this process
            idxMsg = find(cell2mat(msgList(:,4))==i)'; 
            for j = idxMsg 
                % create pseudo task and processor for each incoming message
                if isempty(find(reqReply(:,3)==j,1)) % check that message is NOT a REPLY to this PROCESS (thus not an entry)
                    % processor constructor - default
                    name = [bp.process(i).name,'_MSG_', msgList{j,1}];
                    multiplicity = 1;   % default
                    scheduling = 'inf'; % default
                    quantum = 1E-3;     % default
                    speedFactor = 1;    % default - should remain like this
                    myProc = processor([name, '_processor'], multiplicity, scheduling, quantum, speedFactor); 

                    % tasks constructor - default
                    multiplicity = 1;       % default
                    scheduling = 'inf';     % default
                    thinkTime = 0;          % default
                    activityGraph = 'YES';  % default
                    myTask =  lqn.task([name, '_task'], multiplicity, scheduling, thinkTime, activityGraph);

                    % default entry
                    myEntry = entry([name, '_entry'], 'NONE');
                    myTask = myTask.addEntry(myEntry); 

                    % generate Task Activity graph starting from Element that recives the Message 
                    myTask = generateTaskActivityGraph(bp.process(i),myTask, msgList{j,5}, bp_ext, myLQN, msgList, reqReply,{bp.process.name}');

                    % add entry to list of entries 
                    myLQN.entries{end+1,1} = myEntry.name;
                    myLQN.entries{end,2} = taskID;

                    myProc = myProc.addTask(myTask);
                    myLQN = myLQN.addProcessor(myProc); 

                    % add task to list of tasks
                    myLQN.tasks{end+1,1} = myTask.name;
                    myLQN.tasks{end,2} = taskID;
                    myLQN.tasks{end,3} = myProc.name;
                    myLQN.tasks{end,4} = procID;

                    % increase counters 
                    procID = procID + 1;
                    taskID = taskID + 1;
                end
            end
        end
        
        %% 2.b. analyze BPMN processes WITH start events 
        for i = find(refProcesses==1) 
            % processor constructor - default
            name = bp.process(i).name;
            multiplicity = 1;   % default
            scheduling = 'inf'; % default
            quantum = 1E-3;     % default
            speedFactor = 1;    % default - should remain like this
            myProc = processor([name, '_processor'], multiplicity, scheduling, quantum, speedFactor); 

            % tasks constructor - default
            multiplicity = 1;       % default
            scheduling = 'inf';     % default
            thinkTime = 0;          % default
            activityGraph = 'YES';  % default
            myTask =  lqn.task([name, '_task'], multiplicity, scheduling, thinkTime, activityGraph);


            % check if current processor has a start event -> reference task (workload)
            numSE = length(bp.process(i).startEvents); 
            if numSE == 1
                % only processes with at most 1 start event are supported *****
                
                if ~isempty(bp_ext.startEvents) 
                    idxSE = getIndexCellString({bp_ext.startEvents.id}', bp.process(i).startEvents.id); 
                    if idxSE == -1
                        % throw exception - start event not specified 
                        errID =  'BPMN:Extension:StartEventNotDefined'; 
                        errMsg = 'Process %s has a start event %s not defined in the BPMN extension';
                        err = MException(errID, errMsg, bp.process(i).name, bp.process(i).startEvents.id);
                        throw(err)
                    else
                        myTask.multiplicity = bp_ext.startEvents(idxSE).multiplicity;
                        myTask.thinkTime = bpmn.BPMNtime2sec(bp_ext.startEvents(idxSE).thinkTime);
                    end
                else
                    % throw exception - no starstart event not specified 
                    errID =  'BPMN:Extension:NoStartEventsDefined'; 
                    errMsg = 'No Start Events have been defined in the BPMN extension';
                    err = MException(errID, errMsg);
                    throw(err)
                end

                % generate Task Activity graph starting from Start Event
                myTask = generateTaskActivityGraph(bp.process(i),myTask, bp.process(i).startEvents(1).id, bp_ext, myLQN, msgList, reqReply, {bp.process.name}');

                % add this processor and task as actual processor - workload 
                myLQN.actProcs{end+1,1} = myProc.name;
                myLQN.actProcs{end,2} = procID;
                myLQN.actProcs{end,3} = myTask.name;
                myLQN.actProcs{end,4} = taskID;
                
            else %if numSE > 1
                % throw exception - non supported feature
                errID = 'BPMN:NonSupportedFeature:ManyStartEvents'; 
                errMsg = 'Process %s has %d start events';
                err = MException(errID, errMsg, name, numSE);
                throw(err)
            end

            myProc = myProc.addTask(myTask);
            myLQN = myLQN.addProcessor(myProc); 
            
            % add task to list of tasks
            myLQN.tasks{end+1,1} = myTask.name;
            myLQN.tasks{end,2} = taskID;
            myLQN.tasks{end,3} = myProc.name;
            myLQN.tasks{end,4} = procID;
            
            % increase counters 
            procID = procID + 1;
            taskID = taskID + 1;
        end

    else
        if isempty(bp)
            disp('Error: BPMN2LQN - Empty BPMN model');
            myLQN = [];
        end
        if isempty(bp_ext)
            disp('Error: BPMN2LQN - Empty BPMN model extension');
            myLQN = [];
        end
    end

end

function myTask = generateTaskActivityGraph(proc, myTask, initElemID, bp_ext, myLQN, msgList, reqReply, processNames)
    % Build the task activity graph, including activities, their calls,
    % precedences, 
    %
    % proc:         BPMN process under analysis
    % myTask:       LQN task that represents the BPMN process
    % initElemID:   id of the initial element
    % bp_ext:       BPMN extension
    % myLQN:        lqn model
    % msgList:      list of all messages: ID - sourceProcess - sourceElement - targetProcess - targetElement
    % reqReply:     list of request-reply pairs: originitagin process - output (request) Message - input (reply) Message 
        
    
    % list all flow elements in the process - nx3 string cell: each row
    % with id - type - index within type
    flowElements = cell(0,3);
    elementTypes = {'tasks';'sendTasks';'receiveTasks';
                    'exclusiveGateways'; 'parallelGateways'; 'inclusiveGateways';
                    'startEvents'; 'endEvents'; 'intermediateThrowEvents'; 'intermediateCatchEvents'}; 
    for i = 1:size(elementTypes,1)
        var = eval(['proc.',elementTypes{i}]);
        if ~isempty(var)
            for j = 1:length(var)
                flowElements{end+1,1} = var(j).id;
                flowElements{end,2} = elementTypes{i};
                flowElements{end,3} = int2str(j);
            end
        end
    end
    
    % list of links in the process - nx3 sring cell, each row with id -
    % source - target
    links = cell(length(proc.sequenceFlows),3);
    for i = 1:length(proc.sequenceFlows)
        links{i,1} = proc.sequenceFlows(i).id; 
        links{i,2} = proc.sequenceFlows(i).sourceRef; 
        links{i,3} = proc.sequenceFlows(i).targetRef; 
    end
    
    
    % choose start event (unique) as first flow element
    currFlowElement = initElemID; 
    currIdx = getIndexCellString(flowElements(:,1), currFlowElement);
    n = size(flowElements,1); 
    elemGraph = zeros(n,n); 
    initElement = currIdx; 
    
    idxChecked = zeros(n,1);  % 0-1 vector, 1 for a checked flow element
    idxToCheck = zeros(n,1);  % 0-1 vector, 1 for a flow element discovered but not checked
    idxToCheck(currIdx) = 1;
    
    actNames = cell(n,1);  % names of all the activities - as many as flow elements
    actCalls = cell(n,1); % names of the entries called by each activity, if any
    exclGateways = zeros(n,1); % 0-1 vector, 1 if the flow element is an exclusive gateway
    parallGateways = zeros(n,1); % 0-1 vector, 1 if the flow element is an exclusive gateway
    sendReqElems = zeros(n,1);  % 0-1 vector, 1 if the flow element is a sendTask or an 
                                % intermediateThrowEvent that sends a REQUEST Message
    
    while sum(idxChecked) < n
        currIdx = find(idxToCheck,1); 
        currType = flowElements{currIdx,2};
        currElement = eval(['proc.', currType,'(',flowElements{currIdx,3},')']);
        
        %myActName = [currElement.name,'_activity']; 
        myActName = currElement.name; 
        myAct = lqn.activity(myActName, [], 0, ''); 
        actNames{currIdx} = myActName;         
        
        if strcmp( currType, 'exclusiveGateways') 
            exclGateways(currIdx) = 1;
        end
        if strcmp( currType, 'parallelGateways') 
            parallGateways(currIdx) = 1;
        end
        
        % list of outgoing links
        outLinks = currElement.outgoing; 
        m_out = size(outLinks,1); 
        posts = cell(m_out,1); 
        postsIdx = zeros(m_out,1); 
        for j = 1:m_out
            outLinkIdx = getIndexCellString(links(:,1), outLinks{j});
            % index of target node 
            outIdx = getIndexCellString(flowElements(:,1), links{outLinkIdx,3}); 
            
            posts{j} = flowElements{outIdx,1}; 
            postsIdx(j) = outIdx; 
            % add out nodes not checked yet to list of nodes to check 
            if idxToCheck(outIdx) == 0 && idxChecked(outIdx) == 0 
                idxToCheck(outIdx) = 1; 
            end
        end
        % connect elements that submit messages to the elements that
        % receive the reply (as output element)
        if strcmp( currType, 'sendTasks') || strcmp( currType, 'intermediateThrowEvents')
            idxMsgOut = getIndexCellString(msgList(:,3), currElement.id); % index of the message sent 
            idxMsgIn = reqReply(find(reqReply(:,2)==idxMsgOut,1),3); % index of the reply message 
            if ~isempty(idxMsgIn)
                sendReqElems(currIdx) = 1;
                destElem = msgList{idxMsgIn, 5 }; % id of the element that receives the reply message
                destElemIdx = getIndexCellString(flowElements(:,1), destElem); % index of the same element
                
                % connect current element to destElem
                m_out = 1; 
                posts = {destElem};
                postsIdx = destElemIdx; 
                % add out nodes not checked yet to list of nodes to check 
                if idxToCheck(destElemIdx) == 0 && idxChecked(destElemIdx) == 0 
                    idxToCheck(destElemIdx) = 1; 
                end
            end
        end 
        
        % list of incoming links - only to check for nodes without incoming
        % flows (i.e., intermediate message events)
        inLinks = currElement.incoming; 
        m_in = size(inLinks,1); 
        pres = cell(m_in,1); 
        presIdx = zeros(m_in,1); 
        for j = 1:m_in
            inLinkIdx = getIndexCellString(links(:,1), inLinks{j});
            % index of source node 
            inIdx = getIndexCellString(flowElements(:,1), links{inLinkIdx,2}); 
            
            pres{j} = flowElements{inIdx,1}; 
            presIdx(j) = inIdx; 
            % add in nodes not checked yet to list of nodes to check 
            if idxToCheck(inIdx) == 0 && idxChecked(inIdx) == 0 
                idxToCheck(inIdx) = 1; 
            end
        end
        
        %% Create precedence and build activity graph
        if m_in <= 1
            if m_in == 1
                preType = 'single';
            else 
                preType = '';
            end
            if m_out == 1
                postType = 'single'; 
                postProbs = 1;
                elemGraph(currIdx,postsIdx(1)) = 1; 
            elseif m_out > 1
                if strcmp( currType, 'exclusiveGateways') 
                    postType = 'OR'; 
                    %gateIdx = getIndexCellString({bp_ext.exclusiveGateways(str2num(flowElements{currIdx,3})).id}', currElement.id);
                    gateIdx = getIndexCellString({bp_ext.exclusiveGateways.id}', currElement.id);
                    if gateIdx == -1 
                        % throw exception - gateway not properly defined 
                        errID = 'BPMN:ExclusiveGateways:NoRoutingProbabilities'; 
                        errMsg = 'Routing probabilities for exclusive gateway %s have not been provided in extension file.';
                        err = MException(errID, errMsg, currElement.id);
                        throw(err)
                    else
                        postProbs = zeros(m_out,1); 
                        for j = 1:m_out
                            %elemIdx = getIndexCellString( bp_ext.exclusiveGateways(str2num(flowElements{currIdx,3})).outgoingLinks(:,1), currElement.outgoing{j});
                            elemIdx = getIndexCellString( bp_ext.exclusiveGateways(gateIdx).outgoingLinks(:,1), currElement.outgoing{j});
                            if elemIdx == -1 
                                % throw exception - gateway not properly defined 
                                errID = 'BPMN:ExclusiveGateways:NoRoutingProbabily:Link'; 
                                errMsg = 'Routing probability for link %s in exclusive gateway %s has not been provided in extension file.';
                                err = MException(errID, errMsg, posts{j}, currElement.id);
                                throw(err)
                            else
                                %postProbs(j) = bp_ext.exclusiveGateways(str2num(flowElements{currIdx,3})).outgoingLinks{elemIdx,2}; 
                                postProbs(j) = bp_ext.exclusiveGateways(gateIdx).outgoingLinks{elemIdx,2}; 
                                elemGraph(currIdx,postsIdx(j)) = postProbs(j); 
                            end
                        end
                    
                    end
                elseif strcmp( currType, 'parallelGateways') 
                    postType = 'AND'; 
                    postProbs = ones(m_out,1);
%                    gateIdx = getIndexCellString({bp_ext.parallelGateways.id}', currElement.id)
                    elemGraph(currIdx,postsIdx) = postProbs'; 
                else
                    % throw exception - non supported feature
                    errID = 'BPMN:NonSupportedFeature:Gateways'; 
                    errMsg = 'Element of type %s has %d outgoing links. Not supported feature.';
                    err = MException(errID, errMsg, currType, m_out);
                    throw(err)
                end
            else % m_out = 0
                postType = '';
                postProbs = []; 
            end
        else
            if m_out > 1
                % throw exception - non supported feature
                errID = 'BPMN:NonSupportedFeature:MultiInputMultiOutput'; 
                errMsg = 'Element %s of type %s has % incoming and %d outgoing links. Multi input and output elements are not supported. ';
                err = MException(errID, errMsg, currElement.id, currType, m_in, m_out);
                throw(err)
            else
                if m_out == 0 
                    postType = '';
                    postProbs = 0;
                else
                    postType = 'single';
                    postProbs = 1;
                    elemGraph(currIdx, postsIdx) = 1; 
                end
                
                if strcmp( currType, 'exclusiveGateways') 
                    preType = 'OR'; 
                elseif strcmp( currType, 'parallelGateways') 
                    preType = 'AND'; 
                    elemGraph(currIdx,currIdx) = -m_in; 
                else
                    % throw exception - non supported feature
                    errID = 'BPMN:NonSupportedFeature:Gateways'; 
                    errMsg = 'Element of type %s has %d incoming links. Not supported feature.';
                    err = MException(errID, errMsg, currType, m_in);
                    throw(err)
                end
                
            end
        end
        myPrec = lqn.precedence(myActName, pres, posts, preType, postType, postProbs);         
        myTask = myTask.addPrecedence(myPrec); 
        
        %% add direct calls to resources 
        if strcmp(currType,'tasks') || strcmp(currType,'sendTasks') || strcmp(currType,'receiveTasks') 
            % find task if listed in the extension
            idxTask = getIndexCellString(bp_ext.taskRes(:,1), currElement.id);
            if idxTask > 0
                % find the resource description in the extension 
                idxRes = getIndexCellString({bp_ext.resources.id}', bp_ext.taskRes{idxTask,2}); 
                if idxRes == -1
                    % throw exception - specified resource not found in extension
                    errID = 'BPMN:Extension:ResourceNotDefined'; 
                    errMsg = 'Resource %s used by task %s not specified in the extension.';
                    err = MException(errID, errMsg, bp_ext.taskRes{idxTask,2}, currElement.id);
                    throw(err)
                else
                    %assignmentIdx = getIndexCellString(bp_ext.resources(idxRes).assignments(:,1), currElement.id); 
                    %execTime =  bpmn.BPMNtime2sec(bp_ext.resources(idxRes).assignments{bp_ext.taskRes{idxTask,3},2}); 
                    entryName = [currElement.id, '_entry']; 
                    idxLQNproc = getIndexCellString({myLQN.processors.ID}', bp_ext.taskRes{idxTask,2}); 
                    if getIndexCellString({myLQN.processors(idxLQNproc).tasks(1).entries.name}', entryName) == -1
                        % throw exception - specified entry does not exist
                        errID = 'BPMN:LQN:EntryNotFound'; 
                        errMsg = 'Entry %s not found in processor %s.';
                        err = MException(errID, errMsg, entryName, myLQN.processors.name);
                        throw(err)
                    end
                    % set call in the activity
                    actCalls{currIdx} = entryName; 
                    numCalls = 1;
                    myAct = myAct.addSynchCall(entryName, numCalls); 
                end
            end
        end
        
        %% addactivity to task
        myTask = myTask.setActivity(myAct, currIdx); 
        
        %% check current node 
        idxChecked(currIdx) = 1; 
        idxToCheck(currIdx) = 0; 
    end

   
    %% pass on the activity graph to add activities associated to EXCLUSIVE gateways, one after each as they are not proper activities, but simply mark a precedence
    for i = find(exclGateways==1)'
        inputActs = elemGraph(:,i)'>0; 
        outputActs = elemGraph(i,:)>0; 
        
        if sum(inputActs) == 1 && sum(outputActs) > 1 %%  branch 
            % add as many activities as output links 
            newN = n + sum(outputActs); 
            newActNames = cell(newN,1);
            newActNames(1:n) = actNames; 
            newActCalls = cell(newN,1);
            newActCalls(1:n) = actCalls; 
            newElemGraph = zeros(newN);
            newElemGraph(1:n, 1:n) = elemGraph;
            
            counter = 1;
            for j = find(outputActs == 1) 
                myActName = [actNames{j}, '_after_', int2str(counter)]; 
                myAct = lqn.activity(myActName, [], 0, ''); 
                myTask = myTask.setActivity(myAct, n+counter); 
                newActNames{n+counter} = myActName; 
                
                newElemGraph(i,n+counter) = newElemGraph(i,j); % connect act i with new act with the same prob as with j
                newElemGraph(n+counter,j) = 1; % connect new act to act j
                newElemGraph(i,j) = 0; %remove connection from inputAct to i 
                
                counter = counter+1; 
            end
            
        elseif sum(inputActs) > 1 && sum(outputActs) == 1 %% synch point
            % add as many activities as input links 
            newN = n + sum(inputActs); 
            newActNames = cell(newN,1);
            newActNames(1:n) = actNames; 
            newActCalls = cell(newN,1);
            newActCalls(1:n) = actCalls; 
            newElemGraph = zeros(newN);
            newElemGraph(1:n, 1:n) = elemGraph;
            
            counter = 1;
            
            for j = find(inputActs == 1) 
                myActName = [actNames{j}, '_before_', int2str(counter)]; 
                myAct = lqn.activity(myActName, [], 0, ''); 
                myTask = myTask.setActivity(myAct, n+counter);
                newActNames{n+counter} = myActName; 
                
                newElemGraph(j,n+counter) = newElemGraph(j,i); % connect act j with new act with the same prob as with i
                newElemGraph(n+counter,i) = 1; % connect new act to act i
                newElemGraph(j,i) = 0; %remove connection from inputAct j to i 
                
                counter = counter+1; 
            end
        end
        n = newN;
        actNames = newActNames;
        actCalls = newActCalls;
        elemGraph = newElemGraph; 
    end
    
     %% pass on the activity graph to add activities associated to SEND/RECEIVE tasks, one between each of these pairs
    for i = find(sendReqElems==1)'
        %inputAct = find(elemGraph(:,i)>0,1); 
        outputAct = find(elemGraph(i,:)>0,1); 

        % add one more activity just after sendElem 
        newElemGraph = zeros(n+1);
        newElemGraph(1:n, 1:n) = elemGraph;

        myActName = [actNames{i}, '_call']; 
        myAct = lqn.activity(myActName, [], 0, ''); 
        myTask = myTask.setActivity(myAct, n+1); 
        actNames{n+1} = myActName;
        
        % call the element that receives the message -> entry
        % entry name
        idxMsgOut = getIndexCellString(msgList(:,3), flowElements{i,1}); % index of the message sent by this element
        idxProcOut = msgList{idxMsgOut, 4}; 
        entryName = [processNames{idxProcOut}, '_MSG_', msgList{idxMsgOut,1}, '_entry'];
        actCalls{n+1} = entryName; 
        
        newElemGraph(i,n+1) = newElemGraph(i,outputAct); % connect act i with new act n+1 with the same prob as with outputAct
        newElemGraph(n+1,outputAct) = 1; % connect new act n+1to act outputAct
        newElemGraph(i,outputAct) = 0; %remove connection from inputAct to i 
        
        n = n+1;
        elemGraph = newElemGraph; 
        
    end
    
    myTask = myTask.setInitActivity(initElement); 
    myTask = myTask.setActGraph(elemGraph, actNames, actCalls); 
   
end

%%
function msgList = createMsgList(bp) 
    n = length(bp.process); % number of processes
    m = length(bp.messageFlow); % total number of message flows
    msgList = cell(m,5);
    
    % list of all send tasks and intermediate throw events 
    sendElems = [];
    sendProc = [];
    receiveElems = [];
    receiveProc = [];
    for i = 1:n
        if ~isempty(bp.process(i).sendTasks)
            sendElems =     [sendElems;     {bp.process(i).sendTasks.id}'];
        end
        if ~isempty(bp.process(i).intermediateThrowEvents)
            sendElems =     [sendElems;     {bp.process(i).intermediateThrowEvents.id}'];
        end
        sendProc = [sendProc; i*ones(length(bp.process(i).sendTasks) + length(bp.process(i).intermediateThrowEvents),1)];
        
        if ~isempty(bp.process(i).receiveTasks)
            receiveElems =  [receiveElems;  {bp.process(i).receiveTasks.id}'];
        end
        if ~isempty(bp.process(i).intermediateCatchEvents)
            receiveElems =  [receiveElems;  {bp.process(i).intermediateCatchEvents.id}'];
        end
        receiveProc = [receiveProc; i*ones(length(bp.process(i).receiveTasks) + length(bp.process(i).intermediateCatchEvents),1)];
    end
    
    for i = 1:m
        msgList{i,1} = bp.messageFlow(i).id;
        msgList{i,3} = bp.messageFlow(i).sourceRef;
        msgList{i,5} = bp.messageFlow(i).targetRef;
        
        idxSend = getIndexCellString(sendElems, bp.messageFlow(i).sourceRef); 
        if idxSend == -1
             % throw exception - specified message is not sent by a sendtask or throw event
            errID = 'BPMN:Message:SendElementNotFound'; 
            errMsg = 'Message %s not  sent by a Send Task or Throw Event.';
            err = MException(errID, errMsg, bp.messageFlow(i).id);
            throw(err)
        end
        idxReceive = getIndexCellString(receiveElems, bp.messageFlow(i).targetRef); 
        if idxReceive == -1
             % throw exception - specified message is not sent by a sendtask or throw event
            errID = 'BPMN:Message:ReceiveElementNotFound'; 
            errMsg = 'Message %s not received by a Receive Task or Catch Event.';
            err = MException(errID, errMsg, bp.messageFlow(i).id);
            throw(err)
        end
        
        msgList{i,2} = sendProc(idxSend);
        msgList{i,4} = receiveProc(idxReceive);
    end
end

%%
function reqReply = createReqReplyList(bp, refProcesses, msgList)
    % msgList: ID - sourceProcess - sourceElement - targetProcess - targetElement

    reqReply = zeros(0,3); % procIdx - outMessage (request) - inputMessage (reply)
    
    for i = find(refProcesses==1) % for each reference process
        for j = find(cell2mat(msgList(:,2))==i) % for messages that are emitted by this process
            destProc = msgList{j,4};
            destElem = msgList{j,5};
            
            reqReply(end+1,1) = i;
            reqReply(end,2) = j;
            reqReply = getReplyRequest(destProc, destElem, 1, bp, msgList, reqReply); 
        end
    end

end

function reqReply = getReplyRequest(startProc, startElem, counter, bp, msgList, reqReply) 
    % determines the message that replies (if any) to the message that
    % points to destProc and destElem. 
    % The result is stored in reqReply, row counter, column 3
    
    % explore the flow element graph of this processor, starting from destElem -  to deter
    proc = bp.process(startProc);
    flowElements = cell(0,3);
    elementTypes = {'tasks';'sendTasks';'receiveTasks';
                    'exclusiveGateways'; 'parallelGateways'; 'inclusiveGateways';
                    'startEvents'; 'endEvents'; 'intermediateThrowEvents'; 'intermediateCatchEvents'}; 
    for k = 1:size(elementTypes,1)
        var = eval(['proc.',elementTypes{k}]);
        if ~isempty(var)
            for j = 1:length(var)
                flowElements{end+1,1} = var(j).id;
                flowElements{end,2} = elementTypes{k};
                flowElements{end,3} = int2str(j);
            end
        end
    end

    % list of links in the process - nx3 sring cell, each row with id -
    % source - target
    links = cell(length(proc.sequenceFlows),3);
    for k = 1:length(proc.sequenceFlows)
        links{k,1} = proc.sequenceFlows(k).id; 
        links{k,2} = proc.sequenceFlows(k).sourceRef; 
        links{k,3} = proc.sequenceFlows(k).targetRef; 
    end

    % choose start event (unique) as first flow element
    %currFlowElement = proc.startEvents(1).id; 
    currFlowElement = startElem; 
    currIdx = getIndexCellString(flowElements(:,1), currFlowElement);
    n = size(flowElements,1); 
    
    idxChecked = zeros(n,1);  % 0-1 vector, 1 for a checked flow element
    idxToCheck = zeros(n,1);  % 0-1 vector, 1 for a flow element discovered but not checked
    idxToCheck(currIdx) = 1;
    
    outputMessages = zeros(n,1);    % identifies elements that generate messages in the current process 
                                    % in connection with the input message
                                    % currently analyzed
    
    %% explore activity graph starting from the startElem                                
    while sum(idxChecked) < n && sum(idxToCheck) > 0
        currIdx = find(idxToCheck,1); 
        %currID = flowElements{currIdx,1}; 
        currType = flowElements{currIdx,2}; 
        currElement = eval(['proc.', currType,'(',flowElements{currIdx,3},')']);
               
        
        % list of outgoing links
        outLinks = currElement.outgoing; 
        m_out = size(outLinks,1); 
        for j = 1:m_out
            outLinkIdx = getIndexCellString(links(:,1), outLinks{j});
            % index of target node 
            outIdx = getIndexCellString(flowElements(:,1), links{outLinkIdx,3}); 
            
            % add out nodes not checked yet to list of nodes to check 
            if idxToCheck(outIdx) == 0 && idxChecked(outIdx) == 0 
                idxToCheck(outIdx) = 1; 
            end
        end
        
        % list of incoming links - only to check for nodes without incoming
        % flows (i.e., intermediate message events)
        inLinks = currElement.incoming; 
        m_in = size(inLinks,1); 
        for j = 1:m_in
            inLinkIdx = getIndexCellString(links(:,1), inLinks{j});
            % index of source node 
            inIdx = getIndexCellString(flowElements(:,1), links{inLinkIdx,2}); 
            
            % add in nodes not checked yet to list of nodes to check 
            if idxToCheck(inIdx) == 0 && idxChecked(inIdx) == 0 
                idxToCheck(inIdx) = 1; 
            end
        end
        
        %% check for elements sending messages 
        if strcmp(currType,'intermediateThrowEvents') || strcmp(currType,'sendTasks') 
            outputMessages(currIdx) = 1; 
        end
        
        %% check current node 
        idxChecked(currIdx) = 1; 
        idxToCheck(currIdx) = 0; 
    end
    
    %% single output message - either back to originating process or error
    if sum(outputMessages)==1
        % find the index of the output message 
        outMsgIdx = getIndexCellString(msgList(:,3), flowElements{outputMessages==1,1} ); 
        % find the process where the exit message is sent to
        destProc = msgList{outMsgIdx, 4}; 
        if destProc == reqReply(counter,1)
            % base case: destProc is the same as the origin of the current msg
            % under analysis -> 
            % set in reqReply the index of the message that replies - leaves
            % the current element
            reqReply(counter,3) = outMsgIdx;
        else 
            % recursion: destProc is different as the process that
            % originated the current message ->
            % execute the same procedure with the called process and
            % element AND, once the reply to the new message is known, call
            % the same procedure on the current Proc to find the replying
            % message
            
            % recursion on process called
            destElem = msgList{outMsgIdx,5};
            reqReply(end+1,1) = startProc;
            reqReply(end,2) = outMsgIdx;
            reqReply = getReplyRequest(destProc, destElem, counter+1, bp, msgList, reqReply); 
            
            % continuation of analysis of the current process, starting
            % from the element where the reply was obtained
            destProc = startProc; 
            destElem = msgList{reqReply(counter+1,3),5};
            reqReply = getReplyRequest(destProc, destElem, counter, bp, msgList, reqReply); 
        end
        
    end

end