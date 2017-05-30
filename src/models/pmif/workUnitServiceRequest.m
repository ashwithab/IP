classdef workUnitServiceRequest
% WORKUNITSERVICEREQUEST defines WORKUNITSERVICEREQUEST objects, as part of a Performance Model Interchange Format (PMIF) model. 
%
% Properties:
% workloadName:         name of the workload associated to this service request (string)
% serverID:             name of the server where this ervice request takes place (string)
% numberVisits:         number of visits of this request class to this server (integer)
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
    numberVisits;   %int
    transits;
end

methods
%public methods, including constructor

    %constructor
    function obj = workUnitServiceRequest(workloadName, serverID, numberVisits)
        if(nargin > 0)
            obj.workloadName = workloadName;
            obj.serverID = serverID;
            obj.numberVisits = numberVisits;
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
        myString = sprintf([myString, 'numberVisits: ', num2str(obj.numberVisits),'\n']);
        for i = 1:size(obj.transits,1)
            myString = sprintf([myString, 'transit ', int2str(i),':',  obj.transits{i,1}, ' - ',  num2str(obj.transits{i,2}),'\n']);
        end
    end

end
    
end