classdef Uniform < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = Uniform(minVal, maxVal)
            self = self@Distribution('Uniform',2);
            setParam(self, 1, 'min', minVal, 'java.lang.Double');
            setParam(self, 2, 'max', maxVal, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Uniform';
            self.javaParClass = 'jmt.engine.random.UniformPar';
        end
    end
    
end

