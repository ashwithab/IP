classdef Distribution < handle
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        name
        params
        javaClass
        javaParClass
    end
    
    methods
        %Constructor
        function self = Distribution(name, numParam)
            self.name = name;
                self.params = cell(1,numParam);
            for i=1:numParam
                self.params{i}=struct('paramName','','paramValue',-1,'paramClass','');
            end
        end
        
        function nParam = getNumParams(self)
            nParam = length(self.params);
        end
        
        function setParam(self, id, name, value,typeClass)
            self.params{id}.paramName=name;
            self.params{id}.paramValue=value;
            self.params{id}.paramClass=typeClass;
        end
        
        function param = getParam(self,id)
            param = self.params{id};
        end
    end
    
end

