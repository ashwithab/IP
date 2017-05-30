function RT = CQN_SRP_fluid_ps_RT(myCQN, max_iter, delta_max, y0, RTrange, verbose)
% CQN_FLUID_PS_RT(A) computes the overall response time distribution
% of the original classes in the closed multi-class queueing network A
%
% Parameters: 
% myCQN:        CQNCox object describing the network
% max_iter:     maximum number of iterations
% delta_max:    max change in the mean vector accepted for termination
% y0:           stationary state of the QN obtained via a fluid analysis
%               this state is used as the initial for response time analysis
% RTrange:      percetiles of the response distribution requested (optional)
% verbose:      1 for screen output (optional) 
%
% Output:
% RT:           cell array containing the overall response time
%               distribution for each original class in the QN
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin < 4
    disp('Error in script CQN_SRP_fluid_ps_RT.');
    disp('Not enough parameters to compute response time distribution.');
    RT = [];
    return;
end
if nargin < 5 
    RTrange = [];
end
if nargin < 6
    verbose = 0;
end


M = myCQN.M;    %number of stations
Mp = myCQN.Mp;    %number of stations
K = myCQN.K;    %number of classes
N = myCQN.N;    %population
Lambda = myCQN.mu;
Pi = myCQN.phi;
P = myCQN.P;
S = myCQN.S;
Sp = myCQN.Sp;
W = myCQN.W;


delayNode = -1;
for i = 1:M
    %Set number of servers in delay station = population
    if S(i) == -1;
        S(i) = N;
        delayNode = i;
    end
end

%% initialization
if nargin < 2 || isempty(max_iter) max_iter = 100; end
if nargin < 3 || isempty(delta_max) delta_max = 1e-3; end

phases = zeros(M,K);
for i = 1:M;
    for k = 1:K
        %phases(i,k,e) = length(Lambda{e,i,k});
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



%% response time analysis - starting from fixed point found 
usestiff = 1;
classMatch = myCQN.classMatch; 
origK = size(classMatch,1);
initClasses = zeros(origK,1);
for k = 1:origK
    initClasses(k) = find( classMatch(k,:)==1,1 ); %first class of original class k 
