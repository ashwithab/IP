function RT = CQN_fluid_ps_RT_entry(myCQN, max_iter, delta_max, y0, entryGraphs, processors, RTrange, verbose)
% CQN_FLUID_PS_RT(A) computes the response time distributions for all
% entries in the LQN model A
%
% Parameters: 
% myCQN:        CQNCox object describing the network
% max_iter:     maximum number of iterations
% delta_max:    max change in the mean vector accepted for termination
% y0:           stationary state of the QN obtained via a fluid analysis
%               this state is used as the initial for response time analysis
% entryGraphs:   activitity execution graph for each entry in the model
% processors:   list of all LQN processors
% RTrange:      percetiles of the response distribution requested (optional)
% verbose:      1 for screen output (optional) 
%
% Output:
% RT:           cell array containing the overall response time
%               distribution for each original class in the QN
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin < 5
    disp('Error in script CQN_fluid_ps_RT.');
    disp('Not enough parameters to compute response time distribution.');
    RT = [];
    return;
end
if nargin < 6 
    RTrange = [];
end
if nargin < 7
    verbose = 0;
end


M = myCQN.M;    %number of stations
K = myCQN.K;    %number of classes
N = myCQN.N;    %population
Lambda = myCQN.mu;
Pi = myCQN.phi;
P = myCQN.P;
S = myCQN.S;
for i = 1:M
    %Set number of servers in delay station = population
    if S(i) == -1;
        S(i) = N;
    end
end

%% initialization
if nargin < 2 || isempty(max_iter) max_iter = 100; end
if nargin < 3 || isempty(delta_max) delta_max = 1e-3; end

phases = zeros(M,K);
for i = 1:M;
    for k = 1:K
        phases(i,k) = length(Lambda{i,k});
    end
end
slowrate = zeros(M,K);
for i = 1:M;
    for k = 1:K
        slowrate(i,k) = Inf;
        slowrate(i,k) = min(slowrate(i,k),min(Lambda{i,k}(:))); %service completion (exit) rates in each phase
    end
end



