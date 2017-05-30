function [Qavg, Uavg, Ravg, Xavg, resEntry, RT_CDF,resEntry_CDF,piemb] = CQN_RE_analysis(myCQN, entry, entryGraphs, processors, max_iter, delta_max, RT, RTrange, verbose)
% [Q, U, R, X] = CQN_RE_ANALYSIS(myCQN) computes the stationary performance
% measures of a Closed Multi-Class Queueing Network with Class Switching
% in a Random environment (CQNRE) myCQN. 
% More details on this type of queueing networks can be found 
% on the LINE documentation
% 
% Parameters: 
% myCQN:        a CQNRE model to analyze
% entry:         list of entries in the LQN model
% entryGraphs:   activity execution graphs for each entry
% processors:   list of LQN processors in the model 
% max_iter:     maximum number of iterations (termination condition)
% delta_max:    maximum difference between two succesive iterations (termination condition)
% RT:           1 if response time percentiles must be computed; 0 otherwise
% RTrange:      percentiles of the response time distribution to be  computed, if any
% verbose:      1 for screen output
% 
% Ouput:
% Qavg          mean queue-length for each station and job class 
% Uavg:         utilization for each server
% Ravg:         response time for each job class
% Xavg:         throughput for each job class
% resEntry:      results (mean response time) for the entries defined in the LQN model
% RT_CDF:       response time CDF for the main classes in the LQN
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

myCQNCox = CQNRE2CQNRECox(myCQN);
if verbose > 1
    disp(myCQNCox.toString());
end

classMatch = myCQN.classMatch;
y0 = [];
[Q, ymean_emb, piemb, ~, ~] = CQN_RE_fluid_ps(myCQNCox, max_iter, delta_max, y0, verbose);

%% RT CDF analysis 
if RT >= 1
    RT_CDF = CQN_RE_fluid_ps_RT(myCQNCox, max_iter, delta_max, ymean_emb, piemb, RTrange, verbose);
    if RT == 2
        if ~isempty(entryGraphs)
            RT_CDF_entry = CQN_RE_fluid_ps_RT_entry(myCQNCox, max_iter, delta_max, ymean_emb, piemb, entryGraphs, processors, RTrange, verbose);
        else
            disp('No entryGraphs definition has been found. Response time distributions at entry level will not be computed.');
        end
    else
        RT_CDF_entry = [];
    end
else
    RT_CDF = [];
    RT_CDF_entry = [];
end

%% prepare 
%de-condition mass in Q - needed for Perf Analysis
for e=1:myCQN.E
    if piemb(e) > 0
        Q(:,:,e) = Q(:,:,e)/piemb(e);
    end
end

%% assumes the existence of a delay node through which all classes pass
delayNodes = zeros(1,myCQN.M); 
for i = 1:myCQN.M
    if strcmp(myCQN.sched{i},'inf')
        delayNodes(i) = 1;
    end
end
delayRefNodes = zeros(1,myCQN.M); % delay nodes that are also reference nodes
for k = 1:myCQN.K
    if myCQN.refNodes(k) > 0 % artificial classes do not need to have a reference node
        delayRefNodes(myCQN.refNodes(k)) = 1;
    end
end


%% performance analysis (class switching)
origK = size(classMatch,1);
Qavg = zeros(myCQN.M,origK);
newXfullAvg = zeros(myCQN.M,origK);
XfullAvg = zeros(myCQN.M,myCQN.K);
Ravg = zeros(myCQN.M, origK);
RfullAvg = zeros(myCQN.M, myCQN.K);
Xavg = zeros(1,origK);