end
RT = cell(origK,2);
for k = 1:origK %once for each class
    %mark reference node for class k as delayNode 
    delayNode = myCQN.refNodes(initClasses(k));
    newK = K + sum(classMatch(k,:),2);
    numNewK = newK - K;
    idxCl = find(classMatch(k,:)==1);
    idxArtCl = zeros(1,K); % indices of the artificial class corresponding to each class in the original model for class k 
    idxArtCl(classMatch(k,:)==1) =  K+1:newK;
    newLambda = cell(M,newK);
    newPi = cell(M,newK);
    newP = zeros(M*newK, M*newK);
    newW = zeros(M, Mp, newK); 
    % service rates
    newLambda(:,1:K) = Lambda(:,:);
    for l = 1:numNewK
        newLambda(:,K+l) = Lambda(:,idxCl(l));
    end
    % completion probabilities
    newPi(:,1:K) = Pi(:,:);
    for l = 1:numNewK
        newPi(:,K+l) = Pi(:,idxCl(l));
    end
    % routing/switching probabilities
    % among basic classes
    for l = 1:K
        for m = 1:K
            newP(l:newK:end,m:newK:end) = P(l:K:end,m:K:end);
        end
    end
    % copy probabilities from the basic to the extra classes (forward)
    finalClasses = zeros(K,1);
    for l = 1:numNewK
        for m = 1:numNewK
            if sum(sum(P(idxCl(l):K:end,idxCl(m):K:end))) > 0 
                newP(K+l:newK:end,K+m:newK:end) = P(idxCl(l):K:end,idxCl(m):K:end);
                if sum(P(idxCl(l):K:end,(delayNode-1)*K+idxCl(m))) > 0 
                    finalClasses(idxCl(l)) = 1;
                end
            end
        end
                
    end
    finalClasses = find(finalClasses==1);
    
    routP = P(initClasses(k):K:end, initClasses(k):K:end); %routing matrix for class k
    outputStat = find(routP(delayNode,:)>0); % stats when leaving delay Node
    
    outputIdx = find( P((delayNode-1)*K+initClasses(k),:) > 0 ); 
    outputStat = ceil(outputIdx/K); 
    outputClass = mod(outputIdx-1,K)+1;
        
    
    %determine final classes (leaves in the class graph)
    for l = finalClasses' % for each final class
        %routing matrix from the last artificial class to the first one corresponding to class k
        routP1 = P(l:K:end,initClasses(k):K:end);      %old : l=end
                                        

        inputStat = find(routP1(:,delayNode)>0)'; % stats to enter delay Node
        if ~isempty(inputStat) % ignore cases where the delay node is actually unreachable from the finalClass considered
            for i = inputStat
                % return fluid to original class - added classes are trasient
                % prob from stat i, class l to stat delay, class init(k) = prob
                % from stat i, class l to stat delay, all classes
                newP((i-1)*newK+idxArtCl(l), (delayNode-1)*newK+initClasses(k)) = sum(P((i-1)*K+l, (delayNode-1)*K+1:delayNode*K  ));  

                % delete connection from artifial class l, station i, to artificial class 1, delay node
                newP((i-1)*newK+idxArtCl(l), (delayNode-1)*newK+K+1) = 0;
            end
        end
    end
    
    % new W
    for i = 1:M
        for j = 1:Mp
            for c = 1:K
                newW(i,j,c) = W(i,j,c); 
            end
            for c = K+1:newK
                newW(i,j,c) = W(i,j,k); 
            end
        end
    end
    
    
    %setup the ODEs for the new QN
    [newOde_h, ~] = CQN_SRP_fluid_analysis_ps(N, reshape({newLambda{:,:}},M,newK), reshape({newPi{:,:}},M,newK), newP, S, Sp, newW);
    
    %new phases
    newPhases = zeros(M,newK);
    newPhases(:,1:K) = phases;
    for l = 1:numNewK
        newPhases(:,K+l) = phases(:,idxCl(l));
    end
    
    newYmean_emb = cell(1,1);
    %determine amount of fluid for the new class
    newFluid = zeros(1,length(outputStat));  %take all fluid from output stations
    fullFluid = cell(1,length(outputStat)); %fluid in each phase
    for i = 1:length(outputStat)
        %cox case
        %idx = sum(sum(phases(1:outputStat(i)-1,:))) + sum(phases(outputStat(i),1:initClasses(k)-1));
        idx = sum(sum(phases(1:outputStat(i)-1,:))) + sum(phases(outputStat(i),1:outputClass(i)-1));
        %newFluid(i) = sum( y0(idx+1:idx + phases(outputStat(i),initClasses(k))) );
        newFluid(i) = sum( y0(idx+1:idx + phases(outputStat(i),outputClass(i))) );
        %fullFluid{i} = y0(idx+1:idx + phases(outputStat(i),initClasses(k)));
        fullFluid{i} = y0(idx+1:idx + phases(outputStat(i),outputClass(i)));
    end
    
    %move fluid from original class to the new one
    addY = zeros(1, sum(sum(newPhases(:,:))) );
    for i = 1:length(outputStat)
        %idxKp1 = sum(sum(newPhases(1:outputStat(i)-1,:))) + sum(newPhases(i,1:K)); % base index of class K+1, stat i
        %idxKp1 = sum(sum(newPhases(1:outputStat(i)-1,:))) + sum(newPhases(i,1:idxArtCl(outputClass(i))-1 )); % base index of artifial class outputStat(i), stat i
        idxKp1 = sum(sum(newPhases(1:outputStat(i)-1,:))) + sum(newPhases(outputStat(i),1:idxArtCl(outputClass(i))-1 )); % base index of artifial class outputStat(i), stat i
        %idxk = sum(sum(newPhases(1:outputStat(i)-1,:))) + sum(newPhases(i,1:initClasses(k)-1)); % base index of class k, stat i
        %idxk = sum(sum(newPhases(1:outputStat(i)-1,:))) + sum(newPhases(i,1:outputClass(i)-1)); % base index of original class outputClass(i), stat outputStat(i)
        idxk = sum(sum(newPhases(1:outputStat(i)-1,:))) + sum(newPhases(outputStat(i),1:outputClass(i)-1)); % base index of original class outputClass(i), stat outputStat(i)
        %cox case
        addY( idxKp1 + 1 ) = newFluid(i); %add fluid to artifial class outputStat(i), first phase
        %addY( idxk+1:idxk+newPhases(i,k) ) = -fullFluid{i}; % remove fluid from class k, all classes
        %addY( idxk+1:idxk+newPhases(i,initClasses(k)) ) = -fullFluid{i}; % remove fluid from class k, all phases
        %addY( idxk+1:idxk+newPhases(i,outputClass(i)) ) = -fullFluid{i}; % remove fluid from class outputClass(i), all phases
        addY( idxk+1:idxk+newPhases(outputStat(i),outputClass(i)) ) = -fullFluid{i}; % remove fluid from class outputClass(i), all phases
    end
    newFluid = sum(newFluid);
    
    newY0 = zeros(1, sum(sum(newPhases(:,:))));
    for i = 1:M
        for l = 1:K
            idx = sum(sum(newPhases(1:i-1,:))) + sum(newPhases(i,1:l-1));
            idxOld = sum(sum(phases(1:i-1,:))) + sum(phases(i,1:l-1));
            newY0( idx + 1: idx + newPhases(i,l)  ) = y0(idxOld+1:idxOld + phases(i,l));
        end
    end
    newY0 = newY0 + addY;
    % add passive resource state
    newY0 = [newY0 y0(sum(sum(phases(:,:)))+1:end)]; 
    
    iters = 0;
    iters = iters + 1;
    RTtemp = cell (1,2);
    nonZeroRates = slowrate(:);
    nonZeroRates = nonZeroRates( nonZeroRates >0 );
    T = abs(100/min(nonZeroRates)); % solve ode until T = 100 events with slowest exit rate

    %indices new classes in all stations but delay
    idxN = []; 
    for i = 1:M
        if i ~= delayNode
            idxN = [idxN sum(sum(newPhases(1:i-1,: ) )) + sum(newPhases(i,1:K)) + [1:sum(newPhases(i,K+1:newK))] ]; %works for 
        end
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
    if newFluid > 0;
        RT{k,2} = 1 - sum(fully(:,idxN ),2)/newFluid;
    else
        RT{k,2} = ones(size(fullt));
    end
    if iter > max_iter
        disp('Maximum number of iterations reached when computing the response time distribution.\n Response time distributions may be affected numerically');
    end
    if verbose > 1
        a = ( RT{k,2}(1:end-1) + RT{k,2}(2:end) )/2;
        meanRT = sum(diff(RT{k,1}).*(1-a));
        disp(['Mean response time class ', int2str(k),': ', num2str(meanRT)]);
    end
    % determine the value of the  percentiles requested (RTrange)
    if ~isempty(RTrange) && RTrange(1) >=0 && RTrange(end) <=1
        if newFluid > 0 
            percRT = interp1q(RT{k,2}, RT{k,1}, RTrange); 
        else
            percRT = zeros(size(RTrange));
        end
        RT{k,1} = percRT;
        RT{k,2} = RTrange;
    end
end

return


function [value,isterminal,direction] = events(t,y)
    value = sum(y(idxN));
    isterminal = 1;
    direction = 0;
end


end


