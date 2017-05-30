classdef Section < handle
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        className;
    end
    
    methods
        %Constructor
        function self = Section(className)
            self.className = className;
        end
    end
end
