classdef (Sealed) QueuePolicy
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties (Constant)
    NP = 'NonPreemptive';
    PS = 'ProcessorSharing';
    NPPrio = 'NonPreemptivePriority';
end 

methods (Access = private)
%private so that you can't instatiate.
    function out = QueuePolicy
    end 
end

methods (Static)
    
    function text = toText(type)
        switch type
            case QueuePolicy.NP
                text = 'NonPreemptive';
            case QueuePolicy.PS
                text = 'ProcessorSharing';
            case QueuePolicy.NPPrio
                text = 'NonPreemptivePriority';
        end
    end
end


end

