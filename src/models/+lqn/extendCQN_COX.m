function myCQN = extendCQN_COX(myCQN, COXs, activitiesProcs, activitiesClass, verbose)
% Q = EXTEND_CQN_COX(A) extends a CQN model A to include the Coxian procesing. 
% The extended model Q is % returned as a CQNCox object.
%
% Parameters:
% myCQN:            CQN model to be extended
% COXs:             list of Coxian distributions
% activitiesProcs:  list of LQN activities and processors where they execute
% activitiesClass:  list of LQN activities and the associated request
% verbose:          1 for screen output
% 
% Output:
% myCQN:            QN model extended with Coxian distributions
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


if nargin == 4; verbose = 0; end

if ~isempty(COXs)
    nodeNames = myCQN.nodeNames;
    % obtain Cox QN representation
    myCQN = CQN2CQNCox(myCQN);
    
    rates = myCQN.mu; 
    compProbs = myCQN.phi; 
    
    %% include COXs
    nDist = length(COXs); 
    for i = 1:nDist
        for j = 1:size(COXs(i).activities,1)
            % determine index of activity in list of activitiesProcs
            actIdx = getIndexCellString({activitiesProcs{:,1}}', COXs(i).activities{j});
            if actIdx ~= -1 
                procName = activitiesProcs{actIdx,4};
                % determine index of processor in CQN model
                procIdx = getIndexCellString(nodeNames, procName);
                if procIdx ~= -1 
                    actClasses = activitiesClass{actIdx}; 
                    for k = 1:length(actClasses)
                        rates{procIdx,actClasses(k)} = COXs(i).rates;
                        compProbs{procIdx,actClasses(k)} = COXs(i).completionProbs;
                    end
                end
            end
        end
    end
    
    myCQN.mu = rates;
    myCQN.phi = compProbs; 
else
   disp('Error: XML file ',filenameRE,' empty or unexistent');
   myCQN = [];
end

