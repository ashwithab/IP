classdef CQNCoxSCB
% CQNCOXSCB defines an object that represents a Closed Multi-Class Queueing
% Network with Class Switching,  Coxian service times, and synchronous calls with 
% resource blocking. 
% More details on this type of queueing networks can be found 
% on the LINE documentation, available at http://line-solver.sf.net
%
% Properties:
% M:            number of stations (int)
% K:            number of classes (int)
% N:            total population (int)
% S:            number of servers per station (Mx1 int)
% mu:           service rate in each service phase, for each job class in each station  
%               (MxK cell with n_{i,k}x1 double entries)
% phi:          probability of service completion in each service phase, 
%               for each job class in each station  
%               (MxK cell with n_{i,k}x1 double entries)
% sched:        scheduling policy in each station 
%               (Kx1 cell with string entries)
% P:            transition matrix with class switching
%               (MKxMK matrix with double entries), indexed first by station, then by class
% NK:           initial distribution of jobs in classes (Kx1 int)
% C:            number of chains (int)
% classMatch:   1-0 CxK matrix where 1 in entry (i,j) indicates that class 
%               j belongs to chain i. Column sum must be 1. (CxK int)
% refNodes:     index of the reference node for each request class (Kx1 int)
% nodeNames:    name of each node
%               (Mx1 cell with string entries) - optional
% classNames:   name of each job class
%               (Kx1 cell with string entries) - optional
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
   M;           % number of stations (int)
   K;           % number of classes (int)
   N;           % total population (int), sum(NK) = N - optional
   S;           % number of servers per station (Mx1 int)
   V;           % resources blocked (dim 2) when executing 
                % jobs of each class (dim 3) in station (dim 1)
                % (MxMxK int)
   mu;          % service rate in each service phase, for each job class in each station  
                % (MxK cell with n_{i,k}x1 double entries)
   phi;         % probability of service completion in each service phase, 
                % for each job class in each station  
                % (MxK cell with n_{i,k}x1 double entries)
   sched;       % scheduling policy in each station 
                % (Kx1 cell with string entries)
   P;           % transition matrix with class switching
                % (MKxMK matrix with double entries), indexed first by
                % station, then by class
   NK;          % initial distribution of jobs in classes (Kx1 int)
   C;           % number of chains (int)
   classMatch;  % 1-0 CxK matrix where 1 in entry (i,j) indicates that class  
                % j belongs to chain i. Column sum must be 1. (CxK int)
   refNodes;    % index of the reference node for each request class (Kx1 int)
   nodeNames;   % name of each node
                % (Mx1 cell with string entries) - optional
   classNames;  % name of each job class
                % (Kx1 cell with string entries) - optional
end


methods

%constructor
function obj = CQNCoxSCB(M, K, N, S, V, mu, phi, sched, P, NK, classMatch, refNodes, nodeNames, classNames)
    if(nargin > 0)
        obj.M = M;
        obj.K = K;
        obj.N = N;
        obj.S = S;
        obj.V = V;
        obj.mu = mu;
        obj.phi = phi;
        obj.sched = sched;
        obj.P = P;
        obj.NK = NK;
        obj.classMatch = classMatch;
        obj.C = size(classMatch,1); 
        obj.refNodes = refNodes; 
    end
    if nargin > 12
        obj.nodeNames = nodeNames;
    else
        obj.nodeNames = cell(obj.M,1);
        for j = 1:obj.M 
            obj.nodeNames{j,1} = int2str(j);
        end
    end
    if nargin > 13
        obj.classNames = classNames;
    else
        obj.classNames = cell(obj.K,1);
        for j = 1:obj.K 
            obj.classNames{j,1} = int2str(j);
        end
    end
end


%toString
function myString = toString(obj)
    myString = '------------------------------------\nClosed Multi-Class Queueing Network with Coxian service times\n';
    myString = [myString, 'M: ', int2str(obj.M),'\n'];
    myString = [myString, 'K: ', int2str(obj.K),'\n'];
    myString = [myString, 'N: ', int2str(obj.N),'\n'];
    myString = [myString, 'Service stations\n'];
    myString = [myString, '#   #Servers\tsched\tname\n'];
    for j = 1:obj.M
        myString = [myString, int2str(j), '\t', num2str(obj.S(j)), '\t', obj.sched{j,1}, '\t', obj.nodeNames{j,1} , '\n'];
    end
    for j = 1:obj.K
        myString = [myString, '\nClass: ', obj.classNames{j,1}, '\n'];
        myString = [myString, '\nInit # of jobs:: ', num2str(obj.NK(j)), '\n'];
        myString = [myString, '\nReference node: ', num2str(obj.refNodes(j)), '\n'];
        myString = [myString, '\nChain: ', find(obj.classMatch(:,j)==1), '\n'];
        myString = [myString, 'Stat # \tService rates \tCompletion Probs:\n'];
        for i = 1:obj.M
            myString = [myString, int2str(i),':'];
            for l = 1:length(obj.mu{i,j})
                myString = [myString,'\t', num2str(obj.mu{i,j}(l)),'\t', num2str(obj.phi{i,j}(l)),'\n'];
            end
        end
    end
    myString = [myString, 'Routing matrix:\n'];
    for i = 1:obj.M
        for k = 1:obj.K
            for j= 1:obj.M
                for l = 1:obj.K
                    myString = [myString, num2str(obj.P( (i-1)*obj.K+k,(j-1)*obj.K+l) ),'\t'];
                end
            end
            myString = [myString,'\n'];
        end
    end
    myString = [myString, '------------------------------------\n'];
    myString = sprintf(myString);
end


end

end