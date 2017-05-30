classdef SinkStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
    end
    
    methods
        %Constructor
        function self = SinkStation(model, name)
            self = self@Node(name);
            if model ~= 0
                self.queue = '';
                self.router = '';
                self.server = Section('JobSink');
                addNode(model, self);
            end
        end
                
        function sections = getSections(self)
            sections = {'', self.server, ''};
        end
    end
    
end