%% response time analysis - starting from fixed point found - for each entry 
usestiff = 1;
np = length(entryGraphs);
RT = cell(np,2);
for k = 1:np % once for processor
    % if this processor corresponds to an entry
    if ~isempty(entryGraphs(k).initEntries) && ~strcmp(processors(k).tasks.scheduling, 'ref')
        % once for each sample
        for s = 1%size(entryGraphs(k).initEntries,1) - using only one sample - all are identical
            % create new P, add artificial classes 
            newP = P;
            newK = K;
            newLambda = Lambda;
            newPi = Pi;
            newPhases = phases;
            
            currProcs = entryGraphs(k).initEntries(s,1);
            currClasses = entryGraphs(k).initEntries(s,2);
            currArtClasses = currClasses; % initially the artificial class is the original class
            ready = 0; 
            while ~ready
                nextProcs = [];
                nextClasses = [];
                nextArtClasses = [];
                for j = 1:length(currProcs)
                    idx = (currProcs(j)-1)*K + currClasses(j);
                    nextEntries = find(entryGraphs(k).graph(idx,:)>0); 
                    % if this is the last entry, connect it back with the
                    % appropriate original class
                    if isempty(nextEntries)
                        for i = 1:M
                            % copy routing probs for each target processor
                            newP( (currProcs(j)-1)*newK+currArtClasses(j), (i-1)*newK+1:(i-1)*newK+K) = ...
                                P( (currProcs(j)-1)*K+currClasses(j), (i-1)*K+1:i*K);
                        end
                    end
                    for i = nextEntries
                        nextProc = ceil(i/K); 
                        nextClass = i - (nextProc-1)*K; %mod(i,K); 
                        
                        
                        % create artificial class for response time analysis
                        newK = newK + 1;
                        % enlarge routing matrix P and add link from current class to next
                        newP = reshape(newP,M*(newK-1)*(newK-1), M);
                        newP = [newP; zeros(M*(newK-1),M)];
                        newP = reshape(newP,M*(newK-1),M*newK);
                        
                        newP = reshape(newP,newK-1,M*M*newK);
                        newP = [newP; zeros(1, M*M*newK)];
                        newP = reshape(newP,M*newK,M*newK);
                        
                        newP( (currProcs(j)-1)*newK+currArtClasses(j), (nextProc-1)*newK+newK ) = entryGraphs(k).graph(idx,i); 
                        % enlarge Lambda and Pi and Phases
                        newLambda = [newLambda newLambda(:,nextClass)];
                        newPi = [newPi newPi(:,nextClass)];
                        newPhases = [newPhases newPhases(:,nextClass)];
                        
                        
                        
                        nextProcs = [nextProcs; nextProc];
                        nextClasses = [nextClasses; nextClass];
                        nextArtClasses = [nextArtClasses; newK]; % next art class is the one just created  
                    end
                    
                end
                if isempty(nextProcs)
                    ready = 1;
                else
                    currProcs = nextProcs; 
                    currClasses = nextClasses; 
                    currArtClasses = nextArtClasses; 
                end
            end
           
            % remove initial link from original class to first artificial class
            entryProc = entryGraphs(k).initEntries(s,1);
            entryClass = entryGraphs(k).initEntries(s,2); 
            idx = (entryProc-1)*K + entryClass;
            nextEntries = find(entryGraphs(k).graph(idx,:)>0); 
            newFluid = 0; 
            addY = zeros(1, sum(sum(newPhases)) );
            for i = 1:length(nextEntries)
                % initial (proc, class pairs) 
                initProc = ceil(nextEntries(i)/K); 
                initClass = nextEntries(i) - (initProc-1)*K; %mod(i,K); 
                
                % remove link from original class to artificial class
                newP((entryProc-1)*newK+entryClass, (initProc-1)*newK+K+i) = 0; %zeros(1,M); % zero columns to class K+1
                
                % determine fluid to move from original classes to artificial ones
                idxKpi = sum(sum(newPhases(1:initProc-1,:))) + sum(newPhases(initProc,1:K+i-1)); % base index of class K+i, stat initProc
                idxInitClass = sum(sum(newPhases(1:initProc-1,:))) + sum(newPhases(initProc,1:initClass-1)); % base index of class initClass, initProc
                idxInitClassK = sum(sum(phases(1:initProc-1,:))) + sum(phases(initProc,1:initClass-1)); % as above, but for the original number of phases
                fullFluid = y0(idxInitClassK+1:idxInitClassK + phases(initProc,initClass));
                newFluid = newFluid + sum(fullFluid); 
                addY( idxKpi + 1 ) = newFluid; %add fluid to class K+i, first phase
                addY( idxInitClass+1:idxInitClass+newPhases(initProc,initClass) ) = -fullFluid; % remove fluid from class k, all phases
                
            end
            
            % create new initial vector - moving fluid according to addY
            newY0 = zeros(1, sum(sum(newPhases(:,:))));
            for i = 1:M
                for l = 1:K
                    idx = sum(sum(newPhases(1:i-1,:))) + sum(newPhases(i,1:l-1));
                    idxOld = sum(sum(phases(1:i-1,:))) + sum(phases(i,1:l-1));
                    newY0( idx + 1: idx + newPhases(i,l)  ) = y0(idxOld+1:idxOld + phases(i,l));
                end
            end
            newY0 = newY0 + addY;

            %setup the ODEs for the new QN
            [newOde_h, ~] = CQN_fluid_analysis_ps(N, reshape({newLambda{:,:}},M,newK), reshape({newPi{:,:}},M,newK), newP, S);

            iters = 0;
            iters = iters + 1;
            RTtemp = cell (1,2);
            nonZeroRates = slowrate(:);
            nonZeroRates = nonZeroRates( nonZeroRates >0 );
            T = abs(100/min(nonZeroRates)); % solve ode until T = 100 events with slowest exit rate

            %indices new classes in all stations but delay
            idxN = []; 
            for i = 1:M
                    idxN = [idxN sum(sum(newPhases(1:i-1,: ) )) + sum(newPhases(i,1:K)) + [1:sum(newPhases(i,K+1:newK))] ]; %works for 
            end

            fullt = [];
            fully = [];
            iter = 1;
            finished = 0;
            tref = 0;
            while iter <= max_iter && finished == 0
                % solve ode - yt_e is the transient solution in stage e
                if usestiff == 2
                    opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3);
                    [t, yt_e] = ode23s(newOde_h, [0 T], newY0, opt);
                elseif usestiff == 1
                    opt = odeset('AbsTol', 1e-10, 'RelTol', 1e-7, 'NonNegative', 1:length(newY0),'Events',@events);
                    [t, yt_e] = ode15s(newOde_h, [0 T], newY0, opt);
                else
                    opt = odeset('AbsTol', 1e-8, 'RelTol', 1e-5, 'NonNegative', 1:length(newY0));
                    [t, yt_e] = ode15s(newOde_h, [0 T], newY0, opt);
                end
                iter = iter + 1;
                fullt = [fullt; t+tref];
                fully = [fully; yt_e];
                if sum(yt_e(end,idxN )) < 10e-10
                    finished = 1;
                end
                tref = tref + t(end);
                newY0 = yt_e(end,:);
            end
            % retrieve response time CDF for class k
            RT{k,1} = fullt;
            RT{k,2} = 1 - sum(fully(:,idxN ),2)/newFluid;
            if iter > max_iter
                disp('Maximum number of iterations reached when computing the response time distribution.\n Response time distributions may be affected numerically');
            end
            if verbose > 0
                a = ( RT{k,2}(1:end-1) + RT{k,2}(2:end) )/2;
                meanRT = sum(diff(RT{k,1}).*(1-a));
                disp(['Mean response time class ', processors(k).name,': ', num2str(meanRT)]);
            end
            % determine the value of the  percentiles requested (RTrange)
            if ~isempty(RTrange) && RTrange(1) >=0 && RTrange(end) <=1
                percRT = interp1q(RT{k,2}, RT{k,1}, RTrange); 
                RT{k,1} = percRT;
                RT{k,2} = RTrange;
            end
        
        end
    end
end

return


function [value,isterminal,direction] = events(t,y)
    value = sum(y(idxN));
    isterminal = 1;
    direction = 0;
end


end


