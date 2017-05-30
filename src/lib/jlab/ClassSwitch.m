classdef ClassSwitch < Section
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        classSwitchMatrix;
    end
    
    methods
        %Constructor
        function self = ClassSwitch(customerClasses, csMatrix)
            self = self@Section('ClassSwitch');            
            self.classSwitchMatrix = csMatrix;
        end
    end
    
    methods (Access = 'private')
    end
    
end
