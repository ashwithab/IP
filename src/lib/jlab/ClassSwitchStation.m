classdef ClassSwitchStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        bufferCapacity;
        queuePolicy;
    end
    
    methods
        %Constructor
        function self = ClassSwitchStation(model, name, csMatrix)
            self = self@Node(name);
            if(model ~= 0)
                custClasses = model.custClasses;
                self.queue = Queue(custClasses);
                self.router = Router(custClasses);
                self.bufferCapacity = -1;
                self.queuePolicy = QueuePolicy.NP;
                self.server = ClassSwitch(custClasses, csMatrix);
                addNode(model, self);
            end
        end
                
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
               
        function sections = getSections(self)
            sections = {self.queue, self.server, self.router};
        end
    end
    
end
