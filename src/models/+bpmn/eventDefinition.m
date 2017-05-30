classdef eventDefinition < bpmn.rootElement
% EVENTDEFINITION abstract class part of a Business Process Modeling Notation (BPMN) model. 
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
    function obj = eventDefinition(id)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        end
        obj@bpmn.rootElement(id); 
    end
   
    %toString
    function myString = toString(obj)
        myString = toString@bpmn.rootElement(obj);
    end

end
    
end