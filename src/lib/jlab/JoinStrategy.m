classdef (Sealed) JoinStrategy
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties (Constant)
    Standard = 'Standard Join';
    Quorum = 'Partial Join';
    Guard = 'Partial Join';
end 

methods (Access = private)
%private so that you can't instatiate.
    function out = JoinStrategy
    end 
end

methods (Static)
    
    function text = toText(type)
        switch type
            case JoinStrategy.Standard
                text = 'Stardard Join';
            case JoinStrategy.Partial
                text = 'Partial Join';
        end
    end
end


end

