classdef (Sealed) QueueStrategy
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties (Constant)
    FCFS = 1;
    LCFS = 2;
    Random = 3;
    SJF = 4;
    LJF = 5;
end 

methods (Access = private)
%private so that you can't instatiate.
    function out = QueueStrategy
    end 
end

end