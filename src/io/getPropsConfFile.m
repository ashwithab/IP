function props = getPropsConfFile(filename)
% GETPROPSCONFFILE Reads a properties file and returns the properties 
% values as a struct. 
% P = getPropsConfFile(F) reads the file F and 
% returns the properties in the struct P
% 
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

prop = java.util.Properties();
try 
    prop.load(java.io.FileInputStream(filename));
catch e
    disp(e.message);
    ex = e.ExceptionObject;
    ex.printStackTrace();
    e.rethrow();
end

props = [];
port = prop.get('port');
if ~isempty(port) 
    props.port = str2num(port);
end
maxIter = prop.get('maxIter');
if ~isempty(maxIter) 
    props.maxIter = floor(str2num(maxIter));
end
maxJobSize = prop.get('maxJobSize');
if ~isempty(maxJobSize) 
    props.maxJobSize = floor(str2num(maxJobSize));
end
parallel = prop.get('parallel');
if ~isempty(parallel) 
    props.parallel = parallel;
end
verbose = prop.get('verbose');
if ~isempty(verbose) 
    props.verbose = floor(str2num(verbose));
end
timeoutConn = prop.get('timeoutConnection');
if ~isempty(timeoutConn) 
    props.timeoutConn = floor(str2num(timeoutConn));
end
respTimePerc = prop.get('respTimePerc');
if ~isempty(respTimePerc) 
    props.respTimePerc = respTimePerc;
end
respTimePercMin = prop.get('respTimePercMin');
if ~isempty(respTimePercMin) 
    props.respTimePercMin = str2num(respTimePercMin);
end
respTimePercMax = prop.get('respTimePercMax');
if ~isempty(respTimePercMax) 
    props.respTimePercMax = str2num(respTimePercMax);
end
respTimePercStep = prop.get('respTimePercStep');
if ~isempty(respTimePercStep) 
    props.respTimePercStep = str2num(respTimePercStep);
end
solver = prop.get('solver');
if ~isempty(solver) 
    props.solver = solver;
end

