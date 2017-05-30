classdef COX
% COX defines Coxian distribution objects, which interact with the 
% Layered Queueing Network (LQN) model to extend its modeling capabilities. 
% More details on Coxian distributions and their interaction with LQN models can be found 
% on the LINE documentation, available at http://line-solver.sf.net
%
% Properties:
% ID:                   unique identifier of this COX distribution (integer)
% numPhases:            number of phases in the COX distribution (integer)
% rates:                rates in each phase of the COX distributions (double array)
% completionProbs:      completion probabilities of the COX distributions (double array)
% activities:           list of the activities in the LQN model that follow
%                       this COX distributions (string array)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    ID;                 % id
    numPhases;          % number of phases
    rates;              % rates
    completionProbs;    % completion probabilities
    activities;         % list of activities associated to this COX
end

methods
    
    % constructor
    function obj = COX(ID, numPhases, rates, completionProbs)
        if nargin > 3           
            obj.ID = ID;
            obj.numPhases = numPhases;
            obj.rates = rates;
            obj.completionProbs = completionProbs;
            obj.activities = cell(0);
        end
    end
    
    % addActivity
    % each activity that follows this COX distribution:
    % elemID:       unique identifier of the element in the model to be affected
    function obj = addParameter(obj, elemID)
        if isempty(obj.activities)
            obj.activities{1} = elemID;
        else
            obj.activities{end+1,:} = elemID;
        end
    end
end
    
    
end
