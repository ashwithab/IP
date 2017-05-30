classdef CQNRECox
% CQNRECOX defines an object that represents a Closed Multi-Class Queueing
% Network with Class Switching  with Coxian service times in a Random Environment. 
% The parameters affected by the environmental stage are: the number of
% servers (S), the service rates (rates), and the routing probabilities (P)
% More details on this type of queueing networks can be found 
% on the LINE documentation, available at http://line-solver.sf.net
%
% Properties:
% M:            number of stations (int)
% K:            number of classes (int)
% E:            number of environmental stages (int)
% N:            total population (int)
% ENV:          random environment generator matrix (ExE double matrix)
% S:            number of servers per station (Mx1 int)
% mu:           transition rates for each of the Coxian service phases 
%               for each job class in each station and stage
%               (ExMxK cell with n_{e,i,k}x1 double entries)
% phi:          completion probability for each of the Coxian service phases 
%               for each job class in each station and stage
%               (ExMxK cell with n_{e,i,k}x1 double entries)
% sched:        scheduling policy in each station 
%               (Kx1 cell with string entries)
% P:            transition matrix with class switching
%               (MKxMK matrix with double entries), indexed first by station, then by class
% resetRules:   reset rules for each transition
%               (ExE cell with string entries)
% NK:           initial distribution of jobs in classes (Kx1 int)
% C:            number of chains (int)
% classMatch:   1-0 CxK matrix where 1 in entry (i,j) indicates that class 
%               j belongs to chain i. Column sum must be 1. (CxK int)
% refNodes:     index of the reference node for each request class (Kx1 int)
% nodeNames:    name of each node
%               (Mx1 cell with string entries) - optional
% classNames:   name of each job class
%               (Kx1 cell with string entries) - optional
% adhocResetRules: adhoc reset rules 
%                  (ExE cell with mexmf entries, where me is the
%                  total number of states in the representation 
%                  of the CQN associated with stage e)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


properties
   M;           % number of stations (int)
   K;           % number of classes (int)
   E;           % number of environmental stages (int)
   N;           % total population (int), sum(NK) = N - optional
   ENV;         % random environment generator matrix (ExE double matrix)
   S;           % number of servers per station in each stage
                % (Ex1 cell with Mx1 int entries)
   mu;          % transition rates for each of the Coxian service phases 
                % for each job class in each station and stage
                % (ExMxK cell with n_{e,i,k}x1 double entries)
   phi;         % completion probability for each of the Coxian service phases 
                % for each job class in each station and stage
                % (ExMxK cell with n_{e,i,k}x1 double entries)
   sched;       % scheduling policy in each station 
                % (Kx1 cell with string entries)
   P;           % transition matrices in each stage
                % (Ex1 cell with MKxMK double entries)
   resetRules;  % reset rules for each transition
                % ExE cell with string entries
   NK;          % Initial population per class (Kx1 int)
   C;           % number of chains (int)
   classMatch;  % 1-0 CxK matrix where 1 in entry (i,j) indicates that class  
                % j belongs to chain i. Column sum must be 1. (CxK int)
   refNodes;    % index of the reference node for each request class (Kx1 int)
   nodeNames;   % name of each node
                % (Mx1 cell with string entries) - optional
   classNames;  % name of each job class
                % (Kx1 cell with string entries) - optional
   adhocResetRules; % adhoc reset rules 
                    % ExE cell with mexmf entries, where me is the
                    % total number of states in the representation 
                    % of the CQN associated with stage e
end


methods

%constructor
function obj = CQNRECox(M, K, E, N, ENV, S, mu, phi, sched, P, NK, classMatch, refNodes, resetRules, nodeNames, classNames, adhocResetRules)

    if nargin < 11
        disp('Too few arguments for a CQNRECox');
        obj = [];
    else
        obj.M = M;
        obj.K = K;
        obj.E = E;
        obj.N = N;
        obj.ENV = ENV;
        obj.S = S;
        obj.mu = mu;
        obj.phi = phi;
        obj.sched = sched;
        obj.P = P;
        obj.NK = NK;
        obj.classMatch = classMatch;
        obj.C = size(classMatch,1); 
        obj.refNodes = refNodes; 
        if nargin > 13
            obj.resetRules = resetRules;
        else
            obj.resetRules = cell(E,E);
            for i=1:E
              for j=[1:i-1 i+1:E]
                  obj.resetRules{i,j} = 'noReset';
              end
            end
        end
        if nargin > 14
            obj.nodeNames = nodeNames;
        else
            obj.nodeNames = cell(obj.M,1);
            for j = 1:obj.M 
                obj.nodeNames{j,1} = int2str(j);
            end
        end
        if nargin > 15
            obj.classNames = classNames;
        else
            obj.classNames = cell(obj.K,1);
            for j = 1:obj.K 
                obj.classNames{j,1} = int2str(j);
            end
        end
        if nargin > 16
            obj.adhocResetRules = adhocResetRules;
        end
    end
end


%toString
function myString = toString(obj)
    myString = ['------------------------------------\n',...
    'Closed Multi-Class Queueing Network with Class-Switching',...
    'and Coxian Service Times in a Random Environment\n'];
    myString = [myString, 'M: ', int2str(obj.M),'\n'];
    myString = [myString, 'K: ', int2str(obj.K),'\n'];
    myString = [myString, 'E: ', int2str(obj.N),'\n'];
    myString = [myString, 'N: ', int2str(obj.N),'\n'];
    myString = [myString, 'Service stations\n'];
    myString = [myString, '#\tsched\tname\n'];
    for j = 1:obj.M
        myString = [myString, int2str(j), '\t', obj.sched{j,1}, '\t', obj.nodeNames{j,1} , '\n'];
    end

    myString = [myString, 'Random environment generator\n'];
    for i = 1:obj.E
        for j = 1:obj.E
            myString = [myString, num2str(obj.ENV(i,j)),'\t'];
        end
        myString = [myString,'\n'];
    end

    for e = 1:obj.E
        myString = [myString, '----------------\nStage ', int2str(e), '\n'];
        for j = 1:obj.K
            myString = [myString, '\nClass ', int2str(j), '\n'];
            myString = [myString, 'NK: ', num2str(obj.NK(j)),'\n'];
            myString = [myString, '\nReference node: ', num2str(obj.refNodes(j)), '\n'];
            myString = [myString, '\nChain: ', find(obj.classMatch(:,j)==1), '\n'];
            myString = [myString, 'Service parameters:\n'];
            for i = 1:obj.M
                myString = [myString, 'Station ', num2str(i), '\n'];
                myString = [myString, 'phase\tmu\tphi:\n'];
                for l = 1:length(obj.mu{e,i,j})
                    myString = [myString, int2str(l),'\t', num2str(obj.mu{e,i,j}(l) ),'\t', num2str(obj.phi{e,i,j}(l) ),'\n'];
                end
            end
        end

        myString = [myString, 'Routing matrix:\n'];
        for i = 1:obj.M
            for k = 1:obj.K
                for j= 1:obj.M
                    for l = 1:obj.K
                        myString = [myString, num2str(obj.P{e}( (i-1)*obj.K+k,(j-1)*obj.K+l) ),'\t'];
                    end
                end
                myString = [myString,'\n'];
            end
        end
    end
    myString = [myString, '------------------------------------\n'];
    myString = sprintf(myString);
end


end
    
end