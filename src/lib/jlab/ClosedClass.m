classdef ClosedClass < CustomerClass
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        population;
    end
    
    methods
        
        %Constructor
        function self = ClosedClass(model, name, njobs, refnode, prio)
            self = self@CustomerClass('closed', name);
            self.type = 'closed';
            self.population = njobs;
            self.priority = 0;
            if exist('prio','var')
                self.priority = prio;
            end
            addCustomerClass(model, self);
            setReferenceStation(self, refnode);
            % set default scheduling for this class at all nodes
            for i=1:length(model.stations)
                if ~isempty(model.stations{i}) && ~isa(model.stations{i},'SourceStation') && ~isa(model.stations{i},'SinkStation') && ~isa(model.stations{i},'JoinStation')
                    model.stations{i}.setScheduling(self, QueueStrategy.FCFS);
                end
                if isa(model.stations{i},'JoinStation')
                    model.stations{i}.setStrategy(self,JoinStrategy.Standard);
                    model.stations{i}.setRequired(self,-1);
                end
                if ~isempty(model.stations{i})
                    %                    && (isa(model.stations{i},'QueueingStation') || isa(model.stations{i},'RouterStation'))
                    model.stations{i}.setRouting(self, 'Random');
                end
            end
        end
        
        function setReferenceStation(class, source)
            setReferenceStation@CustomerClass(class, source);
        end
    end
    
end

