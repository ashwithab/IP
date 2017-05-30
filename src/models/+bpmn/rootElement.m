classdef rootElement < bpmn.baseElement
% ROOTELEMENT abstract class, as part of a Business Process Modeling Notation (BPMN) model. 
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
    function obj = rootElement(id)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        end
        obj@bpmn.baseElement(id); 
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@bpmn.baseElement(obj);
    end
    
end
    
end