function [QN, XN, runtime] = CQN_jmt(myCQN, ~, ~, verbose)
% Q = CQN_JMT(myCQN) solves the QN by the JMT simulator
%
% Parameters:
% myCQN:      CQN model to analyze
% delta_max:  max change in the mean vector accepted for termination
% y_init:        initial state
%
% Output:
% QN:         expected number of jobs for each class in each station (fixed point)
% X:          expected throughout for each class (fixed point)
%
% Copyright (c) 2015-2017, Imperial College London
% All rights reserved.

M = myCQN.M;    %number of stations
K = myCQN.K;    %number of classes
rates = myCQN.rates;
P = myCQN.P;
S = myCQN.S; % number of servers
NK = myCQN.NK;  % initial population per class
Ktrue = nnz(NK); % classes that are not artificial

jmtPath = fileparts(which('JMT.jar'));
%% initialization
model = Model('model',jmtPath);

for i=1:M
    switch myCQN.sched{i}
        case 'inf'
            node{i} = DelayStation(model, myCQN.nodeNames{i});
        case 'ps'
            node{i} = QueueingStation(model, myCQN.nodeNames{i}, QueuePolicy.PS);
            node{i}.setNumServers(myCQN.S(i));
        case 'fcfs'
            node{i} = QueueingStation(model, myCQN.nodeNames{i}, QueuePolicy.NP);
            node{i}.setNumServers(myCQN.S(i));
    end
end



for k = 1:K
    if k<=Ktrue
        jobclass{k} = ClosedClass(model, myCQN.classNames{k}, NK(k), node{myCQN.refNodes(k)}, 0);
    else
        % if the reference node is unspecified, as in artificial classes,
        % set it to the first node where the rate for this class is
        % non-null
        jobclass{k} = ClosedClass(model, myCQN.classNames{k}, NK(k), node{min(find(rates(:,k)))}, 0);
    end
    for i=1:M
        if myCQN.rates(i,k)>0
            node{i}.setLoadIndepService(jobclass{k}, Exp(myCQN.rates(i,k)));
        else
            node{i}.setLoadIndepService(jobclass{k}, Exp(1)); % gets ignored anyway
        end
    end
end

% numberOfForkStations = 0;
% for i=1:M
%     for k=1:K
%         rowSum = sum(P((i-1)*K+k,:));
%         if rowSum > 1
%             numberOfForkStations = numberOfForkStations + 1; 
%         end
%     end
% end
% 
% numberOfForkJoinStations = numberOfForkStations * 2;
% 
% forkArray = [];
% toFork = [];
% for i=1:M
%     for k=1:K
%         rowSum = sum(P((i-1)*K+k,:));
%         if rowSum > 1 
%             forkArray = [forkArray (i)];
%            for p=1:numberOfForkStations 
%                node{M+p} = ForkStation(model, 'Fork');
%                
% 
% %                model.addLink(node{k},node{M+p});
%                model.addLink(node{i},node{M+p});
% 
%                for j=1:M
%                  if rowSum > 1 && P((i-1)*K+k,(j-1)*K+k) == 1
%                     model.addLink(node{M+p},node{j});
%                     P((i-1)*K+k,(j-1)*K+k) = 0;
%                     toFork = [toFork (j)];
%                     setTasksPerLink(node{M+p},1.0);
%                     node{M+p}.setRouting(jobclass{k}, 'Probabilities', node{j}, 1.0);
%                  end  
%               end
%            end
%         end
% 
% 
%     end
% end
% 
% joinArray = [];
% for j=1:M
%     for k = 1:K
%         columnSum = sum(P(:,(j-1)*K+k));
%         if columnSum < -1
%             joinArray = [joinArray (j)];
%             for p=1:numberOfForkStations
%                 node{M+numberOfForkStations+p} = JoinStation(model, 'Join');
%                 
%                 model.addLink(node{M+numberOfForkStations + p}, node{j});
%                 for i=1:M
%                     if columnSum < -1 && P((i-1)*K+k,(j-1)*K+k) == -1
%                         P((i-1)*K+k,(j-1)*K+k) = 0;
%                         model.addLink(node{i}, node{M+numberOfForkStations + p});
%                     end
%                 end
%             end
%         end
%         
%             
%     end
% end
% 
% 
% 
% x = zeros(M,1);
% for i=1:numberOfForkJoinStations
%     P = [P,x];
% end
% 
% y = zeros(1,M+numberOfForkJoinStations);
% for i=1:numberOfForkJoinStations
%     P = [P;y];
% end
% 
% for i=1:length(forkArray)
%        P(forkArray(i),M+i) = 1;
%        P(M+i,toFork(2*i-1)) = 1;
%        P(M+i,toFork(2*i)) = 1;
% end
% 
% 
% for i=1:length(joinArray)
%         P(M+numberOfForkStations+i, joinArray(i)) = 1;
%         P(toFork(2*i-1),M+numberOfForkStations+i) = 1;
%         P(toFork(2*i),M+numberOfForkStations+i) = 1;   
% end
% 
% disp(P);
% 
% 
% M = M + numberOfForkJoinStations;

for i=1:M
    for k = 1:K
        rowSum = sum(P((i-1)*K+k,:));
            warning(['Routing probabilities do not sum to 1.0. ', ...
                 sprintf('Problem affects station %d and class %d. ',i,k), ...
                 'Scaling routing matrices to fix the problem.']);
        if rowSum == 0
            P((i-1)*K+k,(i-1)*K+k) = -1;
        end
        if rowSum > 1
            P((i-1)*K+k,:) = P((i-1)*K+k,:) / rowSum;
        end
    end
end


for i=1:M
    for j=1:M
        for k = 1:K
            for c = 1:K
                % routing matrix for each class
                myP{k,c}(i,j) = P((i-1)*K+k,(j-1)*K+c);
            end
        end
    end
end
  


model.linkNetwork(node, jobclass, myP) ;
for r=1:K
    if nargout > 1
        X{r} = PerfIndex(Perf.SysTput, jobclass{r}, node{i});
        model.addMeasure(X{i,r});
    end
    for i=1:M
        Q{i,r} = PerfIndex(Perf.NumCust, jobclass{r}, node{i});
        model.addMeasure(Q{i,r});
    end
end







%% solution
Tstart = tic;
model.runSimulation(1e5);
runtime = toc(Tstart);
results = model.getResults();

if verbose > 0
    
    fprintf('JMT simulation completed in %f sec\n',runtime);
end

% output
for r=1:K
    for i=1:M
        if nargout > 1
            XN(r)=X{r}.get(results);
        end
        QN(i,r)=Q{i,r}.get(results);
    end
end

return
end