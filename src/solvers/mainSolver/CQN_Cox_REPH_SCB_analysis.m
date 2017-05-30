function [Qavg, U, Ravg, Xavg, resEntry, RT_CDF,resEntry_CDF] = CQN_Cox_REPH_SCB_analysis(myCQN, entry, entryGraphs, processors, max_iter, delta_max, RT, RTrange, verbose)
% [Q, U, R, X] = CQN_COX_RE_ANALYSIS(myCQN) computes the stationary performance
% measures of a Closed Multi-Class Queueing Network with Class Switching
% in a Random environment with Coxian processing times (CQNRECox) myCQN. 
% More details on this type of queueing networks can be found 
% on the LINE documentation
% 
% Parameters: 
% myCQN:        a CQNREPH model to analyze
% entry:         list of entries in the LQN model
% entryGraphs:   activity execution graphs for each entry
% processors:   list of LQN processors in the model 
% reset:        1 if a reset occurs when switching environmental stage, 0 otherwise
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

if verbose > 1 
    disp(myCQN.toString());
end

classMatch = myCQN.classMatch;
y0 = [];
[Q, ymean_emb, piemb, ~, ~] = CQN_REPH_SCB_fluid_ps(myCQN, max_iter, delta_max, y0, verbose);

%% RT CDF analysis 
if RT >= 1
    RT_CDF = CQN_RE_SCB_fluid_ps_RT(myCQN, max_iter, delta_max, ymean_emb, piemb, RTrange, verbose);
    if RT == 2
        if ~isempty(entryGraphs)
            RT_CDF_entry = CQN_RE_fluid_ps_RT_entry(myCQN, max_iter, delta_max, ymean_emb, piemb, entryGraphs, processors, RTrange, verbose);
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

%% assumes the existence of a delay node through which all classes pass
origK = size(classMatch,1);
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

%% simpler version: no chain analysis 
M = myCQN.M;
K = myCQN.K;
E = myCQN.E;
refNodes = myCQN.refNodes;
Lambda = myCQN.mu;
Pi = myCQN.phi;
V = myCQN.V;
phases = zeros(E,M,K);
for e = 1:E
    for i = 1:M;
        for k = 1:K
            phases(e,i,k) = length(Lambda{e,i,k});
        end
    end
end
%% indicator matrices for blocking and non-blocking classes 
B = zeros(M,K); % 1 in entry (i,r) if class r jobs block station i, 0 otherwise
useB = zeros(M,K); % 1 in entry (i,r) if class r jobs blocks ANOTHER station when executing in station i, 0 otherwise
for i = 1:M
    for k = 1:K
        B(i,k) = sum( V(:,i,k) ) > 0; 
        useB(i,k) = sum( V(i,:,k) ) > 0; 
    end
end

precisionX = 1E-6; 
Qavg = zeros(myCQN.M,origK);
XfullAvg = zeros(myCQN.M,myCQN.K);
Ravg = zeros(myCQN.M, origK);
RfullAvg = zeros(myCQN.M, myCQN.K);
Xavg = zeros(1,origK);
Xservice = cell(E,M,K); %effective service rate per class, station and Phase - and stage
nonNullE = find(piemb>0);
for e = nonNullE
    %Qlength for all stations, classes, 
    Qfull = ymean_emb{end,e};%/piemb(e);
    Qe = Q(:,:,e)/piemb(e);

    %% Throughput
    %tput for all classes in each station
    Xfull = zeros(myCQN.M,myCQN.K); % throughput of every class at each station
    for i = 1:myCQN.M
        %if i == refNode
        if delayNodes(i) == 1
            for k = 1:myCQN.K
                idx = sum(sum(phases(e,1:i-1,:))) + sum( phases(e,i,1:k-1) ); 
                Xservice{e,i,k} = zeros(phases(e,i,k),1);
                for f = 1:phases(e,i,k)
                    Xfull(i,k) = Xfull(i,k) + Qfull(idx+f)*Lambda{e,i,k}(f);
                    Xservice{e,i,k}(f) = Qfull(idx+f)*Lambda{e,i,k}(f);
                end
                if Xfull(i,k) < precisionX
                    Xfull(i,k) = 0;
                    Xservice{e,i,k} = zeros(phases(e,i,k),1); 
                end
            end
        else
            %xi = sum(Qe(i,:)); %number of jobs in the station
            xi = sum(Qe(i,B(i,:)==0)); %number of non-blocking jobs in the station
            Si = max(0, myCQN.S{e}(i)-sum(Qe(i,B(i,:)==1)) ); % remove capacity stolen by blocking jobs 
            for k = 1:myCQN.K
                if B(i,k) == 0 % non-blocking jobs only
                    idx = sum(sum(phases(e,1:i-1,:))) + sum( phases(e,i,1:k-1) ); 
                    Xservice{e,i,k} = zeros(phases(e,i,k),1);
                    for f = 1:phases(e,i,k)
                        Xfull(i,k) = Xfull(i,k) + Qfull(idx+f)*Lambda{e,i,k}(f)*Pi{e,i,k}(f)/xi*min(xi, Si);
                        Xservice{e,i,k}(f) = Qfull(idx+f)*Lambda{e,i,k}(f)/xi*min(xi, Si);
                    end 
                    if Xfull(i,k) < precisionX
                        Xfull(i,k) = 0;
                        Xservice{e,i,k} = zeros(phases(e,i,k),1); 
                    end
                end
            end
        end
    end
    
    %% Response time
    R = zeros(myCQN.M, myCQN.K);
    for i = 1:myCQN.M
        R(i, Xfull(i,:)>0) = Qe(i,Xfull(i,:)>0)./Xfull(i,Xfull(i,:)>0);
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
    eventualVisit = inv( eye(size(Ptrans)) - Ptrans );
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
    
    %% Average among environmental stages
    %average according to piemb
    XfullAvg = XfullAvg + Xfull*piemb(e);
    Ravg = Ravg + R*piemb(e);
    RfullAvg = RfullAvg + Rfull*piemb(e);
    Xavg = Xavg + X*piemb(e);
    Qavg = Qavg + Qe; 
end

%% Utilization
UN = zeros(M,K);
Sf = myCQN.S;
for e = 1:E
    Sf{e}(delayNodes==1) = 1;
end
for i =1:M
    for k = 1:K
        for e = 1:E
            idx = Xservice{e,i,k}>0;
            UN(i,k) = UN(i,k) + sum(Xservice{e,i,k}(idx)./ (Lambda{e,i,k}(idx) ))*piemb(e)/Sf{e}(i);
        end
    end
end
U = sum(UN,2);

%% Compute response times for entry
if ~isempty(entry)
    [resEntry,resEntry_CDF] = CQN_respTime_entry(processors, entry, RfullAvg, RT_CDF_entry, Xfull, verbose);
else
    resEntry = [];
    resEntry_CDF = [];
    warning('No LQN definition has been found. Performance metrics at entry level will not be computed.');
end