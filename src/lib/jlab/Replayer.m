classdef Replayer < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = Replayer(fileName)
            self = self@Distribution('Replayer',1);
            setParam(self, 1, 'fileName', fileName,'java.lang.String');
            self.javaClass = 'jmt.engine.random.Replayer';
            self.javaParClass = 'jmt.engine.random.ReplayerPar';
        end
    end
    
end

