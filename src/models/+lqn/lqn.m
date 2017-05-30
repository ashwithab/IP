classdef lqn
% LQN defines a object for a Layered Queueing Network (LQN) model. 
% This object is defined as a list of processor objects. 
% More details on processors and their role in LQN models can be found 
% on the LINE documentation, available at http://line-solver.sourceforge.net
%
% Properties:
% name:                 model name (string)
% processors:           list of the processors that form part of this model
% tasks:                list of tasks  - cell (task name, task ID, proc name, proc ID)
% entries:              list of entries  - cell (entry name, task ID)
% actProcs:             list of physical processors and workload sources 
%                       cell - (proc name, proc ID, task name, task ID)
% requesters:           list of activities that demand a service from an entry
%                       cell - (act name, task ID, proc name, target entry, procID)
% providers:            list of activities/entries that provide services 
%                       cell - (act name, entry name, task name, proc name, proc ID)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    name;               % string
    processors = [];    % list of processors
    tasks = cell(0,4);         % list of tasks
    entries = cell(0,2);       % list of entries
    actProcs = cell(0,4);      % list of physical processors and worklodad sources
    %requesters = [];    % list of activities that demand a service an entry
    providers = cell(0,5);     % list of activities/entries that provide services 
end

methods
%public methods, including constructor

    % constructor
    function obj = lqn(name)
        if(nargin > 0)
            obj.name = name;
        end
    end
    
    
    % addProcessor 
    function obj = addProcessor(obj, newProc)
        if(nargin > 1)
            obj.processors = [obj.processors; newProc];
        end
    end
    
    
    % toString
    function myString = toString(obj)
        myString = ['----------\nname: ', obj.name,'\n'];
        myString = [myString, 'processors:\n'];
        for j = 1:length(obj.processors)
            myString = [myString, obj.processors(j).toString()];
        end
        myString = sprintf(myString);
    end

end
    
end