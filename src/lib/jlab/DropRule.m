classdef (Sealed) DropRule
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties (Constant)
    Infinite = 1;
    Drop = 2;
    WaitingQueue = 3;
    BASBlocking = 4;
end 

methods (Access = private)
%private so that you can't instatiate.
    function out = DropRule
    end 
end

end

