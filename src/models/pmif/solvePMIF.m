function solvePMIF(PMIFfilepath, options)
% SOLVEPMIF solves a (set of) PMIF model(s) specified by the path 
% PMIFfilepath, which can be a single file or a folder with several files.  
% For each file analyzed, the results are saved in XML format in the same 
% folder as the input file, and with the same name adding the suffix 
% '-line.xml' 
% 
% Input:
% PMIFfilepath:         filepath of the PMIF XML file with the model to solve
% options:              structure that defines the following options: 
% options.outputFolder: path of an alternative output folder
% options.RTdist:       1 if the response-time distribution is to be
%                       computed, 0 otherwise
% options.RTrange:      array of double in (0,1) with the percentiles to 
%                       evaluate the response-time distribution
% options.verbose:      1 for screen output, 0 otherwise  
%    
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin < 2 
    options = [];
end
%% read options - set defaults if no options provided
[outputFolder, RT, RTrange, maxIter, solver, verbose] = parseOptions(options);

%% if this is a single file 
if exist(PMIFfilepath, 'file') == 2 % it is a file
    allFilenames = {PMIFfilepath}; 
    [~, name, ext] = fileparts(PMIFfilepath);  
    shortNames = {[name, ext]}; 
elseif exist(PMIFfilepath, 'dir') % it is a directory
    folderContents = dir(PMIFfilepath); 
    names = {folderContents.name}';
    allFilenames = cell(0);
    shortNames = cell(0);
    for j = 1:size(names,1)
        if folderContents(j).isdir == 0 && strcmp(folderContents(j).name(end-3:end), '.xml')
            allFilenames{end+1,1} = fullfile(PMIFfilepath, names{j}); 
            shortNames{end+1,1} = names{j}; 
        end
    end
else
    disp(['Error: Input file path ', PMIFfilepath,' not found']);
    return;
end

for j = 1:size(allFilenames,1)
    myPath = allFilenames{j}; 
    % obtain CQN model from PMIF model
    myCQN = PMIF2CQN(myPath, verbose);
    
    if ~isempty(myCQN)
        % check solver 
        [mySolver,myRT] = checkLINESolver(solver,RT,myCQN);
        % compute performance measures
        %max_iter = 1000;
        delta_max = 0.01;
        [~, U, R, X, ~, RT_CDF, ~] = CQN_analysis(myCQN, [], [], [], maxIter, delta_max, myRT, RTrange, mySolver, verbose);

        for i = 1:myCQN.M
            if strcmp(myCQN.sched{i},'inf')
                meanRT = sum(R([1:i-1 i+1:myCQN.M],:),1);
                break;
            end
        end
        
        % write results to output file
        if isempty(outputFolder)
            writeXMLresults(myPath, '', myCQN, U, X, meanRT, R, [], RT_CDF, [], verbose );
        else
            outPath = [outputFolder, '/', shortNames{j}]; 
            writeXMLresults(outPath, '', myCQN, U, X, meanRT, R, [], RT_CDF, [], verbose );
        end
    end
end