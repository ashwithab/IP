function [myCQNCSRE] = extendCQNCOX_RE(myCQNCS, REs, verbose)
% Q = EXTEND_CQNCOX_RE(A,B) extends a CQN model with Coxian processing times A 
% to include the random environments (RE) described in the XML file B. 
% The extended model Q is returned as a CQNRECox object.
%
% Parameters:
% myCQNCS:      CQN model to be extended
% REs:          list of REs to include 
% verbose:      1 for screen output
% 
% Output:
% myCQNRE:      QN model extended with random environments
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


if nargin == 2; verbose = 0; end

if ~isempty(REs)
    M = myCQNCS.M;
    K = myCQNCS.K;
    N = myCQNCS.N;
    S = myCQNCS.S;
    mu = myCQNCS.mu;
    phi = myCQNCS.phi;
    sched = myCQNCS.sched;
    P = myCQNCS.P;
    NK = myCQNCS.NK;
    refNodes =myCQNCS.refNodes; 
    nodeNames = myCQNCS.nodeNames;
    classNames = myCQNCS.classNames;

    %% include REs
    nE = length(REs);
    E=1;
    numStages = zeros(nE,1);
    for i = 1:nE
        E = E*REs(i).numStages;
        numStages(i) = REs(i).numStages; 
    end

    %build a code to interpret resetRules numerically - easier composition
    totRules = 0;
    allRules = cell(0);
    numRules = cell(nE,1); % numerical representation of rules
    for i = 1:nE
        numRules{i} = zeros(REs(i).numStages);
        for j = 1:REs(i).numStages
            for k = [1:j-1 j+1:REs(i).numStages]
                currRule = REs(i).resetRules{j,k};
                if isempty(currRule)
                    currCode = 0;
                else
                    currCode = getIndexCellString(allRules, currRule);
                    if currCode == -1 && ~isempty(currRule) % new rule found
                        allRules{end+1,1} = currRule;
                        totRules = totRules + 1;
                        currCode = totRules;
                    end
                end
                numRules{i}(j,k) = currCode;
            end
        end
    end


    if nE == 1
        stageIndex = [1:E]';
        ENV = REs(1).Q;
        fullResetRules = REs(1).resetRules;
    else
        stageIndex = zeros(E,nE); % stage of each RE in the full RE
        stageIndex(:,1) = kron( [1:numStages(1)]', ones(sum(numStages(2:end)),1) );
        ENV = kron( REs(1).Q,  eye(sum(numStages(2:end)))  );
        fullNumResetRules = kron( numRules{1},  eye(sum(numStages(2:end)))  );
        for i = 2:nE-1
            ENV = ENV + kron( eye(sum(numStages(1:i-1))), ...
                kron( REs(i).Q,  eye(sum(numStages(i+1:end))) ) );
            stageIndex(:,i) = kron( ones(sum(numStages(1:i-1)),1), ...
                kron( [1:numStages(i)]', ones(sum(numStages(i+1:end)),1) ) );
            fullNumResetRules = fullNumResetRules + kron( eye(sum(numStages(1:i-1))), ...
                kron( numRules{i},  eye(sum(numStages(i+1:end))) ) );
        end
        ENV = ENV + kron( eye(sum(numStages(1:nE-1))), REs(nE).Q ) ;
        stageIndex(:,nE) = kron( ones(sum(numStages(1:nE-1)),1) , [1:numStages(nE)]');
        fullNumResetRules = fullNumResetRules + kron( eye(sum(numStages(1:nE-1))), numRules{nE} );

        fullResetRules = cell(E,E); % read back the reset rules
        for i = 1:E
            for j = [1:i-1 i+1:E]
                if fullNumResetRules(i,j) > 0
                    fullResetRules{i,j} = allRules{ fullNumResetRules(i,j) };
                end
            end
        end
    end


    envS = cell(E,1);
    envMu = cell(E,M,K);
    envPhi = cell(E,M,K);
    envP = cell(E,1);
    for j = 1:E
        envS{j} = S;
        envP{j} = P;
        for i = 1:M
            for k = 1:K
                envMu{j,i,k} = mu{i,k};
                envPhi{j,i,k} = phi{i,k};
            end
        end
    end

    %modify parameter values
    for i = 1:nE
        for j = 1:size( REs(i).parameters, 1)
            elemID = REs(i).parameters{j,1};
            procIdx = getIndexCellString(nodeNames, elemID); %index in the list of hardware processors
            if procIdx ~= -1 %&& actProcs{procIdx,2} ~= delayProcIndex%considers hardware processors only (not delay either)
                switch REs(i).parameters{j,2} %evaluate parameter to modify in this processor
                    case 'speed-factor'
                        for k = 1:REs(i).numStages
                            for l = find(stageIndex(:,i)==k)'
                                for r = 1:K % for all classes served by this processors
                                    if ~isempty( envMu{l,procIdx,r} )
                                        envMu{l,procIdx,r} = envMu{l,procIdx,r}*REs(i).parameters{j,3}(k);
                                    end
                                end
                            end
                        end
                    case 'multiplicity'
                        for k = 1:REs(i).numStages
                            for l = find(stageIndex(:,i)==k)
                                S{l}(procIdx) = S{l}(procIdx)*REs(i).parameters{j,3}(k);
                            end
                        end
                    otherwise
                        warning(sprintf('Ignoring unrecognized parameter %s related to environment %s.',REs(i).parameters{j,2},REs(i).ID ));
                end
            else
                disp(sprintf('Processor % not a hardware processor', elemID));
            end
        end
    end


    myCQNCSRE = CQNRECox(M, K, E, N, ENV, envS, ...
                            envMu, envPhi, sched, envP, NK, myCQNCS.classMatch, refNodes, fullResetRules, nodeNames, classNames);
else
   error(['XML file ',filenameRE,' empty or not existent']);
   myCQNCSRE = [];
end

