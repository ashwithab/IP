classdef Router < Section
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        routerCustomerClasses;
    end
    
    methods
        %Constructor
        function self = Router(customerClasses)
            self = self@Section('Router');
            self.routerCustomerClasses{1, 1} = '';
            initialiseRouterCustomerClasses(self, customerClasses);
        end
    end
    
    methods (Access = 'private')
        function initialiseRouterCustomerClasses(self, customerClasses)
           for i = 1 : (length(customerClasses) - 1)
              self.routerCustomerClasses{i} = {customerClasses{i}, RoutingStrategy.Random};  
           end
        end
    end
    
end
