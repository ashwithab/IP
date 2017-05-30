classdef DelayStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        maxCustomers;
        queuePolicy;
        numberOfServers;
        bufferCapacity;
    end
    
    methods
        %Constructor
        function self = DelayStation(model, name)
            self = self@Node(name);
            if(model ~= 0)
                custClasses = model.custClasses;
                self.queue = Queue(custClasses);
                self.router = Router(custClasses);
                self.maxCustomers = -1;
                self.queuePolicy = QueuePolicy.NP;
                self.server = Delay(custClasses);
                self.numberOfServers = Inf;
                self.bufferCapacity = -1;
                
                addNode(model, self);
            end
        end
                
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
        
        function setScheduling(self, class, strategy)
            self.queue.queueCustomerClasses{1, class.index}{2} = strategy;
        end
        
        function setLoadIndepService(self, class, distribution)
            self.server.serverCustomerClasses{1, class.index}{2} = 'LoadIndependent';
            self.server.serverCustomerClasses{1, class.index}{3} = distribution;
        end        
        
        function sections = getSections(self)
            sections = {self.queue, self.server, self.router};
        end
    end
    
end
