classdef inclusiveGateway < bpmn.gateway
% INCLUSIVEGATEWAY object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% default:          ID of the default outgoing sequence flow (string)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    default;        % ID of the default outgoing sequence flow (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = inclusiveGateway(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['exclusiveGateway_',id];
        end
        obj@bpmn.gateway(id,name); 
    end
    
    function obj = setDefault(obj, flowID)
       obj.default = flowID;
    end
    
     %toString
    function myString = toString(obj)
        myString = toString@bpmn.gateway(obj);
    end

end
    
end