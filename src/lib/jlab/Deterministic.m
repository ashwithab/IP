classdef Deterministic < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
    end
    
    methods
        %Constructor
        function self = Deterministic(t)
            self = self@Distribution('Deterministic',1);
            setParam(self, 1, 't', t, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.DeterministicDistr';
            self.javaParClass = 'jmt.engine.random.DeterministicDistrPar';
        end
    end
    
end

