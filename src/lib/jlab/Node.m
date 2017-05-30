classdef Node < handle
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        name;
        queue;
        server;
        router;
    end
    
    methods
        %Constructor
        function self = Node(name)
            self.name = name;
        end
    end
    
    methods
        
        function sections = getSections(self)
            sections = {self.queue, self.server, self.router};
        end
        
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
        
        function setScheduling(self, class, strategy)
            self.queue.queueCustomerClasses{1, class.index}{2} = strategy;
        end
        
        function setRouting(self, class, strategy, destination, probability)
            switch nargin
                case 3
                    self.router.routerCustomerClasses{1, class.index}{2} = RoutingStrategy.toType(strategy);
                case 5
                    self.router.routerCustomerClasses{1, class.index}{2} = RoutingStrategy.toType(strategy);
                    if length(self.router.routerCustomerClasses{1, class.index})<3
                        self.router.routerCustomerClasses{1, class.index}{3}{1} = {destination, probability};
                    else
                        self.router.routerCustomerClasses{1, class.index}{3}{end+1} = {destination, probability};
                    end
            end
        end
    end
    
end

