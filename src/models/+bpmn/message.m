classdef message < bpmn.rootElement
% MESSAGE object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    name;                     % string
end

methods
%public methods, including constructor

    %constructor
    function obj = message(id,name)
        if(nargin == 0)
            disp('No ID provided for this message'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp(['No name provided for message ', id]); 
            name = ['message_',id];
        end
        obj@bpmn.rootElement(id); 
        obj.name = name;
    end
   
     %toString
    function myString = toString(obj)
        myString = toString@bpmn.rootElement(obj);
        myString = sprintf([myString, 'name: ', obj.name,'\n']);
    end

end
    
end