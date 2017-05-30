classdef LINEprotocolXML
% LINEPROTOCOLXML defines an object to control the interaction between the
% LINE client and the server. It handles a set of instructions from the
% LINE client and returns responses according to the results from the
% solver
%
% LINEPROTOCOLXML maintains the LINE object that solves the model,
% processes the input instructions for the solver in the LINE object, 
% and call these solvers. 
%
% Properties:
% state:        state of the protocol
%               values:  
%               EMPTY:  no model has been loaded
%               INIT:   a model has been loaded, no model has been run
%               SOLVED: a model has been run
% myLINE:       LINE object
% SEQ:          1 if LINE operates sequentially
%               0 (default) if LINE operates in parallel
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

properties
    EMPTY = 0;      % no model has been loaded
    INIT = 1;       % a model has been loaded, no model has been run
    SOLVED = 2;     % a model has been run
    state;          % initial state = waiting
    myLINE;         % LINE object
end


methods
    % Constructor
    function obj = LINEprotocolXML(maxIter,PARALLEL,RT,RTrange,solver,verbose)
        obj.state = obj.EMPTY;                          % initial state = waiting
        obj.myLINE = LINE_obj(maxIter,PARALLEL,RT,RTrange,solver,verbose); % LINE object 
        obj.state = obj.INIT;                           % update state
    end

    % This function process the input lines 
    % The two accepted commands are those staring with QUIT, CLOSE, and SOLVE
    function [theOutput, obj] = processInput(obj, theInput) 
        theOutput = [];
        if obj.state == obj.INIT
            n = size(theInput,1);
            quitCommand = 0;
            closeCommand = 0;
            XMLfiles = cell(0);
            REfiles = cell(0);
            for i = 1:n
                myInput = char(theInput{i});
                %QUIT
                if length(myInput)==4 && strcmpi( myInput, 'QUIT')
                    quitCommand = 1;
                    break;
                %CLOSE
                elseif length(myInput)==5 && strcmpi( myInput, 'CLOSE')
                    closeCommand = 1;
                    break;
                %SOLVE
                elseif length(myInput)>7 && strcmpi( myInput(1:5), 'SOLVE')
                    myInput = myInput(7:end); 
                    breakIdx = strfind(myInput, '.xml');
                    breakIdx2 = strfind(myInput, '.lqxo'); 
                    
                    lengthExt = [];
                    if ~isempty(breakIdx2)
                        lengthExt = 4*ones(1,length(breakIdx2));
                    end
                    if ~isempty(breakIdx)
                        lengthExt = [lengthExt 3*ones(1,length(breakIdx))];
                    end
                    breakIdx = [breakIdx2 breakIdx]; 
                    if length(breakIdx) == 1
                        XMLfile = myInput(1:breakIdx(1)+lengthExt(1)); 
                        REfile = '';
                    elseif length(breakIdx) == 2
                        XMLfile = myInput(1:breakIdx(1)+lengthExt(1)); 
                        if strcmp(myInput(breakIdx(1)+lengthExt(1)+1), ' ')
                            REfile = myInput(breakIdx(1)+lengthExt(1)+2:breakIdx(2)+lengthExt(2)); 
                        else
                            REfile = '';
                        end
                    end
                    if ~exist(XMLfile, 'file') 
                        theOutput{end+1,1} = ['ERROR: File ',XMLfile,' not found.'];
                    elseif ~isempty(REfile) && ~exist(REfile, 'file') 
                        theOutput{end+1,1} = ['ERROR: File ',REfile,' not found.'];
                    else
                        XMLfiles{end+1,1} = XMLfile; 
                        REfiles{end+1,1} = REfile; 
                    end
                else
                    theOutput{end+1,1} = ['ERROR: Command not recognized. Please try again.'];
                end
                
            end
            
            try
               if ~isempty(XMLfiles)
                    obj.myLINE = obj.myLINE.solve(XMLfiles, REfiles);
                    
                    newOutput = cell(size(XMLfiles));
                    for j = 1:size(XMLfiles,1)
                        newOutput{j,1} = ['MODEL ', XMLfiles{j,1}, ' ', REfiles{j,1}, ' SUBMITTED'];
                    end
                    theOutput = [theOutput; newOutput]; 
                    
                    if obj.myLINE.PARALLEL == 0 || obj.myLINE.PARALLEL == 2
                        % in sequential and parfor execution models have been already solved
                        newOutput = cell(size(XMLfiles,1),1);
                        for j = 1:size(XMLfiles,1)
                            newOutput{j,1} = ['MODEL ', XMLfiles{j,1}, ' ', REfiles{j,1}, ' SOLVED'];
                        end
                        theOutput = [theOutput; newOutput]; 
                    end
               end
            catch ME
                theOutput{end+1,1} = ['ERROR: An error has occurred while executing LINE.'];
                theOutput{end+1,1} = ['ERROR: ', ME.message];
                for j = 1:length(ME.stack)
                    theOutput{end+1,1} = ['ERROR: Error in line ', int2str(ME.stack(j).line), ' of LINE script ', ME.stack(j).name];
                end
            end
            
            if closeCommand == 1
                theOutput{end+1,1} = 'Closing connection';
            end
            if quitCommand == 1
                theOutput{end+1,1} = 'Quitting LINE';
            end
        end
    end

end
    
end