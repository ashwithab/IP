classdef timeServiceRequest
% TIMESERVICEREQUEST defines TIMESERVICEREQUEST objects, as part of a Performance Model Interchange Format (PMIF) model. 
%
% Properties:
% workloadName:         name of the workload associated to this service request (string)
% serverID:             name of the server where this ervice request takes place (string)
% serviceDemand:        mean demand posed by the service request on the server (double)
% numberVisits:         number of visits of this request class to this server (integer)
% timeUnits:            time units in which the service time is measured (string - optional)
% transits:             list of (dest,prob) tuples describing the routing
%                       after the visit to the servic node. Each entry holds
%                       the name of the destination node (dest) and the
%                       probability (prob)
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    workloadName;   %string
    serverID;       %string
    serviceDemand;  %double
    timeUnits = ''; %string - optional
    transits;
end

methods
%public methods, including constructor

    %constructor
    function obj = timeServiceRequest(workloadName, serverID, serviceDemand, timeUnits)
        if(nargin > 0)
            obj.workloadName = workloadName;
            obj.serverID = serverID;
            obj.serviceDemand = serviceDemand;
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
        myString = sprintf(['<<<<<<<<<<\nworkload name: ', obj.workloadName,'\n']);
        myString = sprintf([myString, 'serverID: ', num2str(obj.serverID),'\n']);
        myString = sprintf([myString, 'serviceDemand: ', num2str(obj.serviceDemand),'\n']);
        myString = sprintf([myString, 'timeUnits: ', obj.timeUnits,'\n']);
        for i = 1:size(obj.transits,1)
            myString = sprintf([myString, 'transit ', int2str(i),':',  obj.transits{i,1}, ' - ',  num2str(obj.transits{i,2}),'\n']);
        end
    end

end
    
end