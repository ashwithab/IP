classdef Queue < Section
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        size;
        queuePolicy;
        queueCustomerClasses;
    end
    
    methods
        %Constructor
        function self = Queue(customerClasses)
            self = self@Section('Queue');
            self.size = -1;
            self.queuePolicy = QueuePolicy.NP;
            self.queueCustomerClasses{1,1} = '';            
            initialiseQueueCustomerClasses(self, customerClasses);
        end
    end
    
    methods (Access = 'private')
        function initialiseQueueCustomerClasses(self, customerClasses)
           for i = 1 : (length(customerClasses) - 1),
              self.queueCustomerClasses{i} = {customerClasses{i}, QueueStrategy.FCFS, DropRule.Infinite};  
           end
        end
    end
    
end

