classdef task < bpmn.activity
% TASK object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% id:                   unique identifier (string)
% name:                 server name (string)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = task(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['task_',id];
        end
        obj@bpmn.activity(id,name); 
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@bpmn.activity(obj);
    end

end
    
end