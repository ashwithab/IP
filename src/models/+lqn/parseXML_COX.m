function [COXs,COX_IDs] = parseXML_COX(doc)
% PARSEXML_COX(A) parses an XML file A describing a set of Coxian distributions
%
% Parameters: 
% doc:          head of the XML object to parse
% verbose:      1 for screen output 
%
% Output:
% COXs:         list of COX elements
% COX_IDs:      list of indices for the COX elements
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;

import lqn.COX;
% Read Cox distributions
%NodeList 
distList = doc.getElementsByTagName('coxDistribution');
COXs = [];
COX_IDs = cell(0);
for i = 0:distList.getLength()-1
    %Node - Processor
    distNode = distList.item(i);
    if distNode.getNodeType() == Node.ELEMENT_NODE
        distElement = distNode;
        ID = char(distElement.getAttribute('coxID')); 
        numPhases = str2num(char(distElement.getAttribute('numPhases'))); 
        numPhases = round(numPhases);
        
        rates = zeros(numPhases,1);
        completionProbs = zeros(numPhases,1);
        
        phaseList = distNode.getElementsByTagName('phase');
        %%list of stages
        for j = 0:phaseList.getLength()-1
            %Node - Task
            phaseNode = phaseList.item(j);
            if phaseNode.getNodeType() == Node.ELEMENT_NODE
                %Element 
                phaseElement = phaseNode;
                meanTime = str2num( char(phaseElement.getAttribute('meanTime')) ); 
                compProb = str2num( char(phaseElement.getAttribute('completionProb')) );
                phaseIdx = round(str2num( char(phaseElement.getAttribute('phaseIndex')) ));
                rates(phaseIdx) = 1/meanTime;
                completionProbs(phaseIdx) = compProb;
            end
        end
        myCOX = COX(ID, numPhases, rates, completionProbs);
        COXs = [COXs; myCOX];
        COX_IDs{end+1,1} = ID;
    end
end

%read parameters that follow these coxian distributions 
paramList = doc.getElementsByTagName('coxParameter');
for i = 0:paramList.getLength()-1
    paramNode = paramList.item(i);
    if paramNode.getNodeType() == Node.ELEMENT_NODE
        paramElement = paramNode;
        coxID = char(paramElement.getAttribute('coxID')); 
        elemID = char(paramElement.getAttribute('id')); 
        
        envIdx = getIndexCellString(COX_IDs, coxID);
        if envIdx ~= -1
            COXs(envIdx) = COXs(envIdx).addParameter(elemID);
        else
            disp(sprintf('Reference to an undefined Cox distribution %s', coxID));
        end
    end
end

