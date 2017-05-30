classdef Pareto < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = Pareto(alpha,k)
            self = self@Distribution('Pareto',2);
            setParam(self, 1, 'alpha', alpha, 'java.lang.Double');
            setParam(self, 2, 'k', k, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Pareto';
            self.javaParClass = 'jmt.engine.random.ParetoPar';
        end
    end
    
end

