classdef Gamma < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = Gamma(alpha, beta)
            self = self@Distribution('Gamma',2);
            setParam(self, 1, 'alpha', alpha, 'java.lang.Double');
            setParam(self, 2, 'beta', beta, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.GammaDistr';
            self.javaParClass = 'jmt.engine.random.GammaDistrPar';
        end
    end
    
end

