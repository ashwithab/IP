classdef Exp < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = Exp(lambda)
            self = self@Distribution('Exponential', 1);
            setParam(self, 1, 'lambda', lambda, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Exponential';
            self.javaParClass = 'jmt.engine.random.ExponentialPar';
        end
    end
    
end

