function [Q, U, R, X,resEntry,RT_CDF,resEntry_CDF] = CQN_analysis(myCQN, entry, entryGraphs, processors, max_iter, delta_max, RT, RTrange, solver, verbose)
% [Q, U, R, X] = CQN_ANALYSIS(myCQN) computes the stationary performance
% measures of a Closed Multi-Class Queueing Network with Class Switching
% (CQN) myCQN. 
% More details on this type of queueing networks can be found 
% on the LINE documentation
% 
% Parameters: 
% myCQN:        a CQN model to analyze
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
% Q:            mean queue-length for each station and job class 
% U:            utilization for each server
% R:            response time for each job class
% X:            throughput for each job class
% resEntry:      results (mean response time) for the entries defined in the LQN model
% RT_CDF:       response time CDF for the main classes in the LQN
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin < 9
    solver = 1; % default FLUID solver
end
if nargin < 10
    verbose = 0; % default no screen output 
end

switch solver 
        
    case 1 % FLUID
        myCQNCSCox = CQN2CQNCox(myCQN);
        if verbose > 1 
            disp(myCQNCSCox.toString());
        end

        y0 = [];
        [Q, ymean_emb, ~, ~] = CQN_fluid_ps(myCQNCSCox, max_iter, delta_max, y0, verbose);
        if RT >= 1
            RT_CDF = CQN_fluid_ps_RT(myCQNCSCox, max_iter, delta_max, ymean_emb{end}, RTrange, verbose);
            if RT == 2
                if ~isempty(entryGraphs)
                    RT_CDF_entry = CQN_fluid_ps_RT_entry(myCQNCSCox, max_iter, delta_max, ymean_emb{end}, entryGraphs, processors, RTrange, verbose);
                else
                    warning('No entryGraphs definition has been found. Response time distributions at entry level will not be computed.');
                end
            else
                RT_CDF_entry = [];
            end
        else
            RT_CDF = [];
            RT_CDF_entry = [];
        end

    case 2 % QD-AMVA
        y0 = [];
        Q = CQN_amvaqd(myCQN, delta_max, y0, verbose);
        RT_CDF = [];
        RT_CDF_entry = [];

    case 3 % JMT
        y0 = [];
        Q = CQN_jmt(myCQN, [], [], verbose);
        RT_CDF = [];
        RT_CDF_entry = [];
end
classMatch = myCQN.classMatch;
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

%% computing tput - simpler version: no chain analysis - effective throughput Tput
K = myCQN.K;
rates = myCQN.rates;
refNodes = myCQN.refNodes;
S = myCQN.S;
S(delayNodes>0) = myCQN.N*ones(sum(delayNodes>0),1); 


%tput for all classes in each station
xi = sum(Q,2); %number of jobs in each station
minxi = min(xi,S); %minimum between number of jobs and servers in each station

minxi(xi>0) = minxi(xi>0)./xi(xi>0); %ratio to determine effective rate
Xfull = Q.*rates.*(minxi*ones(1,K));

%% response times + utilizations
origK = size(classMatch,1);
R = zeros(myCQN.M, myCQN.K);
for i = 1:myCQN.M
    R(i, Xfull(i,:)>0) = Q(i,Xfull(i,:)>0)./Xfull(i,Xfull(i,:)>0);
end

newR = zeros(myCQN.M,origK);
X = zeros(1,origK);
newQ = zeros(myCQN.M,origK);
% determine eventual probability of visiting each station in each class (expected number of visits)
% weight response time of each original class with the expented number of
% visits to each station in each associated artificial class
idxNR = reshape(1:myCQN.M*myCQN.K, myCQN.K, myCQN.M); %indices of non-delay (non-reference) nodes
idxNR = reshape(idxNR(:,delayRefNodes==0),1,[]); 
Ptrans = myCQN.P(idxNR,idxNR); %transient transition matrix for non-reference nodes
eventualVisit = inv( eye(size(Ptrans)) - Ptrans );
idxOrigClasses = zeros(origK,1); 
for k = 1:origK
    idxOrigClasses(k) = find(classMatch(k,:),1);
    refNode = refNodes(idxOrigClasses(k));
    
    eventualVisitProb = reshape( myCQN.P((refNode-1)*myCQN.K+idxOrigClasses(k),idxNR)*eventualVisit, myCQN.K , myCQN.M-sum(delayRefNodes>0) )'; %probability of eventual visit 
    eventualVisitProb = eventualVisitProb(:,classMatch(k,:)==1); 
    
    newR(refNode,k) = sum( R(refNode,classMatch(k,:)==1),2 );
    newR(delayRefNodes==0,k) = sum( R(delayRefNodes==0,classMatch(k,:)==1).*eventualVisitProb,  2 );
    
    X(k) = sum( Xfull(refNode,classMatch(k,:)==1) );
    newQ(:,k) = sum( Q(:,classMatch(k,:)==1),2 );
end
Rfull = R;
R = newR;
Q = newQ;

UN = zeros(myCQN.M*myCQN.K,1);
UN(myCQN.rates>0) = Xfull(myCQN.rates>0) ./ myCQN.rates(myCQN.rates>0);
UN = reshape(UN, myCQN.M, myCQN.K);

U = sum(UN,2);
U(delayNodes==0) = U(delayNodes==0)./myCQN.S(delayNodes==0);

%% Compute response times for entry
if ~isempty(entry)
    [resEntry,resEntry_CDF] = CQN_respTime_entry(processors, entry, Rfull, RT_CDF_entry, Xfull, verbose);
else
    resEntry = [];
    resEntry_CDF = []; 
    warning('No LQN definition has been found. Performance metrics at entry level will not be computed.');
end