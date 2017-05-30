function [resEntry,resEntry_CDF] = CQN_respTime_entry(processors, entry, Rfull, RT_CDF_entry, Xfull, verbose)
% A = CQN_RESPTIME_entry(P,entry,R) determines the mean response times of 
% the services defined as entries in an LQN model.  
% P contains the list of processors in the LQN model and 
% Rfull the mean response times for each class and station in the associated 
% Closed Multi-Class Queueing Network with Class Switching (CQN). 
% More details on this type of queueing networks can be found 
% on the LINE documentation
% 
% Parameters: 
% processors:   list of processors in the LQN model
% entry:         list of entries in the LQN model
% Rfull:        mean response times for each class and station in the
%               associated queueing network model 
% RT_CDF_entry: response time distributions for each entry
% Xfull:        throughput for each request class in the model
% verbose:      1 for screen output
% 
% Ouput:
% resEntry:      mean response times of the entries in the LQN model
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

np = length(processors); 
nonEmptyProc = zeros(np,1);
resEntry = cell(np,3);
for i = 1:np
    if entry(i).numCalls > 0 && ~strcmp(processors(i).tasks.scheduling, 'ref')
        resEntry{i,1} = processors(i).name;
        respTime = 0;
        % for each activity in this processor/entry
        for j = 1:size(processors(i).tasks.actNames,1)
            % if this activity called any resource-demanding activity
            if ~isempty(entry(i).actCalls(j).actNames)
                temp = 0;
                for k = 1:size(entry(i).actCalls(j).actNames,1)
                    % add mean resp time for the associated (proc,class)
                    % multiply by the probability of calling this
                    % (proc,class) in this activity call
                    temp = temp + Rfull(entry(i).actCalls(j).procs(k), entry(i).actCalls(j).classes(k) ) * entry(i).actCalls(j).probs(k); 
                end
                temp = temp * processors(i).tasks.actProbs(j); % multiply by the probability of visiting this activity
                respTime = respTime + temp; 
            end
        end
        respTime = respTime/entry(i).numCalls; % divide by the number of calls to this processor -> all activities
        resEntry{i,2} = respTime;
        nonEmptyProc(i) = 1;
        
        %throughput computation 
        numActs = size(processors(i).tasks.actNames,1); 
        % indexes of current activities
        currActs = zeros(1,numActs);
        currActs(processors(i).tasks.initActID) = 1; 
        % first layer of activities with actual calls
        firstLayerActs = zeros(1,numActs);
        firstLayerTput = zeros(1,numActs);
        ready = false;
        while ~(sum(currActs)==0) && ~ready
            nextActs = zeros(1,numActs);
            for j = find(currActs > 0)
                nextActs = nextActs + processors(i).tasks.actGraph(j,:)>0; 
            end
            for j = find(nextActs > 0)
                % add activities with actual calls
                if ~isempty(entry(i).actCalls(j).actNames)
                    firstLayerActs(j) = processors(i).tasks.actProbs(j);
                    firstLayerTput(j) = Xfull(entry(i).actCalls(j).procs(1), entry(i).actCalls(j).classes(1) ); 
                    % remove these activities from further analysis
                    nextActs(j) = 0;
                end
            end
            if sum(firstLayerActs) == 1
                ready = true;
            end
            currActs = nextActs;
        end
        resEntry{i,3} = sum(firstLayerActs.*firstLayerTput);
    end
end
resEntry = reshape({resEntry{nonEmptyProc==1,:}}',sum(nonEmptyProc),3);

if ~isempty(RT_CDF_entry)
    resEntry_CDF = reshape({RT_CDF_entry{nonEmptyProc==1,:}}',sum(nonEmptyProc),2);
else
    resEntry_CDF = [];
end
