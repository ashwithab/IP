classdef (Sealed) Perf
% JLAB 0.1.0    
% Copyright (c) 2017, Imperial College London 
% All rights reserved.

properties (Constant)
    DropRate = 'Drop Rate';
    NumCust = 'Number of Customers';
    QueueT = 'Queue Time';
    ResidT = 'Residence Time';
    FCRWeight = 'FCR Total Weight';
    FCRMemOcc = 'FCR Memory Occupation';
    FJNumCust = 'Fork Join Response Time';
    FJRespT = 'Fork Join Response Time';
    RespT = 'Response Time';
    RespTSink = 'Response Time per Sink';
    SysDropR = 'System Drop Rate';
    SysNumCust = 'System Number of Customers';
    SysPower = 'System Power';
    SysRespT = 'System Response Time';
    SysTput = 'System Throughput';
    Tput = 'Throughput';
    TputSink = 'Throughput per Sink';
    Util = 'Utilization';
end 

end