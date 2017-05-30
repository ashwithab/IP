function [REs, REPHflag] = parseXML_REPH(doc)
% PARSEXML_REPH parses an XML file describing a 
% set of Random Environments (REs) with PH holding times
% If any of the RE has PH holding times, it returns a list of REPH objects,
% and the indicator REPH = 1. Otherwise, it returns a simpler list of RE
% objects and REPH = 0. 
%
% Parameters: 
% doc:          head of the XML object to parse
% verbose:      1 for screen output 
%
% Output:
% REs: random environments description
% REPHflag: equal to 1 if objects returned are REPH, 0 if these are RE.
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;

import lqn.RE; 
import lqn.REPH; 

%NodeList 
envList = doc.getElementsByTagName('environment');
REs = [];
RE_IDs = cell(0);
REPHflag = 0; % set this indicator initially to 0
for i = 0:envList.getLength()-1
    %Node - Processor
    envNode = envList.item(i);
    if envNode.getNodeType() == Node.ELEMENT_NODE
        envElement = envNode;
        ID = char(envElement.getAttribute('envID')); 
        numStages = str2num(char(envElement.getAttribute('numStages'))); 
        numStages = round(numStages);
        
        %Q = zeros(numStages);
        sojTimes = cell(numStages,1); 
        transProbs = zeros(numStages); 
        
        resetRules = cell(numStages,numStages);
        stageNames = cell(numStages,1);
        
        
        stageList = envNode.getElementsByTagName('stage');
        %%list of stages
        for j = 0:stageList.getLength()-1
            %Node - Task
            stageNode = stageList.item(j);
            if stageNode.getNodeType() == Node.ELEMENT_NODE
                %Element 
                stageElement = stageNode;
                nameStage = char(stageElement.getAttribute('name')); 
                stageNames{j+1,1} = nameStage;
            end
        end
        %%transitions
        for j = 0:stageList.getLength()-1
            %Node - Task
            stageNode = stageList.item(j);
            if stageNode.getNodeType() == Node.ELEMENT_NODE
                %Element 
                stageElement = stageNode;
                %meanTime = str2num(char(stageElement.getAttribute('meanTime'))); 
                %Q(j+1,j+1) = -1/meanTime;
                transList = stageNode.getElementsByTagName('transition');
                for k = 0:transList.getLength()-1
                    %Node - Task
                    transNode = transList.item(k);
                    if transNode.getNodeType() == Node.ELEMENT_NODE
                        %Element 
                        transElement = transNode;
                        destName = char(transElement.getAttribute('destName')); 
                        prob = str2num(char(transElement.getAttribute('prob')));
                        
                        stageDest = getIndexCellString(stageNames, destName);
                        %Q(j+1,stageDest) = prob/meanTime;
                        transProbs(j+1,stageDest) = prob;
                        
                        
                        resetRuleElement = transNode.getElementsByTagName('resetRule').item(0);
                        ruleName = char(resetRuleElement.getAttribute('ruleName'));
                        
                        resetRules{j+1,stageDest} = ruleName;
                    end
                end
                
                % get sojTime
                stageTimeNode = stageNode.getElementsByTagName('stageTime').item(0); 
                meanTimeNode = stageTimeNode.getElementsByTagName('meanTime').item(0); 
                coxIDNode = stageTimeNode.getElementsByTagName('coxID').item(0); 
                if ~isempty(meanTimeNode)
                    %meanTimeNode = meanTimeList.item(0);
                    sojTimes{j+1} = str2num(char(meanTimeNode.getTextContent()));
                else
                    %coxIDNode = coxIDList.item(0); 
                    sojTimes{j+1} = char(coxIDNode.getTextContent());
                    REPHflag = 1;
                end
                
                
            end
        end
        %myRE = RE(ID, numStages, Q, resetRules, stageNames);
        myRE = REPH(ID, numStages, sojTimes, transProbs, resetRules, stageNames);
        REs = [REs; myRE];
        RE_IDs{end+1,1} = ID;
    end
end

% check if all REs have exponential holding times to translate all the
% REPH objects into the simpler RE
if ~isempty(REs) && REPHflag == 0
    newREs = [];
    for i = length(REs); 
        myRE = REs(i);
        sojTimes = cell2mat(myRE.sojTimes);
        Q = - diag(sojTimes) + (sojTimes*ones(1,myRE.numStages)).*myRE.transProbs;
        newRE = RE(myRE.ID, myRE.numStages, Q, myRE.resetRules, myRE.stageNames);
        newREs = [newREs; newRE];
    end
    REs = newREs;
end





%read parameters that depend on the environments
paramList = doc.getElementsByTagName('envParameter');
for i = 0:paramList.getLength()-1
    paramNode = paramList.item(i);
    if paramNode.getNodeType() == Node.ELEMENT_NODE
        paramElement = paramNode;
        envID = char(paramElement.getAttribute('envID')); 
        paramName = char(paramElement.getAttribute('paramName')); 
        elemID = char(paramElement.getAttribute('id')); 
        
        envIdx = getIndexCellString(RE_IDs, envID);
        if envIdx ~= -1
            factors = ones(REs(envIdx).numStages,1);
            valueList = paramNode.getElementsByTagName('envValue');
            %%list of stages
            for j = 0:valueList.getLength()-1
                %Node - Task
                valueNode = valueList.item(j);
                if valueNode.getNodeType() == Node.ELEMENT_NODE
                    %Element 
                    valueElement = valueNode;
                    stage = char(valueElement.getAttribute('stage')); 
                    factor = str2num(char(valueElement.getAttribute('factor')));
                    k = getIndexCellString(REs(envIdx).stageNames, stage);
                    if k ~= -1
                        factors(k) = factor;
                    else
                        disp(sprintf('Reference to an undefined stage %s in environment %s', stage, envID));
                    end
                end
            end
            
            REs(envIdx) = REs(envIdx).addParameter(elemID, paramName, factors);
        else
            disp(sprintf('Reference to an undefined environment %s', envID));
        end
    end
end




