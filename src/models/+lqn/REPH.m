classdef REPH
% REPH defines Random Environment objects, which interact with the 
% Layered Queueing Network (LQN) model to extend its modeling capabilities. 
% Different from RE, an REPH may have Coxian holding times in each of the
% environmental stages. 
% More details on Random Environments and their interaction with LQN models can be found 
% on the LINE documentation, available at http://line-solver.sf.net
%
% Properties:
% ID:                   unique identifier of this RE (integer)
% numStages:            number of environmental stages in the RE (integer)
% sojTimes:             numStages x 1 cell with either float or string entries
%                       a float entry denotes the mean sojourn time in each stage
%                       a string entry denotes the id of the Cox distribution
%                       associated with the sojourn time in each stage
% transProbs:           numStages x numStages array (double) 
%                       transition probability matrix 
% resetRules:           rules to define how the ongoing services behave under a stage transition (string array)
% stageNames:           stages' names (string array)
% parameters:           list of the parameters in the LQN model that are affected by this RE
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    ID;         % id
    numStages;  % number of environmental stages
    sojTimes;   % numStages x 1 cell with either float or string entries
                % a float entry denotes the mean sojourn time in each stage
                % a string entry denotes the id of the Cox distribution
                % associated with the sojourn time in each stage
    transProbs; % numStages x numStages array (double) 
                % transition probability matrix 
    resetRules; % reset rule for each stage transition
    stageNames; % name for each stage
    parameters; % list of parameters associated to this RE
end

methods
    
    %constructor
    function obj = REPH(ID, numStages, sojTimes, transProbs, resetRules, stageNames)
        if nargin > 3           
            obj.ID = ID;
            obj.numStages = numStages;
            obj.sojTimes = sojTimes;
            obj.transProbs = transProbs;
            obj.resetRules = resetRules;
            obj.parameters = cell(0);
        end
        if nargin > 4
           obj.stageNames = stageNames;
        else
            obj.stageNames = cell(numStages,1);
            for i = 1:obj.numStages
                obj.stageNames{i,1} = ['stage',int2str(i)];
            end
        end
    end
    
    %addParameter
    % each parameter affected by this RE is added by providing:
    % elemID:       unique identifier of the element in the model to be affected
    % paramName:    name of the parameter of the element that is directly affected by the RE
    % factors:      list of the factors that modify the value of the parameter.
    %               the effective parameter value in each stage is obtained
    %               by multiplying its default value by the factors.
    %               There must be one factor for each stage in the RE            
    function obj = addParameter(obj, elemID, paramName, factors)
        if nargin == 4 && length(factors)==obj.numStages
            obj.parameters(end+1,:) = {elemID, paramName, factors};
        else
            disp(sprintf('Too few or too many parameters when adding parameter % of %s  ',paramName,elemID));
        end
    end
end
    
    
end
