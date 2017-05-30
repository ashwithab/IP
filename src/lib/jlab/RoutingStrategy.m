classdef (Sealed) RoutingStrategy
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties (Constant)
    Random = 1;
    RoundRobin = 2;
    Probabilities = 3;
    JoinShortestQueue = 4;
    ShortestRTime = 5;
    LeastUtilization = 6;
    FastestService = 7;
    LDRouting = 8;
end 

methods (Access = private)
%private so that you can't instatiate.
    function out = RoutingStrategy
    end 
end

methods (Static, Access = public)
    function type = toType(text)
        switch text
            case 'Random'
                type = RoutingStrategy.Random;
            case 'RoundRobin'
                type = RoutingStrategy.RoundRobin;
            case 'Probabilities'
                type = RoutingStrategy.Probabilities;
            case 'JoinShortestQueue'
                type = RoutingStrategy.JoinShortestQueue;
            case 'ShortestRTime'
                type = RoutingStrategy.ShortestRTime;
            case 'LeastUtilization'
                type = RoutingStrategy.LeastUtilization;
            case 'FastestService'
                type = RoutingStrategy.FastestService;
            case 'LDRouting'
                type = RoutingStrategy.LDRouting;
        end
    end
    
    function text = toText(type)
        switch type
            case RoutingStrategy.Random
                text = 'Random';
            case RoutingStrategy.RoundRobin
                text = 'RoundRobin';
            case RoutingStrategy.Probabilities
                text = 'Probabilities';
            case RoutingStrategy.JoinShortestQueue
                text = 'JoinShortestQueue';
            case RoutingStrategy.ShortestRTime
                text = 'ShortestRTime';
            case RoutingStrategy.LeastUtilization;
                text = 'LeastUtilization';
            case RoutingStrategy.FastestService
                text = 'FastestService';
            case RoutingStrategy.LDRouting
                text = 'LDRouting';
        end
    end
end

end

