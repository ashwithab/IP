classdef PerfIndex < handle
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        type;
        class;
        station;
        confInt;
        maxRelErr;
    end
    
    methods
        %Constructor
        function self = PerfIndex(type, class, station)
            self.type = type;
            self.class = class;
            self.station = station;
            self.confInt = 0.99;
            self.maxRelErr = 0.03;
        end
        
        function value = get(self, results)
            for i=1:length(results.metric)
                if strcmp(results.metric{i}.class, self.class.name) && strcmp(results.metric{i}.station, self.station.name) && strcmp(results.metric{i}.measureType,self.type)
                    value = results.metric{i}.meanValue;
                    break;
                end
            end
        end
    end
    
end

