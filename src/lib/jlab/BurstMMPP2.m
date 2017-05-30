classdef BurstMMPP2 < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = BurstMMPP2(lambda0,lambda1,sigma0,sigma1)
            self = self@Distribution('Burst (MMPP2)',4);
            setParam(self, 1, 'lambda0', lambda0, 'java.lang.Double');
            setParam(self, 2, 'lambda1', lambda1, 'java.lang.Double');
            setParam(self, 3, 'sigma0', sigma0, 'java.lang.Double');
            setParam(self, 4, 'sigma1', sigma1, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.MMPP2Distr';
            self.javaParClass = 'jmt.engine.random.MMPP2Par';            
        end
    end
    
end

