function [myCQN, REflag, COXflag, REPHflag] = extendCQN(myCQN, filenameEXT, activitiesProcs, activitiesClass, verbose)
% Q = EXTEND_CQN(A,B) extends a CQN model A to include the extensions 
% described in the XML file B. Currently, Line supports extensions for 
% random environments (RE) and Coxian distributions. 
%
% Parameters:
% myCQN:            CQN model to be extended
% filenameEXT:      path of the XML file that describes a set of extensions
% activitiesProcs:  list of LQN activities and processors where they execute
% activitiesClass:  list of LQN activities and the associated request
%                   classes in the CQN model
% verbose:          1 for screen output
% 
% Output:
% myCQN:        extended QN model 
% REflag:       1 if the model includes RE elements, 0 otherwise
% COXflag:      1 if the model includes COX elements, 0 otherwise
% REPHflag:     1 if the model includes REPH elements, 0 otherwise
%                   environmental changes
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import java.io.File;

import lqn.*; 

% indicators of whether the model includes REs or Coxians
REflag = 0;
COXflag = 0;
REPHflag = 0;

dbFactory = DocumentBuilderFactory.newInstance();
dBuilder = dbFactory.newDocumentBuilder();
try
    doc = dBuilder.parse(filenameEXT);
catch exception 
    if ~exist(filenameEXT, 'file')
        disp(['Error: Input XML file ', filenameEXT, ' not found']);
        return;
    else 
        rethrow(exception);
    end
end
 
doc.getDocumentElement().normalize();
if verbose > 0
    disp(['Parsing LQN Extension file: ', filenameEXT] );
    disp(['Root element :', char(doc.getDocumentElement().getNodeName()) ] );
end


%% COX extensions
[COXs, COX_IDs] = parseXML_COX(doc); 
COXflag = ~isempty(COXs); 
if COXflag
    if verbose > 0
        disp('COX extension defined'); 
    end
    myCQN = extendCQN_COX(myCQN, COXs, activitiesProcs, activitiesClass, verbose);
end
    
%% RE extensions
[REs, REPHflag] = parseXML_REPH(doc); 
REflag = ~isempty(REs); 
if REflag
    if verbose > 0 
        disp('RE extension defined');
    end
    if COXflag
        if REPHflag
            myCQN = extendCQNCOX_REPH(myCQN, REs, COXs, COX_IDs, verbose);
        else
            myCQN = extendCQNCOX_RE(myCQN, REs, verbose);
        end
    else
        myCQN = extendCQN_RE(myCQN, REs, verbose);
    end
end



