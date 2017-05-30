classdef LoggerStation < Node
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.
    
    properties
        fileName;
        filePath;
        queuePolicy;
        bufferCapacity;
        wantExecTimestamp;
        wantLoggerName;
        wantTimeStamp;
        wantJobID;
        wantJobClass;
        wantTimeSameClass;
        wantTimeAnyClass;
    end
    
    methods
        %Constructor
        function self = LoggerStation(model, name, logFileName)
            self = self@Node(name);
            [filePath,fileName,fileExt] = fileparts(logFileName);
            self.fileName = sprintf('%s%s',fileName,fileExt);
            self.filePath = filePath;
            if(model ~= 0)
                custClasses = model.custClasses;
                self.queue = Queue(custClasses);
                self.router = Router(custClasses);
                self.bufferCapacity = -1;
                self.queuePolicy = QueuePolicy.NP;
                self.server = LogTunnel();
                self.wantExecTimestamp = 'false';
                self.wantLoggerName = 'false';
                self.wantTimeStamp = 'true';
                self.wantJobID = 'true';
                self.wantJobClass = 'true';
                self.wantTimeSameClass = 'false';
                self.wantTimeAnyClass = 'false';
                addNode(model, self);
            end
        end
        
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
        
        function setScheduling(self, class, strategy)
            self.queue.queueCustomerClasses{1, class.index}{2} = strategy;
        end
        
        function sections = getSections(self)
            sections = {self.queue, self.server, self.router};
        end
    end
end