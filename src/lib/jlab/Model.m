classdef Model < handle
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

%Private properties
    properties (GetAccess = 'private', SetAccess='private')
        fileName;
        jmtPath;
        maxSamples;
        %stations;
        %custClasses;
    end
    
    properties
        stations;
        custClasses;
        perfIndices;
        connections;
    end
    
    %Constants
    properties (Constant)
        xmlnsXsi = 'http://www.w3.org/2001/XMLSchema-instance';
        xsiNoNamespaceSchemaLocation = 'Archive.xsd';
        fileFormat = 'jsimg';
        jsimgPath = '';
    end
    
    % PUBLIC METHODS
    methods
        %Constructor
        function self = Model(fileName, jarPath)
            self.fileName = fileName;
            self.stations{1,1} = '';
            self.custClasses{1,1} = '';
            self.perfIndices{1,1} = '';
            self.connections{1,1} = '';
            self.jmtPath = jarPath;
        end
        
        %Setter
        function self = setJMTJarPath(self, path)
            self.jmtPath = path;
        end
        
        % Getter
        function out = getJMTJarPath(self)
            out = self.jmtPath;
        end
        
        %Setter
        function self = setFileName(self, fileName)
            self.fileName = fileName;
        end
        
        function out = getFileName(self)
            out = self.fileName;
        end
        
        function Tsim=runSimulation(self, maxSamples)
            self.maxSamples = maxSamples;
            save_jsimg(self);
            tic;
            if ispc
                system(['java -cp ',self.getJMTJarPath(),'/*;. jmt.commandline.Jmt sim .\', self.fileName, '.jsimg']);
            elseif isunix
                system(['java -cp ',self.getJMTJarPath(),'/JMT.jar jmt.commandline.Jmt sim ./', self.fileName, '.jsimg']);
            end
            Tsim=toc;
        end
        
        function [results, parsed] = getResults(self)
            if ispc
                parsed = xml_read(strcat(pwd,'\',self.fileName,'.jsimg-result.jsim'));
            elseif isunix
                parsed = xml_read(strcat(pwd,'/',self.fileName,'.jsimg-result.jsim'));
            end
            results.('model') = parsed.ATTRIBUTE;
            results.('metric') = {parsed.measure.ATTRIBUTE};
        end
        
        function [simElem,simNode] = save_xmlheader(self)
            docNode = com.mathworks.xml.XMLUtils.createDocument('archive');
            simNode = com.mathworks.xml.XMLUtils.createDocument('sim');
            simElem = simNode.getDocumentElement;
            simElem.setAttribute('xmlns:xsi', self.xmlnsXsi);
            simElem.setAttribute('disableStatisticStop', 'true');
            simElem.setAttribute('logDecimalSeparator', '.');
            simElem.setAttribute('logDelimiter', ';');
            simElem.setAttribute('logPath', '');
            simElem.setAttribute('logReplaceMode', '0');
            simElem.setAttribute('maxSamples', int2str(self.maxSamples));
            simElem.setAttribute('name', getFileNameExtension(self));
            simElem.setAttribute('polling', '1.0');
            simElem.setAttribute('xsi:noNamespaceSchemaLocation', 'SIMmodeldefinition.xsd');
        end
        
        function [simElem, simNode] = save_classes(self, simElem, simNode)
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1),
                currentClass = self.custClasses{i,1};
                userClass = simNode.createElement('userClass');
                userClass.setAttribute('name', currentClass.name);
                userClass.setAttribute('type', currentClass.type);
                userClass.setAttribute('priority', int2str(currentClass.priority));
                userClass.setAttribute('referenceSource', currentClass.referenceStation.name);
                if strcmp(currentClass.type, 'closed') % do nothing if open
                    userClass.setAttribute('customers', int2str(currentClass.population));
                end
                simElem.appendChild(userClass);
            end
        end
        
        function [simElem, simNode] = save_perfindexes(self, simElem, simNode)
            
            numOfPerformanceIndices = length(self.perfIndices);
            for j=1:(numOfPerformanceIndices - 1),
                currentPerformanceIndex = self.perfIndices{j,1};
                performanceNode = simNode.createElement('measure');
                performanceNode.setAttribute('alpha', num2str(1 - currentPerformanceIndex.confInt,2));
                performanceNode.setAttribute('name', strcat('Performance_', int2str(j)));
                performanceNode.setAttribute('nodeType', 'station');
                performanceNode.setAttribute('precision', num2str(currentPerformanceIndex.maxRelErr,2));
                performanceNode.setAttribute('referenceNode', currentPerformanceIndex.station.name);
                performanceNode.setAttribute('referenceUserClass', currentPerformanceIndex.class.name);
                performanceNode.setAttribute('type', currentPerformanceIndex.type);
                performanceNode.setAttribute('verbose', 'false');
                simElem.appendChild(performanceNode);
            end
        end
        
        function [simElem, simNode] = save_connections(self, simElem, simNode)
            numOfConnections = length(self.connections);
            for j=1:(numOfConnections - 1),
                currentConnection = self.connections{j,1};
                connectionNode = simNode.createElement('connection');
                connectionNode.setAttribute('source', currentConnection{1}.name);
                connectionNode.setAttribute('target', currentConnection{2}.name);
                simElem.appendChild(connectionNode);
            end
        end
        
        function [simNode, section] = save_dropstrategy(self, simNode, section)
            queueStrategyNode = simNode.createElement('parameter');
            queueStrategyNode.setAttribute('array', 'true');
            queueStrategyNode.setAttribute('classPath', 'java.lang.String');
            queueStrategyNode.setAttribute('name', 'dropStrategies');
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1),
                currentClass = self.custClasses{i,1};
                
                refClassNode = simNode.createElement('refClass');
                refClassNode.appendChild(simNode.createTextNode(currentClass.name));
                queueStrategyNode.appendChild(refClassNode);
                
                subParameterNode = simNode.createElement('subParameter');
                subParameterNode.setAttribute('classPath', 'java.lang.String');
                subParameterNode.setAttribute('name', 'dropStrategy');
                
                valueNode2 = simNode.createElement('value');
                valueNode2.appendChild(simNode.createTextNode('drop'));
                
                subParameterNode.appendChild(valueNode2);
                queueStrategyNode.appendChild(subParameterNode);
                section.appendChild(queueStrategyNode);
            end
        end
        
        function [simNode, section] = save_getstrategy(self, simNode, section, currentNode)
            queueGetStrategyNode = simNode.createElement('parameter');
            switch currentNode.queuePolicy
                case QueuePolicy.NP
                    queueGetStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.QueueGetStrategies.FCFSstrategy');
                    queueGetStrategyNode.setAttribute('name', 'FCFSstrategy');
                case QueuePolicy.PS
                    queueGetStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.QueueGetStrategies.FCFSstrategy');
                    queueGetStrategyNode.setAttribute('name', 'PSStrategy');
            end
            section.appendChild(queueGetStrategyNode);
        end
        
        function [simNode, section] = save_putstrategy(self, simNode, section, currentNode)
            queuePutStrategyNode = simNode.createElement('parameter');
            queuePutStrategyNode.setAttribute('array', 'true');
            queuePutStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.QueuePutStrategy');
            queuePutStrategyNode.setAttribute('name', 'NetStrategy');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1),
                currentClass = self.custClasses{i,1};
                
                refClassNode2 = simNode.createElement('refClass');
                refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
                
                queuePutStrategyNode.appendChild(refClassNode2);
                switch currentNode.queue.queueCustomerClasses{i}{2}
                    case QueueStrategy.Random
                        subParameterNode2 = simNode.createElement('subParameter');
                        subParameterNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.QueuePutStrategies.RandStrategy');
                        subParameterNode2.setAttribute('name', 'RandStrategy');
                    case QueueStrategy.LJF
                        subParameterNode2 = simNode.createElement('subParameter');
                        subParameterNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.QueuePutStrategies.LJFStrategy');
                        subParameterNode2.setAttribute('name', 'LJFStrategy');
                    case QueueStrategy.SJF
                        subParameterNode2 = simNode.createElement('subParameter');
                        subParameterNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.QueuePutStrategies.SJFStrategy');
                        subParameterNode2.setAttribute('name', 'SJFStrategy');
                    case QueueStrategy.LCFS
                        subParameterNode2 = simNode.createElement('subParameter');
                        subParameterNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.QueuePutStrategies.HeadStrategy');
                        subParameterNode2.setAttribute('name', 'HeadStrategy');
                    otherwise % treat as FCFS - this is important for PS
                        subParameterNode2 = simNode.createElement('subParameter');
                        subParameterNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.QueuePutStrategies.TailStrategy');
                        subParameterNode2.setAttribute('name', 'TailStrategy');
                end
                queuePutStrategyNode.appendChild(subParameterNode2);
                section.appendChild(queuePutStrategyNode);
            end
        end
        
        function [simNode, section] = save_buffercapacity(self, simNode, section, currentNode)
            %Size
            sizeNode = simNode.createElement('parameter');
            sizeNode.setAttribute('classPath', 'java.lang.Integer');
            sizeNode.setAttribute('name', 'size');
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode(int2str(currentNode.bufferCapacity)));
            
            sizeNode.appendChild(valueNode);
            section.appendChild(sizeNode);
        end
        
        function [simNode, section] = save_server_numservers(self, simNode, section, currentNode)
            sizeNode = simNode.createElement('parameter');
            sizeNode.setAttribute('classPath', 'java.lang.Integer');
            sizeNode.setAttribute('name', 'maxJobs');
            
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode(int2str(currentNode.numberOfServers)));
            
            sizeNode.appendChild(valueNode);
            section.appendChild(sizeNode);
        end
        
        function [simNode, section] = save_server_visits(self, simNode, section)
            visitsNode = simNode.createElement('parameter');
            visitsNode.setAttribute('array', 'true');
            visitsNode.setAttribute('classPath', 'java.lang.Integer');
            visitsNode.setAttribute('name', 'numberOfVisits');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1),
                currentClass = self.custClasses{i,1};
                
                refClassNode = simNode.createElement('refClass');
                refClassNode.appendChild(simNode.createTextNode(currentClass.name));
                visitsNode.appendChild(refClassNode);
                
                subParameterNode = simNode.createElement('subParameter');
                subParameterNode.setAttribute('classPath', 'java.lang.Integer');
                subParameterNode.setAttribute('name', 'numberOfVisits');
                
                valueNode2 = simNode.createElement('value');
                valueNode2.appendChild(simNode.createTextNode(int2str(1)));
                
                subParameterNode.appendChild(valueNode2);
                visitsNode.appendChild(subParameterNode);
                section.appendChild(visitsNode);
            end
        end
        
        function [simNode, section] = save_joinstrategy(self, simNode, section, currentNode)
            strategyNode = simNode.createElement('parameter');
            strategyNode.setAttribute('array', 'true');
            strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategy');
            strategyNode.setAttribute('name', 'JoinStrategy');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1)
                currentClass = self.custClasses{i,1};
                switch currentNode.queue.joinStrategy{currentClass.index}
                    case JoinStrategy.Standard
                        refClassNode2 = simNode.createElement('refClass');
                        refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
                        strategyNode.appendChild(refClassNode2);
                        
                        joinStrategyNode = simNode.createElement('subParameter');
                        joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.NormalJoin');
                        joinStrategyNode.setAttribute('name', 'Standard Join');
                        reqNode = simNode.createElement('subParameter');
                        reqNode.setAttribute('classPath', 'java.lang.Integer');
                        reqNode.setAttribute('name', 'numRequired');
                        valueNode = simNode.createElement('value');
                        valueNode.appendChild(simNode.createTextNode(int2str(currentNode.queue.joinRequired{currentClass.index})));
                        reqNode.appendChild(valueNode);
                        joinStrategyNode.appendChild(reqNode);
                        strategyNode.appendChild(joinStrategyNode);
                        section.appendChild(strategyNode);
                    case JoinStrategy.Quorum
                        refClassNode2 = simNode.createElement('refClass');
                        refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
                        strategyNode.appendChild(refClassNode2);
                        
                        joinStrategyNode = simNode.createElement('subParameter');
                        joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.PartialJoin');
                        joinStrategyNode.setAttribute('name', 'Quorum');
                        reqNode = simNode.createElement('subParameter');
                        reqNode.setAttribute('classPath', 'java.lang.Integer');
                        reqNode.setAttribute('name', 'numRequired');
                        valueNode = simNode.createElement('value');
                        valueNode.appendChild(simNode.createTextNode(int2str(currentNode.queue.joinRequired{currentClass.index})));
                        reqNode.appendChild(valueNode);
                        joinStrategyNode.appendChild(reqNode);
                        strategyNode.appendChild(joinStrategyNode);
                        section.appendChild(strategyNode);
                    case JoinStrategy.Guard
                        refClassNode2 = simNode.createElement('refClass');
                        refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
                        strategyNode.appendChild(refClassNode2);
                        
                        joinStrategyNode = simNode.createElement('subParameter');
                        joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.PartialJoin');
                        joinStrategyNode.setAttribute('name', 'Quorum');
                        reqNode = simNode.createElement('subParameter');
                        reqNode.setAttribute('classPath', 'java.lang.Integer');
                        reqNode.setAttribute('name', 'numRequired');
                        valueNode = simNode.createElement('value');
                        valueNode.appendChild(simNode.createTextNode(int2str(currentNode.queue.joinRequired{currentClass.index})));
                        reqNode.appendChild(valueNode);
                        joinStrategyNode.appendChild(reqNode);
                        strategyNode.appendChild(joinStrategyNode);
                        section.appendChild(strategyNode);
                end
            end
        end
        
        function [simNode, section] = save_arrivalstrategy(self, simNode, section, currentNode)
            strategyNode = simNode.createElement('parameter');
            strategyNode.setAttribute('array', 'true');
            strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategy');
            strategyNode.setAttribute('name', 'ServiceStrategy');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1)
                currentClass = self.custClasses{i,1};
                switch currentClass.type
                    case 'closed'
                        refClassNode2 = simNode.createElement('refClass');
                        refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
                        strategyNode.appendChild(refClassNode2);
                        
                        serviceTimeStrategyNode = simNode.createElement('subParameter');
                        serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
                        serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
                        subParValue = simNode.createElement('value');
                        subParValue.appendChild(simNode.createTextNode('null'));
                        serviceTimeStrategyNode.appendChild(subParValue);
                        strategyNode.appendChild(serviceTimeStrategyNode);
                        section.appendChild(strategyNode);
                        
                    case 'open'
                        refClassNode2 = simNode.createElement('refClass');
                        refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
                        strategyNode.appendChild(refClassNode2);
                        
                        serviceTimeStrategyNode = simNode.createElement('subParameter');
                        serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
                        serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
                        
                        distributionNode = simNode.createElement('subParameter');
                        distributionObj = currentNode.queue.sourceCustClasses{i}{end};
                        distributionNode.setAttribute('classPath', distributionObj.javaClass);
                        distributionNode.setAttribute('name', distributionObj.name);
                        serviceTimeStrategyNode.appendChild(distributionNode);
                        
                        distrParNode = simNode.createElement('subParameter');
                        distrParNode.setAttribute('classPath', distributionObj.javaParClass);
                        distrParNode.setAttribute('name', 'distrPar');
                        
                        for k=1:distributionObj.getNumParams()
                            subParNode = simNode.createElement('subParameter');
                            subParNode.setAttribute('classPath', distributionObj.getParam(k).paramClass);
                            subParNode.setAttribute('name', distributionObj.getParam(k).paramName);
                            subParValue = simNode.createElement('value');
                            switch distributionObj.getParam(k).paramClass
                                case 'java.lang.Double'
                                    subParValue.appendChild(simNode.createTextNode(sprintf('%d',distributionObj.getParam(k).paramValue)));
                                case 'java.lang.String'
                                    subParValue.appendChild(simNode.createTextNode(distributionObj.getParam(k).paramValue));
                            end
                            subParNode.appendChild(subParValue);
                            distrParNode.appendChild(subParNode);
                        end
                        
                        serviceTimeStrategyNode.appendChild(distrParNode);
                        strategyNode.appendChild(serviceTimeStrategyNode);
                        section.appendChild(strategyNode);
                end
            end
        end
        
        function [simNode, section] = save_servicestrategy(self, simNode, section, currentNode)
            strategyNode = simNode.createElement('parameter');
            strategyNode.setAttribute('array', 'true');
            strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategy');
            strategyNode.setAttribute('name', 'ServiceStrategy');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1),
                currentClass = self.custClasses{i,1};
                refClassNode2 = simNode.createElement('refClass');
                refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
                strategyNode.appendChild(refClassNode2);
                
                serviceTimeStrategyNode = simNode.createElement('subParameter');
                serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
                serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
                
                distributionNode = simNode.createElement('subParameter');
                distributionObj = currentNode.server.serverCustomerClasses{i}{end};
                distributionNode.setAttribute('classPath', distributionObj.javaClass);
                distributionNode.setAttribute('name', distributionObj.name);
                serviceTimeStrategyNode.appendChild(distributionNode);
                
                distrParNode = simNode.createElement('subParameter');
                distrParNode.setAttribute('classPath', distributionObj.javaParClass);
                distrParNode.setAttribute('name', 'distrPar');
                
                for k=1:distributionObj.getNumParams()
                    subParNode = simNode.createElement('subParameter');
                    subParNode.setAttribute('classPath', distributionObj.getParam(k).paramClass);
                    subParNode.setAttribute('name', distributionObj.getParam(k).paramName);
                    subParValue = simNode.createElement('value');
                    switch distributionObj.getParam(k).paramClass
                        case 'java.lang.Double'
                            subParValue.appendChild(simNode.createTextNode(sprintf('%d',distributionObj.getParam(k).paramValue)));
                        case 'java.lang.String'
                            subParValue.appendChild(simNode.createTextNode(distributionObj.getParam(k).paramValue));
                    end
                    subParNode.appendChild(subParValue);
                    distrParNode.appendChild(subParNode);
                end
                
                serviceTimeStrategyNode.appendChild(distrParNode);
                strategyNode.appendChild(serviceTimeStrategyNode);
                section.appendChild(strategyNode);
            end
        end
        
        function [simNode, section] = save_classswitchstrategy(self, simNode, section, currentNode)
            paramNode = simNode.createElement('parameter');
            paramNode.setAttribute('array', 'true');
            paramNode.setAttribute('classPath', 'java.lang.Object');
            paramNode.setAttribute('name', 'matrix');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1)
                currentClass = self.custClasses{i,1};
                
                refClassNode = simNode.createElement('refClass');
                refClassNode.appendChild(simNode.createTextNode(currentClass.name));
                paramNode.appendChild(refClassNode);
                
                
                subParNodeRow = simNode.createElement('subParameter');
                subParNodeRow.setAttribute('array', 'true');
                subParNodeRow.setAttribute('classPath', 'java.lang.Float');
                subParNodeRow.setAttribute('name', 'row');
                for j=1:(numOfClasses - 1)
                    nextClass = self.custClasses{j,1};
                    
                    refClassNode = simNode.createElement('refClass');
                    refClassNode.appendChild(simNode.createTextNode(nextClass.name));
                    subParNodeRow.appendChild(refClassNode);
                    
                    subParNodeCell = simNode.createElement('subParameter');
                    subParNodeCell.setAttribute('classPath', 'java.lang.Float');
                    subParNodeCell.setAttribute('name', 'cell');
                    valNode = simNode.createElement('value');
                    valNode.appendChild(simNode.createTextNode(num2str(currentNode.server.classSwitchMatrix(i,j))));
                    subParNodeCell.appendChild(valNode);
                    subParNodeRow.appendChild(subParNodeCell);
                    
                end
                paramNode.appendChild(subParNodeRow);
                
            end
            section.appendChild(paramNode);
            
        end
        
        function [simNode, section] = save_routingstrategy(self, simNode, section, currentNode)
            strategyNode = simNode.createElement('parameter');
            strategyNode.setAttribute('array', 'true');
            strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategy');
            strategyNode.setAttribute('name', 'RoutingStrategy');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1),
                currentClass = self.custClasses{i,1};
                
                refClassNode = simNode.createElement('refClass');
                refClassNode.appendChild(simNode.createTextNode(currentClass.name));
                strategyNode.appendChild(refClassNode);
                
                switch RoutingStrategy.toText(currentNode.router.routerCustomerClasses{i}{2})
                    case 'Random'
                        concStratNode = simNode.createElement('subParameter');
                        concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.RandomStrategy');
                        concStratNode.setAttribute('name', 'Random');
                    case 'RoundRobin'
                        concStratNode = simNode.createElement('subParameter');
                        concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.RoundRobinStrategy');
                        concStratNode.setAttribute('name', 'Round Robin');
                    case 'Probabilities'
                        concStratNode = simNode.createElement('subParameter');
                        concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.EmpiricalStrategy');
                        concStratNode.setAttribute('name', 'Probabilities');
                        concStratNode2 = simNode.createElement('subParameter');
                        concStratNode2.setAttribute('array', 'true');
                        concStratNode2.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
                        concStratNode2.setAttribute('name', 'EmpiricalEntryArray');
                        for k=1:length(currentNode.router.routerCustomerClasses{i}{end})
                            concStratNode3 = simNode.createElement('subParameter');
                            concStratNode3.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
                            concStratNode3.setAttribute('name', 'EmpiricalEntry');
                            concStratNode4Station = simNode.createElement('subParameter');
                            concStratNode4Station.setAttribute('classPath', 'java.lang.String');
                            concStratNode4Station.setAttribute('name', 'stationName');
                            concStratNode4StationValueNode = simNode.createElement('value');
                            concStratNode4StationValueNode.appendChild(simNode.createTextNode(sprintf('%s',currentNode.router.routerCustomerClasses{i}{end}{k}{1}.name)));
                            concStratNode4Station.appendChild(concStratNode4StationValueNode);
                            concStratNode3.appendChild(concStratNode4Station);
                            concStratNode4Probability = simNode.createElement('subParameter');
                            concStratNode4Probability.setAttribute('classPath', 'java.lang.Double');
                            concStratNode4Probability.setAttribute('name', 'probability');
                            concStratNode4ProbabilityValueNode = simNode.createElement('value');
                            concStratNode4ProbabilityValueNode.appendChild(simNode.createTextNode(sprintf('%d',currentNode.router.routerCustomerClasses{i}{end}{k}{2})));
                            concStratNode4Probability.appendChild(concStratNode4ProbabilityValueNode);
                            
                            concStratNode3.appendChild(concStratNode4Station);
                            concStratNode3.appendChild(concStratNode4Probability);
                            concStratNode2.appendChild(concStratNode3);
                        end
                        concStratNode.appendChild(concStratNode2);
                end
                strategyNode.appendChild(concStratNode);
                section.appendChild(strategyNode);
            end
            
        end
        
        function [simNode, section] = save_logtunnel(self, simNode, section, currentNode)
            
            loggerNodesCP = {'java.lang.String','java.lang.String'};
            for i=3:9 loggerNodesCP{i} = 'java.lang.Boolean'; end
            loggerNodesCP{10} = 'java.lang.Integer';
            
            loggerNodesNames = {'logfileName','logfilePath','logExecTimestamp', ...
                'logLoggerName','logTimeStamp','logJobID', ...
                'logJobClass','logTimeSameClass','logTimeAnyClass', ...
                'numClasses'};
            numOfClasses = length(self.custClasses) - 1;
            loggerNodesValues = {currentNode.fileName,currentNode.filePath, ...
                currentNode.wantExecTimestamp,currentNode.wantLoggerName, ...
                currentNode.wantTimeStamp,currentNode.wantJobID, ...
                currentNode.wantJobClass,currentNode.wantTimeSameClass, ...
                currentNode.wantTimeAnyClass,int2str(numOfClasses)};
            
            for j=1:length(loggerNodesValues)
                loggerNode = simNode.createElement('parameter');
                loggerNode.setAttribute('classPath', loggerNodesCP{j});
                loggerNode.setAttribute('name', loggerNodesNames{j});
                valueNode = simNode.createElement('value');
                valueNode.appendChild(simNode.createTextNode(loggerNodesValues{j}));
                loggerNode.appendChild(valueNode);
                section.appendChild(loggerNode);
            end
        end
        
        function [simNode, section] = save_forkstrategy(self, simNode, section, currentNode)
            jplNode = simNode.createElement('parameter');
            jplNode.setAttribute('classPath', 'java.lang.Integer');
            jplNode.setAttribute('name', 'jobsPerLink');
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode(int2str(currentNode.router.tasksPerLink)));
            jplNode.appendChild(valueNode);
            section.appendChild(jplNode);
            
            blockNode = simNode.createElement('parameter');
            blockNode.setAttribute('classPath', 'java.lang.Integer');
            blockNode.setAttribute('name', 'block');
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode(int2str(-1)));
            blockNode.appendChild(valueNode);
            section.appendChild(blockNode);
            
            issimplNode = simNode.createElement('parameter');
            issimplNode.setAttribute('classPath', 'java.lang.Boolean');
            issimplNode.setAttribute('name', 'isSimplifiedFork');
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode('true'));
            issimplNode.appendChild(valueNode);
            section.appendChild(issimplNode);
            
            strategyNode = simNode.createElement('parameter');
            strategyNode.setAttribute('array', 'true');
            strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategy');
            strategyNode.setAttribute('name', 'ForkStrategy');
            
            numOfClasses = length(self.custClasses);
            for i=1:(numOfClasses - 1),
                currentClass = self.custClasses{i,1};
                
                refClassNode = simNode.createElement('refClass');
                refClassNode.appendChild(simNode.createTextNode(currentClass.name));
                strategyNode.appendChild(refClassNode);
                
                concStratNode = simNode.createElement('subParameter');
                concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.ProbabilitiesFork');
                concStratNode.setAttribute('name', 'Branch Probabilities');
                concStratNode2 = simNode.createElement('subParameter');
                concStratNode2.setAttribute('array', 'true');
                concStratNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.OutPath');
                concStratNode2.setAttribute('name', 'EmpiricalEntryArray');
                for k=1:length(currentNode.router.routerCustomerClasses{i}{end})
                    concStratNode3 = simNode.createElement('subParameter');
                    concStratNode3.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.OutPath');
                    concStratNode3.setAttribute('name', 'OutPathEntry');
                    concStratNode4 = simNode.createElement('subParameter');
                    concStratNode4.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
                    concStratNode4.setAttribute('name', 'outUnitProbability');
                    concStratNode4Station = simNode.createElement('subParameter');
                    concStratNode4Station.setAttribute('classPath', 'java.lang.String');
                    concStratNode4Station.setAttribute('name', 'stationName');
                    concStratNode4StationValueNode = simNode.createElement('value');
                    concStratNode4StationValueNode.appendChild(simNode.createTextNode(sprintf('%s',currentNode.router.routerCustomerClasses{i}{end}{k}{1}.name)));
                    concStratNode4Station.appendChild(concStratNode4StationValueNode);
                    concStratNode3.appendChild(concStratNode4Station);
                    concStratNode4Probability = simNode.createElement('subParameter');
                    concStratNode4Probability.setAttribute('classPath', 'java.lang.Double');
                    concStratNode4Probability.setAttribute('name', 'probability');
                    concStratNode4ProbabilityValueNode = simNode.createElement('value');
                    concStratNode4ProbabilityValueNode.appendChild(simNode.createTextNode('1.0'));
                    concStratNode4Probability.appendChild(concStratNode4ProbabilityValueNode);
                    
                    concStratNode4b = simNode.createElement('subParameter');
                    concStratNode4b.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
                    concStratNode4b.setAttribute('array', 'true');
                    concStratNode4b.setAttribute('name', 'JobsPerLinkDis');
                    concStratNode5b = simNode.createElement('subParameter');
                    concStratNode5b.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
                    concStratNode5b.setAttribute('name', 'EmpiricalEntry');
                    concStratNode5bStation = simNode.createElement('subParameter');
                    concStratNode5bStation.setAttribute('classPath', 'java.lang.String');
                    concStratNode5bStation.setAttribute('name', 'numbers');
                    concStratNode5bStationValueNode = simNode.createElement('value');
                    concStratNode5bStationValueNode.appendChild(simNode.createTextNode('1'));
                    concStratNode5bStation.appendChild(concStratNode5bStationValueNode);
                    concStratNode4b.appendChild(concStratNode5bStation);
                    concStratNode5bProbability = simNode.createElement('subParameter');
                    concStratNode5bProbability.setAttribute('classPath', 'java.lang.Double');
                    concStratNode5bProbability.setAttribute('name', 'probability');
                    concStratNode5bProbabilityValueNode = simNode.createElement('value');
                    concStratNode5bProbabilityValueNode.appendChild(simNode.createTextNode('1.0'));
                    concStratNode5bProbability.appendChild(concStratNode5bProbabilityValueNode);
                    
                    concStratNode4.appendChild(concStratNode4Station);
                    concStratNode4.appendChild(concStratNode4Probability);
                    concStratNode3.appendChild(concStratNode4);
                    concStratNode5b.appendChild(concStratNode5bStation);
                    concStratNode5b.appendChild(concStratNode5bProbability);
                    concStratNode4b.appendChild(concStratNode5b);
                    concStratNode3.appendChild(concStratNode4b);
                    concStratNode2.appendChild(concStratNode3);
                    concStratNode.appendChild(concStratNode2);
                    strategyNode.appendChild(concStratNode);
                    section.appendChild(strategyNode);
                end
            end
        end
        
        function save_jsimg(self)
            [simElem, simNode] = save_xmlheader(self);
            [simElem, simNode] = save_classes(self, simElem, simNode);
            
            numOfClasses = length(self.custClasses);
            numOfStations = length(self.stations);
            for i=1:(numOfStations - 1),
                currentNode = self.stations{i,1};
                node = simNode.createElement('node');
                node.setAttribute('name', currentNode.name);
                
                nodeSections = getSections(currentNode);
                for j=1:length(nodeSections),
                    section = simNode.createElement('section');
                    currentSection = nodeSections{1,j};
                    if ~isempty(currentSection)
                        section.setAttribute('className', currentSection.className);
                        switch currentSection.className
                            case 'Queue'
                                [simNode, section] = save_buffercapacity(self, simNode, section, currentNode);
                                [simNode, section] = save_dropstrategy(self, simNode, section);
                                [simNode, section] = save_getstrategy(self, simNode, section, currentNode);
                                [simNode, section] = save_putstrategy(self, simNode, section, currentNode);
                            case {'Server','PSServer'}
                                [simNode, section] = save_server_numservers(self, simNode, section, currentNode);
                                [simNode, section] = save_server_visits(self, simNode, section);
                                [simNode, section] = save_servicestrategy(self, simNode, section, currentNode);
                            case 'Delay'
                                [simNode, section] = save_servicestrategy(self, simNode, section, currentNode);
                            case 'LogTunnel'
                                [simNode, section] = save_logtunnel(self, simNode, section, currentNode);
                            case 'Router'
                                [simNode, section] = save_routingstrategy(self, simNode, section, currentNode);
                            case 'ClassSwitch'
                                [simNode, section] = save_classswitchstrategy(self, simNode, section, currentNode);
                            case 'RandomSource'
                                [simNode, section] = save_arrivalstrategy(self, simNode, section, currentNode);
                            case 'Join'
                                [simNode, section] = save_joinstrategy(self, simNode, section, currentNode);
                            case 'Fork'
                                [simNode, section] = save_forkstrategy(self, simNode, section, currentNode);
                        end
                        node.appendChild(section);
                    end
                end
                simElem.appendChild(node);
            end
            
            [simElem, simNode] = save_perfindexes(self, simElem, simNode);
            [simElem, simNode] = save_connections(self, simElem, simNode);
            
            hasReferenceNodes = 0;
            preloadNode = simNode.createElement('preload');
            for i=1:(numOfStations - 1),
                isReferenceNode = 0;
                currentNode = self.stations{i,1};
                stationPopulationsNode = simNode.createElement('stationPopulations');
                stationPopulationsNode.setAttribute('stationName', currentNode.name);
                for r=1:(numOfClasses - 1),
                    currentClass = self.custClasses{r,1};
                    if currentClass.isReferenceStation(currentNode)
                        classPopulationNode = simNode.createElement('classPopulation');
                        switch currentClass.type
                            case 'closed'
                                isReferenceNode = 1;
                                classPopulationNode.setAttribute('population', sprintf('%d',currentClass.population));
                                classPopulationNode.setAttribute('refClass', currentClass.name);
                                stationPopulationsNode.appendChild(classPopulationNode);
                        end
                    end
                end
                if isReferenceNode
                    preloadNode.appendChild(stationPopulationsNode);
                end
                hasReferenceNodes = hasReferenceNodes + isReferenceNode;
            end
            if hasReferenceNodes
                simElem.appendChild(preloadNode);
            end
            xmlwrite(getJsimgFilePath(self), simNode);
        end
        
        function addCustomerClass(self, customerClass)
            classes = length(self.custClasses);
            customerClass.index = classes;
            self.custClasses{classes, 1} = customerClass;
            self.custClasses{classes + 1, 1} = '';
        end
        
        function addNode(self, node)
            numberOfNodes = length(self.stations);
            self.stations{numberOfNodes, 1} = node;
            self.stations{numberOfNodes + 1, 1} = '';
        end
        
        function addLink(self, nodeA, nodeB)
            numberOfConnections = length(self.connections);
            self.connections{numberOfConnections, 1} = {nodeA, nodeB};
            self.connections{numberOfConnections + 1, 1} = '';
        end
        
        function [loggerBefore,loggerAfter] = linkNetworkAndLog(self, nodes, classes, P, wantLogger, logPath)
            R = length(classes);
            M = length(nodes);
            Mp = 3*M;
            loggerBefore = cell(1,M);
            loggerAfter = cell(1,M);
            for i=1:M
                if wantLogger(i)
                    if ispc
                        loggerBefore{i} = LoggerStation(self,sprintf('Arv%03d',i),[logPath,'\',sprintf('logArv%03d.csv',i)]);
                        loggerAfter{i} = LoggerStation(self,sprintf('Dep%03d',i),[logPath,'\',sprintf('logDep%03d.csv',i)]);
                    elseif isunix
                        loggerBefore{i} = LoggerStation(self,sprintf('Arv%03d',i),[logPath,'/',sprintf('logArv%03d.csv',i)]);
                        loggerAfter{i} = LoggerStation(self,sprintf('Dep%03d',i),[logPath,'/',sprintf('logDep%03d.csv',i)]);
                    end
                end
            end
            for r=1:R
                for s=1:R
                    Pp{r,s} = zeros(Mp);
                    for i=1:M
                        for j=1:M
                            if P{r,s}(i,j)>0
                                if wantLogger(i) && wantLogger(j)
                                    % link logAi to logBj
                                    Pp{r,s}(2*M+i,M+j) = P{r,s}(i,j);
                                elseif wantLogger(i) && ~wantLogger(j)
                                    % link logAi to j
                                    Pp{r,s}(2*M+i,j) = P{r,s}(i,j);
                                elseif ~wantLogger(i) && wantLogger(j)
                                    % link i to logBj
                                    Pp{r,s}(i,M+j) = P{r,s}(i,j);
                                else
                                    % link i to j
                                    Pp{r,s}(i,j) = P{r,s}(i,j);
                                end
                            end
                        end
                    end
                    for i=1:M
                        if wantLogger(i)
                            Pp{r,s}(M+i,i) = 1.0; % logBi -> i
                            Pp{r,s}(i,2*M+i) = 1.0; % i -> logAi
                        end
                    end
                end
            end
            for r=1:R
                for s=1:R
                    idx = find(wantLogger);
                    Pp{r,s} = Pp{r,s}([1:M,M+idx,2*M+idx],[1:M,M+idx,2*M+idx]);
                end
            end
            stations = {nodes{:},loggerBefore{find(wantLogger)},loggerAfter{find(wantLogger)}};
            linkNetwork(self, stations, classes, Pp);
        end
        
        function linkNetwork(self, nodes, classes, P)
            R = length(classes);
            M = length(nodes);
            
            for i=1:M
                for j=1:M
                    csMatrix{i,j} = [];
                    for r=1:R
                        for s=1:R
                           
                            csMatrix{i,j}(r,s) = P{r,s}(i,j);
                        end
                    end
                    
                end
            end
            
            
            csid = zeros(M);
            for i=1:M
                for j=1:M
                    if ~isdiag(csMatrix{i,j})
                        nodes{end+1} = ClassSwitchStation(self, sprintf('_CS%d%d',i,j),csMatrix{i,j});
                        csid(i,j)=length(nodes);
                    end
                end
            end
            
            Mplus = length(nodes); % number of nodes after addition of cs nodes

            % resize matrices
            for r=1:R
                for s=1:R
                    P{r,s}((M+1):Mplus,(M+1):Mplus)=0;
                end
            end

            
            for i=1:M
                for j=1:M
                    if csid(i,j)>0
                        % re-route
                        for r=1:R
                            for s=1:R
                                P{r,r}(i,csid(i,j)) = P{r,r}(i,csid(i,j))+ P{r,s}(i,j);
                                P{r,s}(i,j) = 0;
                                P{s,s}(csid(i,j),j) = 1;
                            end
                        end
                    end
                end
            end
            
            connected = zeros(Mplus);
            
            for i=1:Mplus
                for j=1:Mplus
                    for r=1:R
                        if P{r,r}(i,j) > 0
                            if connected(i,j) == 0
                                self.addLink(nodes{i}, nodes{j});
                                connected(i,j) = 1;
                            end
                            nodes{i}.setProbRouting(classes{r}, nodes{j}, P{r,r}(i,j));
                        end
                    end
                end
            end
        end
        
        function addMeasure(self, performanceIndex)
            numberOfIndices = length(self.perfIndices);
            self.perfIndices{numberOfIndices, 1} = performanceIndex;
            self.perfIndices{numberOfIndices + 1, 1} = '';
        end
        
    end
    
    %Private methods.
    methods (Access = 'private')
        function out = getJsimgFilePath(self)
            out = [Model.jsimgPath, getFileNameExtension(self)];
        end
        
        function out = getFileNameExtension(self)
            out = [getFileName(self), ['.', self.fileFormat]];
        end
    end
    
end
