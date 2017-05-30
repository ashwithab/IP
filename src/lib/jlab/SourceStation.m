classdef SourceStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
    end
    
    methods
        %Constructor
        function self = SourceStation(model, name)
            self = self@Node(name);
            if(model ~= 0)
                custClasses = model.custClasses;
                self.router = Router(custClasses);
                self.server = ServiceTunnel();
                self.queue = RandomSource(custClasses);
                addNode(model, self);
            end
        end
        
        function setArrival(self, class, distribution)
            self.queue.sourceCustClasses{1, class.index}{2} = 'LoadIndependent';
            self.queue.sourceCustClasses{1, class.index}{3} = distribution;
        end
        
        function sections = getSections(self)
            sections = {self.queue, self.server, self.router};
        end
    end
    
end