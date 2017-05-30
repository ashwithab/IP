classdef intermediateThrowEvent < bpmn.throwEvent
% INTERMEDIATETHROWEVENT object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = intermediateThrowEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['intermediateThrowEvent_',id];
        end
        obj@bpmn.throwEvent(id,name); 
    end
    
    %toString
    function myString = toString(obj)
       myString = toString@bpmn.throwEvent(obj);
    end

end
    
end