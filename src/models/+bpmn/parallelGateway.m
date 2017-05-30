classdef parallelGateway < bpmn.gateway
% PARALLELGATEWAY object, as part of a Business Process Modeling Notation (BPMN) model. 
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
    function obj = parallelGateway(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['parallelGateway_',id];
        end
        obj@bpmn.gateway(id,name); 
    end
    
    

end
    
end