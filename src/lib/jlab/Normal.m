classdef Normal < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = Normal(mean, stdev)
            self = self@Distribution('Normal',2);
            setParam(self, 1, 'mean', mean, 'java.lang.Double');
            setParam(self, 2, 'standardDeviation', stdev, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Normal';
            self.javaParClass = 'jmt.engine.random.NormalPar';
        end
    end
    
end

