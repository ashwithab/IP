classdef closedWorkload
% CLOSEDWORKLOAD defines CLOSEDWORKLOAD objects, as in a Performance Model Interchange Format (PMIF) model. 
%
% Properties:
% name:                 workload name (string)
% numberJobs:           number of jobs/users belonging to this workload/class (integer)
% thinkTime:            mean time spent in a delay node (double)
% thinkDevice:          name of the delay node (double)
% timeUnits:            time units in which the think time is measured (string - optional)
% transits:             list of (dest,prob) tuples describing the routing
%                       after the visit to the think node. Each entry holds
%                       the name of the destination node (dest) and the
%                       probability (prob)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    name;               %string
    numberJobs;         %int
    thinkTime;          %string
    thinkDevice;        %double
    timeUnits = '';     %string - optional
    transits;           %cell
end

methods
%public methods, including constructor

    %constructor
    function obj = closedWorkload(name, numberJobs, thinkTime, thinkDevice, timeUnits)
        if(nargin > 0)
            obj.name = name;
            obj.numberJobs = numberJobs;
            obj.thinkTime = thinkTime;
            obj.thinkDevice = thinkDevice;
            if nargin > 4 
                obj.timeUnits = timeUnits;
            end
        end
    end
    
    function obj = addTransit(obj, dest, prob)
        if isempty(obj.transits)
            obj.transits = cell(1,2);
            obj.transits{1,1} = dest;
            obj.transits{1,2} = prob;
        else
           obj.transits{end+1,1} = dest; 
           obj.transits{end,2} = prob;
        end
    end
    
     %toString
    function myString = toString(obj)
        myString = sprintf(['<<<<<<<<<<\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'number of jobs: ', int2str(obj.numberJobs),'\n']);
        myString = sprintf([myString, 'thinkTime: ', num2str(obj.thinkTime),'\n']);
        myString = sprintf([myString, 'thinkDevice: ', obj.thinkDevice,'\n']);
        myString = sprintf([myString, 'timeUnits: ', obj.timeUnits,'\n']);
        for i = 1:size(obj.transits,1)
            myString = sprintf([myString, 'transit ', int2str(i),':',  obj.transits{i,1}, ' - ',  num2str(obj.transits{i,2}),'\n']);
        end
    end

end
    
end