classdef QueueingStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        queuePolicy;
        numberOfServers;
        bufferCapacity;
    end
    
    methods
        %Constructor
        function self = QueueingStation(model, name, policy, strategy)
            self = self@Node(name);
            if(model ~= 0)
                custClasses = model.custClasses;
                self.queue = Queue(custClasses);
                self.router = Router(custClasses);
                self.bufferCapacity = -1;
                self.queuePolicy = QueuePolicy.NP;
                self.server = Server(custClasses);
                self.numberOfServers = 1;
                
                addNode(model, self);
            end
            if exist('policy','var')
                self.queuePolicy = policy;
                switch policy
                    case QueuePolicy.PS
                        self.server = PSServer(custClasses);
                    case QueuePolicy.NP
                        self.server = Server(custClasses);
                end
            end
        end
                
        function setBufferCapacity(self, value)
            self.bufferCapacity = value;
        end
        
        function setNumServers(self, value)
            self.numberOfServers = value;
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
