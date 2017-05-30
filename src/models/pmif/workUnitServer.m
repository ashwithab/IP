classdef workUnitServer
% WORKUNITSERVER defines WORKUNITSERVER objects, as in a Performance Model Interchange Format (PMIF) model. 
%
% Properties:
% name:                 server name (string)
% quantity:             number of servers (integer)
% scheduling:           service scheduling policy  (string in {'IS', 'FCFS', 'PS'} )
% serviceTime:          mean service time (double)
% timeUnits:            time units in which the service time is measured (string - optional)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    name;               %string
    quantity = 1;       %int
    scheduling;         %string
    serviceTime;        %double
    timeUnits = '';     %string - optional
end

methods
%public methods, including constructor

    %constructor
    function obj = workUnitServer(name, quantity, scheduling, serviceTime, timeUnits)
        if(nargin > 0)
            obj.name = name;
            obj.quantity = quantity;
            obj.scheduling = scheduling;
            obj.serviceTime = serviceTime;
            if nargin > 4 
                obj.timeUnits = timeUnits;
            end
        end
    end
    
     %toString
    function myString = toString(obj)
        myString = sprintf(['<<<<<<<<<<\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'quantity: ', int2str(obj.quantity),'\n']);
        myString = sprintf([myString, 'scheduling: ', obj.scheduling,'\n']);
        myString = sprintf([myString, 'serviceTime: ', num2str(obj.serviceTime),'\n']);
        myString = sprintf([myString, 'timeUnits: ', obj.timeUnits,'\n']);
    end

end
    
end