K = myCQN.K;
nonNullE = find(piemb>0);
for e = nonNullE
    %% computing tput - simpler version
    rates = myCQN.rates{e};
    S = myCQN.S{e};
    refNodes = myCQN.refNodes;
    S(delayNodes>0) = myCQN.N*ones(sum(delayNodes>0),1); 

    Qe = Q(:,:,e); 
    %tput for all classes in each station
    xi = sum(Qe,2); %number of jobs in each station
    minxi = min(xi,S); %minimum between number of jobs and servers in each station
    minxi(xi>0) = minxi(xi>0)./xi(xi>0); %ratio to determine effective rate
    Xfull = Qe.*rates.*(minxi*ones(1,K));

    %% response time
    R = zeros(myCQN.M, myCQN.K);
    for i = 1:myCQN.M
        R(i, Xfull(i,:)>0) = Q(i,Xfull(i,:)>0,e)./Xfull(i,Xfull(i,:)>0);
    end
    
    newR = zeros(myCQN.M,origK);
    X = zeros(1,origK);
    newXfull = zeros(myCQN.M,origK);
    newQ = zeros(myCQN.M,origK);
    % determine eventual probability of visiting each station in each class (expected number of visits)
    % weight response time of each original class with the expented number of
    % visits to each station in each associated artificial class
    idxNR = reshape(1:myCQN.M*myCQN.K, myCQN.K, myCQN.M); %indices of non-delay (non-reference) nodes
    idxNR = reshape(idxNR(:,delayRefNodes==0),1,[]); 
    Ptrans = myCQN.P{e}(idxNR,idxNR); %transient transition matrix for non-reference nodes
    if min(sum(Ptrans,2)) < 1 % check if Ptrans is a sub-generator, otherwise set eventualVisit to identity
        eventualVisit = inv( eye(size(Ptrans)) - Ptrans );
    else
        eventualVisit = eye(size(Ptrans)); 
    end
    idxOrigClasses = zeros(origK,1); 
    for k = 1:origK
        idxOrigClasses(k) = find(classMatch(k,:),1);
        refNode = refNodes(idxOrigClasses(k));

        eventualVisitProb = reshape( myCQN.P{e}((refNode-1)*myCQN.K+idxOrigClasses(k),idxNR)*eventualVisit, myCQN.K , myCQN.M-sum(delayRefNodes>0) )'; %probability of eventual visit 
        eventualVisitProb = eventualVisitProb(:,classMatch(k,:)==1); 
        newR(refNode,k) = sum( R(refNode,classMatch(k,:)==1),2 );
        newR(delayRefNodes==0,k) = sum( R(delayRefNodes==0,classMatch(k,:)==1).*eventualVisitProb,  2 );

        X(k) = sum( Xfull(refNode,classMatch(k,:)==1) );
        newXfull(:,k) = sum( Xfull(:,classMatch(k,:)==1),2 );
        newQ(:,k) = sum( Q(:,classMatch(k,:)==1,e),2 );
    end
    Rfull = R;
    R = newR;
    Qe = newQ;

    %accumulate towards averages
    newXfullAvg = newXfullAvg + newXfull*piemb(e);
    XfullAvg = XfullAvg + Xfull*piemb(e);
    RfullAvg = RfullAvg + Rfull*piemb(e);
    Ravg = Ravg + R*piemb(e);
    Xavg = Xavg + X*piemb(e);
    Qavg = Qavg + Qe*piemb(e);
end

%% Utilization 
UN = zeros(myCQN.M*myCQN.K,1);
ratesAvg = myCQN.rates{1}*piemb(1);
SAvg = myCQN.S{1}*piemb(1);
for e = 2:myCQN.E
    ratesAvg = ratesAvg + myCQN.rates{e}*piemb(e);
    SAvg = SAvg + myCQN.S{e}*piemb(e);
end

UN(ratesAvg>0) = XfullAvg(ratesAvg>0) ./ ratesAvg(ratesAvg>0);
UN = reshape(UN, myCQN.M, myCQN.K);
Uavg = sum(UN,2);
Uavg(delayNodes==0) = Uavg(delayNodes==0)./SAvg(delayNodes==0);

%% Compute response times for entry
if ~isempty(entry)
    [resEntry,resEntry_CDF] = CQN_respTime_entry(processors, entry, RfullAvg, RT_CDF_entry, Xfull, verbose );
else
    resEntry = [];
    resEntry_CDF = [];
    warning('No LQN definition has been found. Performance metrics at entry level will not be computed.');
end