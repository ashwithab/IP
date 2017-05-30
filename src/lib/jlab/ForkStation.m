classdef ForkStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        queuePolicy;
        bufferCapacity;
    end
    
    methods
        %Constructor
        function self = ForkStation(model, name)
            self = self@Node(name);
            if(model ~= 0)
                custClasses = model.custClasses;
                self.queue = Queue(custClasses);
                self.queuePolicy = QueuePolicy.NP;
                self.bufferCapacity = -1;
                self.server = ServiceTunnel();
                self.router = Fork(custClasses);
                addNode(model, self);
            end
        end
           
        function setTasksPerLink(self, nTasks)
            self.router.tasksPerLink = nTasks;
        end
    end
    
end
