classdef throwEvent < bpmn.event
% THROWEVENT abstract class, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% eventDefinition:      event definition only valid for this event (cell of event definition)
% eventDefinitionRefp:  references to event definitions that are globally available (cell of string)
%
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    eventDefinition;    % event definition only valid for this event (cell of event definition)
    eventDefinitionType;    % type of the associated eventDefinition (cell of string) - Message, Timer, etc
    eventDefinitionRef; % references to event definitions that are globally available (cell of string)
    eventDefinitionRefType; % type of the associated eventDefinition reference (cell of string) - Message, Timer, etc
end

methods
%public methods, including constructor

    %constructor
    function obj = throwEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['throwEvent_',id];
        end
        obj@bpmn.event(id,name); 
    end
    
    function obj = addEventDefinition(obj, eventDef, type)
       if nargin > 1
            if isempty(obj.eventDefinition)
                obj.eventDefinition = eventDef;
                obj.eventDefinitionType = type;
            else
                obj.eventDefinition(end+1,1) = eventDef;
                obj.eventDefinitionType(end+1,1) = type;
            end
       end
    end
    
    function obj = addEventDefinitionRef(obj, eventDefRef, type)
       if nargin > 1
            if isempty(obj.eventDefinitionRef)
                obj.eventDefinitionRef = cell(1);
                obj.eventDefinitionRef{1} = eventDefRef;
                obj.eventDefinitionRefType = cell(1);
                obj.eventDefinitionRefType{1} = type;
            else
                obj.eventDefinitionRef{end+1,1} = eventDefRef;
                obj.eventDefinitionRefType{end+1,1} = type;
            end
       end
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@bpmn.event(obj);
    end

end
    
end