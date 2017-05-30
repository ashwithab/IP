classdef server
% SERVER defines SERVER objects, as part of a Performance Model Interchange Format (PMIF) model. 
%
% Properties:
% name:                 server name (string)
% quantity:             number of servers (integer)
% scheduling:           service scheduling policy  (string in {'IS', 'FCFS', 'PS'} )
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    name;                 %string
    quantity = 1;         %int
    scheduling;           %string 
end

methods
%public methods, including constructor

    %constructor
    function obj = server(name, quantity, scheduling)
        if(nargin > 0)
            obj.name = name;
            obj.quantity = quantity;
            obj.scheduling = scheduling;
        end
    end
    
     %toString
    function myString = toString(obj)
        myString = sprintf(['<<<<<<<<<<\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'quantity: ', int2str(obj.quantity),'\n']);
        myString = sprintf([myString, 'scheduling: ', obj.scheduling,'\n']);
    end

end
    
end