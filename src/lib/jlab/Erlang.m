classdef Erlang < Distribution
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    methods
        %Constructor
        function self = Erlang(alpha, r)
            self = self@Distribution('Erlang',2);
            setParam(self, 1, 'alpha', alpha, 'java.lang.Double');
            setParam(self, 2, 'r', r, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Erlang';
            self.javaParClass = 'jmt.engine.random.ErlangPar';
        end
    end
    
end

