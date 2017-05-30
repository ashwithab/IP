classdef (Sealed) ServiceStrategy
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties (Constant)
    LoadIndependent = 1;
    LoadDependent = 2;
    ZeroServiceTime = 3;
end 

methods (Access = private)
%private so that you can't instatiate.
    function out = ServiceStrategy
    end 
end

end

