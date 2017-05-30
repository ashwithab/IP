function [myCQNCSRE] = extendCQNCOX_REPH(myCQNCS, REs, COXs, COX_IDs, verbose)
% Q = EXTEND_CQNCOX_REPH(A) extends a CQN model with Coxian processing times A 
% to include the random environments with Phase-type holding times (REPH). 
% The extended model Q is returned as a CQNREPHCox object.
%
% Parameters:
% myCQNCS:      CQN model to be extended
% REs:          list of RE elements to include
% COXs:         list of COX elements included
% COX_IDs:      list of  IDs for the COX elements included
% verbose:      1 for screen output
% 
% Output:
% myCQNRE:  extended QN model 
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
    
    % build the representation of the RE using the COX distributions provided
    RE_ENV = cell(nE,1); 
    for i = 1:nE
        thisRE = REs(i); 
        thisENV = cell(thisRE.numStages,3); 
        for j = 1:thisRE.numStages
            if isfloat(thisRE.sojTimes{j})
                thisENV{j,1} = 1;
                thisENV{j,2} = -1/thisRE.sojTimes{j};
                thisENV{j,3} = thisRE.transProbs(j,:);
            elseif ischar(thisRE.sojTimes{j})
                coxIdx = getIndexCellString(COX_IDs, thisRE.sojTimes{j});
                if coxIdx > 0
                    m = COXs(coxIdx).numPhases; 
                    thisENV{j,1} = [1 zeros(1,m-1)]; 
                    thisENV{j,2} = -diag(COXs(coxIdx).rates) + diag(COXs(coxIdx).rates(1:m-1).*(ones(m-1,1)-COXs(coxIdx).completionProbs(1:m-1)),1);
                    thisENV{j,3} = thisRE.transProbs(j,:);
                else
                    ME = MException('LINE:CoxDistNotFound', ...
                           'Cox distribution with ID %s not found', inputstr);
                    throw(ME);
                end
            end
        end
        RE_ENV{i} = thisENV;
    end

    % build a code to interpret resetRules numerically - easier composition
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

    % RE composition
    if nE == 1
        stageIndex = [1:E]';
        ENV = RE_ENV{1}; 
        fullResetRules = REs(1).resetRules;
    else
        stageIndex = zeros(E,nE); % stage of each RE in the full RE
        stageIndex(:,1) = kron( [1:numStages(1)]', ones(prod(numStages(2:end)),1) );
        fullNumResetRules = kron( numRules{1},  eye(prod(numStages(2:end)))  );
        for i = 2:nE-1
            stageIndex(:,i) = kron( ones(prod(numStages(1:i-1)),1), ...
                kron( [1:numStages(i)]', ones(prod(numStages(i+1:end)),1) ) );
            fullNumResetRules = fullNumResetRules + kron( eye(prod(numStages(1:i-1))), ...
                kron( numRules{i},  eye(prod(numStages(i+1:end))) ) );
        end
        stageIndex(:,nE) = kron( ones(prod(numStages(1:nE-1)),1) , [1:numStages(nE)]');
        fullNumResetRules = fullNumResetRules + kron( eye(prod(numStages(1:nE-1))), numRules{nE} );
        
        
        fullResetRules = cell(E,E); % read back the reset rules
        for i = 1:E
            for j = [1:i-1 i+1:E]
                if fullNumResetRules(i,j) > 0
                    fullResetRules{i,j} = allRules{ fullNumResetRules(i,j) };
                end
            end
        end
        
        % compose holding times in each stage
        ENV = cell(E,3);
        for i = 1:E
            alpha = kron( RE_ENV{1}{stageIndex(i,1),1}, RE_ENV{2}{stageIndex(i,2),1} ); 
            T = kron(          RE_ENV{1}{stageIndex(i,1),2}, eye(size(RE_ENV{2}{stageIndex(i,2),2},1)) ) + ... 
                kron( eye(size(RE_ENV{1}{stageIndex(i,1),2},1)),      RE_ENV{2}{stageIndex(i,2),2} );
            absProbs = -alpha/T;
            absProbs = absProbs*[ kron( -sum(RE_ENV{1}{stageIndex(i,1),2},2), ones(size(RE_ENV{2}{stageIndex(i,2),2},1),1) ) ...
                                  kron( ones(size(RE_ENV{1}{stageIndex(i,1),2},1),1), -sum(RE_ENV{2}{stageIndex(i,2),2},2) )]; 
            e1 = eye(size(RE_ENV{1},1));
            e1 = e1(stageIndex(i,1),:);
            e2 = eye(size(RE_ENV{2},1));
            e2 = e2(stageIndex(i,2),:);
            p = absProbs(1)*kron( RE_ENV{1}{stageIndex(i,1),3}, e2) + ...
                absProbs(2)*kron( e1, RE_ENV{2}{stageIndex(i,2),3}); 
            enext = kron(e1,e2); % stage selection considering the first 2 REs 
            for j = 3:nE
                alphaOld = alpha;
                TOld = T;
                alpha = kron( alpha, RE_ENV{j}{stageIndex(i,j),1} ); 
                T = kron( T, eye(size(RE_ENV{j}{stageIndex(i,j),2},1)) ) + kron( eye(size(T,1)), RE_ENV{j}{stageIndex(i,j),2} ); 
                absProbs = -alpha/T;
                absProbs = absProbs*[ kron( -sum(TOld,2), ones(size(RE_ENV{j}{stageIndex(i,j),2},1),1) ) ...
                                  kron( ones(size(TOld,1),1), -sum(RE_ENV{j}{stageIndex(i,j),2},2) )]; 
                
                
                e1 = enext; 
                e2 = eye(size(RE_ENV{j},1));
                e2 = e2(stageIndex(i,j),:);
                p = absProbs(1)*kron( p, e2) + ...
                    absProbs(2)*kron( e1, RE_ENV{j}{stageIndex(i,j),3}); 
                enext = kron(e1,e2); % stage selection considering the first 2 REs 
            end
            ENV{i,1} = alpha;
            ENV{i,2} = T;
            ENV{i,3} = p;
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


    myCQNCSRE = CQNREPHCox(M, K, E, N, ENV, envS, envMu, envPhi, ...
                            sched, envP, NK, myCQNCS.classMatch, refNodes, fullResetRules, nodeNames, classNames); 
else
   error(['XML file ',filenameRE,' empty or not existent']);
   myCQNCSRE = [];
end

