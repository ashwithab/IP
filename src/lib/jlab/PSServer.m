classdef PSServer < Section
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        numberOfServers;
        serverCustomerClasses;
    end
    
    methods
        %Constructor
        function self = PSServer(customerClasses)
            self = self@Section('PSServer');
            self.numberOfServers = 1;
            self.serverCustomerClasses{1, 1} = '';
            initialiseServerCustomerClasses(self, customerClasses); %[CustomerClass(), ServiceStrategy.LoadIndependent, Distribution('exp')];
        end
    end
    
    methods (Access = 'private')
        function initialiseServerCustomerClasses(self, customerClasses)
           for i = 1 : (length(customerClasses) - 1),
              self.serverCustomerClasses{1, i} = {customerClasses{1, i}, ServiceStrategy.LoadIndependent, Exponential()};  
           end
        end
    end
end

