classdef RandomSource < Section   
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties
        sourceCustClasses;
    end
    
        methods
        %Constructor
        function self = RandomSource(custClasses)
            self = self@Section('RandomSource');
            self.sourceCustClasses{1,1} = '';
            initialiseArrivalCustClasses(self, custClasses);
        end
    end
    
    methods (Access = 'private')
        function initialiseArrivalCustClasses(self, custClasses)
           for i = 1 : (length(custClasses) - 1),
              self.sourceCustClasses{1, i} = {custClasses{1, i}, QueueStrategy.FCFS, DropRule.Infinite};  
           end
        end
    end

    
end

