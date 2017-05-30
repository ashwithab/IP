function model=replaceNamesWithIDs(model)
%% The current code is id-based, whereas in LQNs it is name-based. 
% To avoid mishandling of precedences, it is important that id and name match. 
% Therefore, we replace all names with the id field.
for p=1:length(model.process)
firstTaskReplace = true;
for t=1:length(model.process(p).tasks) 
    if ~strcmp(model.process(p).tasks(t).name, model.process(p).tasks(t).id) && firstTaskReplace
        fprintf('BPMN process %d: task names will be replaced with their IDs.\n',p)
        firstTaskReplace = false;
    end
    model.process(p).tasks(t).name = model.process(p).tasks(t).id;
end
firstInclusiveGatewaysReplace = true;
for t=1:length(model.process(p).inclusiveGateways) 
    if ~strcmp(model.process(p).inclusiveGateways(t).name, model.process(p).inclusiveGateways(t).id) && firstInclusiveGatewaysReplace
        fprintf('BPMN process %d: inclusive gateway names will be replaced with their IDs.\n',p)
        firstInclusiveGatewaysReplace = false;
    end
    model.process(p).inclusiveGateways(t).name = model.process(p).inclusiveGateways(t).id;
end
firstExclusiveGatewaysReplace = true;
for t=1:length(model.process(p).exclusiveGateways) 
    if ~strcmp(model.process(p).exclusiveGateways(t).name, model.process(p).exclusiveGateways(t).id) && firstExclusiveGatewaysReplace
        fprintf('BPMN process %d: exclusive gateway names will be replaced with their IDs.\n',p)
        firstExclusiveGatewaysReplace = false;
    end
    model.process(p).exclusiveGateways(t).name = model.process(p).exclusiveGateways(t).id;
end
firstParallelGatewaysReplace = true;
for t=1:length(model.process(p).parallelGateways) 
    if ~strcmp(model.process(p).parallelGateways(t).name, model.process(p).parallelGateways(t).id) && firstParallelGatewaysReplace
        fprintf('BPMN process %d: parallel gateway names will be replaced with their IDs.\n',p)
        firstParallelGatewaysReplace = false;
    end
    model.process(p).parallelGateways(t).name = model.process(p).parallelGateways(t).id;
end
firstStartEventReplace = true;
for t=1:length(model.process(p).startEvents) 
    if ~strcmp(model.process(p).startEvents(t).name, model.process(p).startEvents(t).id) && firstStartEventReplace
        fprintf('BPMN process %d: start event names will be replaced with their IDs.\n',p)
        firstStartEventReplace = false;
    end
    model.process(p).startEvents(t).name = model.process(p).startEvents(t).id;
end
firstEndEventReplace = true;
for t=1:length(model.process(p).endEvents) 
    if ~strcmp(model.process(p).endEvents(t).name, model.process(p).endEvents(t).id) && firstEndEventReplace
        fprintf('BPMN process %d: end event names will be replaced with their IDs.\n',p)
        firstEndEventReplace = false;
    end
    model.process(p).endEvents(t).name = model.process(p).endEvents(t).id;
end
end
end