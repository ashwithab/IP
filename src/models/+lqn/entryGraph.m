classdef entryGraph
% entryGraph defines an object that represents the entry services in LQN
% models. These are deployed on LQN processors, that are not reference
% processors, hardware processors, nor delays. 
% More details on entryGraphs and their role in PCM and LQN models can be found 
% on the LINE documentation, available at http://line-solver.sourceforge.net/
%
% Properties:
% name:                 name of the associated LQN processor (string)
% M:                    number of stations in the model
% K:                    number of classes in the model
% graph:                matrix representing the graph of (proc,class) pairs that compose a call to this entry 
%                       (MKxMK real matrix) - M: number of nodes - K:number of classes
% initAct:              initial activity of the associated LQN processor with an actual call for a service
% initEntries:          initial entries in the graph, as (proc,class) pairs (numSamples x 2) 
% numSamples:           number of samples / calls to this service in the model
% currSample:           current sample - used to build the graph while parsing the LQN model
% currProc:             current processor being considered
% currClass:            current class being considered
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.
    
properties
    name;               % name of the associated LQN processor (string)
    M;                  % number of stations in the model
    K;                  % number of classes in the model
    graph = [];         % matrix representing the graph of (proc,class) pairs that compose a call to this entry 
                        % (MKxMK real matrix) - M: number of nodes - K:number of classes
    initAct = 0;        % initial activity of the associated LQN processor with an actual call for a service
    initEntries = [];   % initial entries in the graph, as (proc,class) pairs (numSamples x 2) 
    numSamples = 0;     % number of samples / calls to this service in the model
    currSample = 0;     % current sample - used to build the graph while parsing the LQN model
    currProc = 0;       % current processor being considered
    currClass = 0;      % current class being considered
end


methods
%public methods, including constructor

    % constructor
    function obj = entryGraph(name, M, K, initAct)
        if(nargin > 0)
            obj.name = name;
            obj.M = M;
            obj.K = K;
            obj.graph = zeros(M*K, M*K);
            obj.initAct = initAct;
        end
    end
    
    % addClass: adds a new class (K+1), enlarging the graph
    function obj = addClass(obj)
        newGraph = zeros(obj.M*(obj.K+1), obj.M*(obj.K+1));
        newIdx = 1:obj.M*(obj.K+1);
        newIdx = reshape(newIdx,obj.K+1,obj.M);
        newIdx = reshape(newIdx(1:obj.K,:) ,1,[]);
        newGraph(newIdx,newIdx) = obj.graph;
        obj.graph = newGraph; 
        obj.K = obj.K + 1;
    end
    
    % addConnection: adds a new connection from (p1,c1) to (p2,c2) with
    % probability prob to the graph
    % LQNact indicates the activity of the associ
    function obj = addConnection(obj, p1, c1, p2, c2, prob)
        % first ever connection
        if obj.currProc == 0 || obj.currClass == 0
            obj.numSamples = 1;
            obj.currSample = 1;
            obj.initEntries = [p1 c1]; 
            
        % current class and processor coincide - continuation of the same sample
        %elseif obj.currProc == p1 && obj.currClass == c1 %% what if they coincide but this is the second consecutive to the service, not ?
            
        % connection starts a new sample
        %else
        elseif obj.currProc ~= p1 || obj.currClass ~= c1
            obj.numSamples = obj.numSamples + 1;
            obj.currSample = obj.currSample + 1;
            obj.initEntries = [obj.initEntries; [p1 c1] ] ; 
        end
        obj.currProc = p2;
        obj.currClass = c2;
        obj.graph((p1-1)*obj.K + c1, (p2-1)*obj.K + c2) = prob;
    end
    
    
  
        

end
    
end