classdef Join < Section
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        joinStrategy;
        joinRequired;
        joinCustomerClasses;
    end
    
    methods
        %Constructor
        function self = Join(customerClasses)
            self = self@Section('Join');
            self.joinCustomerClasses{1,1} = '';
            initialiseJoinCustomerClasses(self, customerClasses);
        end
    end
    
    methods (Access = 'public')
        
        function setRequired(self, customerClass, nJobs)
            self.joinRequired{customerClass.index} = nJobs;
        end
        
        function setStrategy(self, customerClass, joinStrat)
            self.joinCustomerClasses{customerClass.index} = customerClass;            
            self.joinStrategy{customerClass.index} = joinStrat;
        end
        
        function initialiseJoinCustomerClasses(self, customerClasses)
            for i = 1 : (length(customerClasses) - 1),
                self.joinCustomerClasses{i} = customerClasses{i};
                self.joinRequired{i} = -1;
                self.joinStrategy{i} = JoinStrategy.Standard;
            end
        end
    end
    
end

