function LINEserver(config_file)
% LINEserver(A) configures the LINE server (since v0.5). 
% It reads the LINE configuration from the configuration file A
%
% Parameters:
% config_file:  filepath of the configuration file
% 
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


import java.net.*;
import java.io.*;
import java.lang.StringBuilder;


%% Read parameters from config file
props = getPropsConfFile(config_file);
[portNumber, maxIter, maxJobSize, verbose, parallel, timeoutConn, RT, RTrange, solver ] = parseProps(props);


% init communication protocol - persists over all connections    
lp = LINEprotocolXML(maxIter,parallel,RT,RTrange,solver,verbose);

%% Establish connection on specified port
try 
    serverSocket = ServerSocket(portNumber);
catch 
    disp(['Could not listen on port: ', int2str(portNumber) ]);
    return;
end
disp('LINE is running.');
disp(['Listening on port ', int2str(portNumber),'.']);


%% Accept client connections
terminateLINE = 0;
numConns = 0; % connection counter
%timeoutConn = 30; %connection timeout
interCheckTimeConn = 2; %connection interval to check input
while terminateLINE == 0
    try 
        clientSocket = serverSocket.accept();
    catch 
        disp('Socket accept failed.');
        return;
    end
    out = PrintWriter(clientSocket.getOutputStream(), true);
    in = BufferedReader(InputStreamReader(clientSocket.getInputStream()));
    numConns = numConns + 1;

    out.println('LINE READY');
    out.flush();
    disp(['Connection #',int2str(numConns),' established']);
    disp('LINE READY');

    % parameters
    timeout = 60;
    pendingJobs = -1;       % number of pending Jobs
    pendingJobsList = [];
    interCheckTime = 0.5;   % time between check of job state


    %% communicate with the client
    inputLine = in.readLine();
    close = 0;
    maxLines = maxJobSize;
    while ~isempty(inputLine) && close == 0%readLine waits for written input        
        totalLines = {inputLine};
        tstart = tic;
        numLines = 0;
        while in.ready() && numLines < maxLines
            innerInputLine = in.readLine();
            totalLines{end+1,:} = innerInputLine;
            numLines = numLines + 1;
            if toc(tstart) > timeout
                break
            end
        end
        if ~isempty(totalLines)
            [outputLines, lp] = lp.processInput(totalLines);
            terminateLINE = 0;
            for j = 1:size(outputLines,1)
                outputLine = outputLines{j,1};
                out.println(outputLine);
                out.flush();
                if strcmp(outputLine, 'Closing connection') %close connection
                    close = 1;
                end
                if strcmp(outputLine, 'Quitting LINE') % quit the break server
                    terminateLINE = 1;
                end


            end
        else
            terminateLINE = 1;
        end
        
        if terminateLINE + close >= 1
            if terminateLINE == 1
                disp('Preparing to quit LINE. Waiting for outstanding jobs.');
            else
                disp('Preparing to close connection to LINE. Waiting for outstanding jobs.');
            end
            n = size(lp.myLINE.myJobs,1);
            %update pending jobs 
            addJobs = n - size(pendingJobsList,1);
            pendingJobsList = [pendingJobsList; ones(addJobs,1)];
            a = find(pendingJobsList == 1);
            if size(a,1) > 0
                outputLine = 'Waiting for outstanding jobs to complete';
                out.println(outputLine);
            end
            for j = 1:size(a,1)
                if ~strcmp(lp.myLINE.myJobs{a(j)}.State,'finished')
                    disp(['Waiting for job ',int2str(a(j)),' of ',int2str(n),' to complete']);
                    wait(lp.myLINE.myJobs{a(j)});
                end
                disp(['Job ',int2str(a(j)),' completed.']);
                filenames = lp.myLINE.jobTasks{a(j)};
                filenamesRE = lp.myLINE.jobTaskREs{a(j)};
                if isempty(lp.myLINE.myJobs{a(j)}.Tasks(1).Error)
                    for k = 1:size(filenames,1);
                        outputLine = ['MODEL ',filenames{k},' ',filenamesRE{k},' SOLVED'];
                        out.println(outputLine);
                    end
                else
                    for k = 1:size(filenames,1);
                        outputLine = ['ERROR: Error when solving MODEL ',filenames{k},' ',filenamesRE{k}];
                        out.println(outputLine);
                    end
                    outputLine = ['ERROR: ', lp.myLINE.myJobs{a(j)}.Tasks(1).Error.message];
                    out.println(outputLine);
                    for l = 1:length(lp.myLINE.myJobs{a(j)}.Tasks(1).Error.stack)
                        outputLine = ['ERROR: Error in line ', int2str(lp.myLINE.myJobs{a(j)}.Tasks(1).Error.stack(l).line), ' of LINE script ', lp.myLINE.myJobs{a(j)}.Tasks(1).Error.stack(l).name];
                        out.println(outputLine);
                    end
                end
                out.flush();
            end
            disp('All outstanding jobs completed.');
            if terminateLINE == 1
                % indicate that LINE stops
                outputLine = 'LINE STOP';
            else
                % indicate that LINE closes the connection
                outputLine = 'LINE CLOSED';
            end
            out.println(outputLine);
                out.flush();
                disp(outputLine);
            break; 
        end

        if pendingJobs == -1
            % first time check
            pendingJobs = size(lp.myLINE.myJobs,1);
            pendingJobsList = ones(pendingJobs,1);
        else
            % any other case
            n = size(lp.myLINE.myJobs,1);
            addJobs = n - size(pendingJobsList,1);
            pendingJobs = pendingJobs + addJobs;
            pendingJobsList = [pendingJobsList; ones(addJobs,1)];
        end

        while ( ~in.ready() && pendingJobs > 0 )
            a = find(pendingJobsList == 1);
            for j = 1:size(a,1)
                if strcmp(lp.myLINE.myJobs{a(j)}.State,'finished')
                    filenames = lp.myLINE.jobTasks{a(j)};
                    filenamesRE = lp.myLINE.jobTaskREs{a(j)};
                    if isempty(lp.myLINE.myJobs{a(j)}.Tasks(1).Error)
                        for k = 1:size(filenames,1);
                            outputLine = ['MODEL ',filenames{k},' ',filenamesRE{k},' SOLVED'];
                            out.println(outputLine);
                        end
                    else
                        for k = 1:size(filenames,1);
                            outputLine = ['ERROR: Error when solving MODEL ',filenames{k},' ',filenamesRE{k}];
                            out.println(outputLine);
                        end
                        outputLine = ['ERROR: ', lp.myLINE.myJobs{a(j)}.Tasks(1).Error.message];
                        out.println(outputLine);
                        for l = 1:length(lp.myLINE.myJobs{a(j)}.Tasks(1).Error.stack)
                            outputLine = ['ERROR: Error in line ', int2str(lp.myLINE.myJobs{a(j)}.Tasks(1).Error.stack(l).line), ' of LINE script ', lp.myLINE.myJobs{a(j)}.Tasks(1).Error.stack(l).name];
                            out.println(outputLine);
                        end
                    end
                    out.flush();
                    pendingJobsList(a(j)) = 0;
                    pendingJobs = pendingJobs - 1;
                end

            end
            pause(interCheckTime);
        end
        %inputLine = in.readLine();
        if terminateLINE == 0 && close == 0 
            % small pause to wait for next line
            pause(0.5);
            tstart = tic;
            while ~in.ready()
                pause(interCheckTimeConn);
                if toc(tstart) > timeoutConn
                    disp('Connection timeout')
                    close = 1;
                    break;
                end
            end
            inputLine = in.readLine();
        end
    end
    % clean up by closing connections
    disp(['Closing connection #', int2str(numConns)]);
    out.close();
    in.close();
    clientSocket.close();
    % clean jobs 
    lp.myLINE = lp.myLINE.clean();
end
% close cluster if open
lp.myLINE = lp.myLINE.closeCluster();
serverSocket.close();
end