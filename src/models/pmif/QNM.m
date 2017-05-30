classdef QNM
% QNM defines a Queueing Network Model object, as in the Performance Model Interchange Format (PMIF) model. 
%
% Properties:
% servers:                  list of servers
% workUnitServers:          list of work unit servers
% closedWorkloads:          list of closed workloads
% demandServiceRequests:    list of demand service requests
% workUnitServiceRequests:  list of work unit service requests
% timeServiceRequests:      list of time service requests
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    servers;
    workUnitServers; 
    closedWorkloads; 
    demandServiceRequests;
    workUnitServiceRequests;
    timeServiceRequests;
end

methods
%public methods, including constructor

    %constructor
    function obj = QNM(servers, workUnitServers, closedWorkloads, ...
                    demandServiceRequests, workUnitServiceRequests, timeServiceRequests)
        if(nargin > 0)
            obj.servers = servers;
            obj.workUnitServers = workUnitServers;
            obj.closedWorkloads = closedWorkloads;
            obj.demandServiceRequests = demandServiceRequests;
            obj.workUnitServiceRequests = workUnitServiceRequests;
            obj.timeServiceRequests = timeServiceRequests;
        end
    end
    

end
    
end