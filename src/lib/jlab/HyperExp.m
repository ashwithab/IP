classdef HyperExp < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = HyperExp(p, lambda1, lambda2)
            self = self@Distribution('Hyperexponential',3);
            setParam(self, 1, 'p', p, 'java.lang.Double');
            setParam(self, 2, 'lambda1', lambda1, 'java.lang.Double');
            setParam(self, 3, 'lambda2', lambda2, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.HyperExp';
            self.javaParClass = 'jmt.engine.random.HyperExpPar';
        end
    end
    
end

