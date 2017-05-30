classdef CQNREPH
% CQNRE defines an object that represents a Closed Multi-Class Queueing
% Network with Class Switching in a Random Environment (RE), 
% where the RE has PH holding times. 
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
% ENV:          Ex3 cell defining the parameters for the RE
%               Entry {e,1} holds the initial probability vector of the
%               stage-e PH holding time (1xm_e double)
%               Entry {e,2} holds the sub-generator matrix of the
%               stage-e PH holding time (m_exm_e double)
%               Entry {e,3} holds the transition probabilities to each
%               stage, after a sojourn in stage e (1xm_e double)
% S:            number of servers per station (Mx1 int)
% rates:        service rate for each job class in each station 
%               (MxK matrix with double entries)  
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
   E;           % number of environmental stages (int)
   N;           % total population (int), sum(NK) = N - optional       
   ENV;         % Ex3 cell defining the parameters for the RE
                % Entry {e,1} holds the initial probability vector of the
                % stage-e PH holding time (1xm_e double)
                % Entry {e,2} holds the sub-generator matrix of the
                % stage-e PH holding time (m_exm_e double)
                % Entry {e,3} holds the transition probabilities to each
                % stage, after a sojourn in stage e (1xm_e double)
   S;           % number of servers per station in each stage
                % (Ex1 cell with Mx1 int entries)
   rates;       % service rate for each job class in each station and stage
                % (Ex1 cell with MxK double matrix entries)
   sched;       % scheduling policy in each station 
                % (Kx1 cell with string entries)
   P;           % transition matrices in each stage
                % (Ex1 cell with MKxMK double entries)
   NK;          % population per class (Kx1 int) - In case of class switching, initial distribution
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
function obj = CQNREPH(M, K, E, N, ENV, S, rates, sched, P, NK, classMatch, refNodes, nodeNames, classNames)
    if nargin < 10
        disp('Too few arguments for a CQN_RE');
        obj = [];
    else
        if nargin > 0
            obj.M = M;
            obj.K = K;
            obj.E = E;
            obj.N = N;
            obj.ENV = ENV;
            obj.S = S;
            obj.rates = rates;
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
end


%toString
function myString = toString(obj)
    myString = ['------------------------------------\n',...
                    'Closed Multi-Class Queueing Network with Class-Switching in a Random Environment\n'];
    myString = [myString, 'M: ', int2str(obj.M),'\n'];
    myString = [myString, 'K: ', int2str(obj.K),'\n'];
    myString = [myString, 'E: ', int2str(obj.E),'\n'];
    myString = [myString, 'N: ', int2str(obj.N),'\n'];
    myString = [myString, 'Service stations\n'];
    myString = [myString, '#\tsched\tname\n'];
    for j = 1:obj.M
        myString = [myString, int2str(j), '\t', obj.sched{j,1}, '\t', obj.nodeNames{j,1} , '\n'];
    end

    myString = [myString, 'Random environment\n'];
    for i = 1:obj.E
        myString = [myString, 'Stage', int2str(i), '\n'];
        myString = [myString, 'Init. prob. vector: ', num2str(obj.ENV{i,1}),'\n'];
        myString = [myString, 'Sub-generator matrix: ', num2str(obj.ENV{i,2}),'\n'];
        myString = [myString, 'Transition probs: ', num2str(obj.ENV{i,3}),'\n'];
        myString = [myString,'\n'];
    end

    for e = 1:obj.E
        myString = [myString, '----------------\nStage ', int2str(e), '\n'];
        for j = 1:obj.K
            myString = [myString, '\nClass ', int2str(j), '\n'];
            myString = [myString, 'NK: ', num2str(obj.NK(j)),'\n'];
            myString = [myString, '\nReference node: ', num2str(obj.refNodes(j)), '\n'];
            myString = [myString, '\nChain: ', find(obj.classMatch(:,j)==1), '\n'];
            myString = [myString, 'Service rates:\n'];
            for i = 1:obj.M
                myString = [myString, int2str(i),': ', num2str(obj.rates{e}(i,j) ),'\n'];
            end
        end
        myString = [myString, '----------------\nRouting matrix:\n'];
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