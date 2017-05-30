classdef JoinStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        bufferCapacity;
    end
    
    methods
        %Constructor
        function self = JoinStation(model, name)
            self = self@Node(name);
            if(model ~= 0)
                custClasses = model.custClasses;
                self.queue = Join(custClasses);
                self.router = Router(custClasses);
                self.server = ServiceTunnel();
                addNode(model, self);
            end
        end
        
        function setStrategy(self, class, strategy)
            self.queue.setStrategy(class,strategy);
        end
        
        function setRequired(self, class, njobs)
            self.queue.setRequired(class,njobs);
        end
        
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
        
    end
    
end
