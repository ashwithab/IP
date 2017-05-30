classdef CustomerClass < handle
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        name;
        priority;
        referenceStation;
        index;
        type;
    end
    
    methods
        %Constructor
        function self = CustomerClass(type, name)
            self.name = name;
            self.priority = 0;
            self.referenceStation = Node('');
            self.index = 1;
            self.type=type;
        end
        
        function self = setReferenceStation(self, source)
            self.referenceStation = source;
        end

        function boolIsa = isReferenceStation(self, node)
            boolIsa = strcmp(self.referenceStation.name,node.name);
        end

%         function self = set.priority(self, priority)
%             if ~(rem(priority,1) == 0 && priority >= 0)
%                 error('Priority must be an integer.');
%             end
%             self.priority = priority;
%         end
    end
    
end
