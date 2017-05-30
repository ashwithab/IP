function [ode_h,q_indices] = CQN_SCB_fluid_analysis_ps(N, Mu, Phi, P, S, V)
% CQN_FLUID_ANALYSIS_PS provides the methods to perform the ODE 
% analysis of a Closed Multi-Class Queueing Network with Class Switching
% with Coxian Service Times (CQNCox). 
% More details on this type of queueing networks can be found 
% on the LINE documentation
%
% Parameters:
% N:    total number of jobs
% Mu:   service rates in each station (in each phase), for each stage
% Phi:  probability of service completion in each stage of the service 
%       process in each station, for each stage
% P:    routing matrix for each stage
% S:    number of servers in each station, for each stage
%
% Output:
% ode_h:        handler of the ODE system
% q_indices:    indices of each job class and station, in the state vector
% ode_jumps_h:  handler of the jumps in the ODE system
% ode_rates_h:  handler of the transition rates in the ODE system
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

M = length(S);      % number of stations
%Mp = length(Sp);    % number of passive stations
K = size(Mu,2);     % number of classes

match = zeros(M,K); % indicates whether a class is served at a station
for i = 1:M
    for c = 1:K
        %match(i,c) = sum( P(:,(i-1)*K+c) ) > 0;
        %changed to consider rows instead of colums, for response time
        %analysis (first articial class never returns to delay node)
        match(i,c) = sum( P((i-1)*K+c,:) ) > 0;
    end
end


B = zeros(M,K); % 1 in entry (i,r) if class r jobs block station i, 0 otherwise
useB = zeros(M,K); % 1 in entry (i,r) if class r jobs blocks ANOTHER station when executing in station i, 0 otherwise
for i = 1:M
    for k = 1:K
        B(i,k) = sum( V(:,i,k) ) > 0; 
        useB(i,k) = sum( V(i,:,k) ) > 0; 
    end
end

%S = zeros(M,R);

function [rateBase, eventIdx] = getRateBase()
    rateBase = zeros(size(all_jumps,2),1);
    eventIdx = zeros(size(all_jumps,2),1);
    rateIdx = 0;
    for i = 1 : M   %state changes from departures in service phases 2...
        for c = 1:K
            if match(i,c)>0
            for j = 1 : M
                for l = 1:K
                    if P((i-1)*K+c,(j-1)*K+l) > 0 
                    for k = 1 : Kic(i,c)
                        rateIdx = rateIdx + 1;
                        rateBase(rateIdx) = Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k);
                        eventIdx(rateIdx) = q_indices(i,c) + k - 1;
                    end
                    end
                end
            end
            end
        end
    end

    for i = 1 : M   %state changes from "next service phase" transition in phases 2...
        for c = 1:K
            if match(i,c)>0
            for k = 1 : (Kic(i,c) - 1)
                rateIdx = rateIdx + 1;
                rateBase(rateIdx) = (1-Phi{i,c}(k))*Mu{i,c}(k);
                eventIdx(rateIdx) = q_indices(i,c) + k - 1;
            end
            end
        end
    end        
end

function rates = ode_rates_new(x)
    rates = zeros(size(rateBase));
    n = zeros(1,M); % total number of jobs in each station
    % build variable rate vector 
    for i = 1:M
        if S(i) == sum(N)
            n(i) = 1;
        else
            n(i) = sum( x(q_indSstat{i}));  % sum only active jobs, not blocking jobs
        end
        if n(i) > 0
            rates(q_indSstat{i}) = x(q_indSstat{i})/n(i) * min(n(i), max(0,S(i)-sum(x(q_indBstat{i})) ) );
        end
    end
    rates = rates(eventIdx);
    %built effective rate vector
    rates = rateBase.*rates;
end
 
function jumps = ode_jumps_new()
    jumps = [];         %returns state changes triggered by all the events
    for i = 1:M   %state changes from departures in service phases 2...
        for c = 1:K
            if match(i,c)>0
            xic = q_indices(i,c);
            for j = 1:M
                for l = 1:K
                    if P((i-1)*K+c,(j-1)*K+l) > 0 
                    xjl = q_indices(j,l);
                    for k = 1 : Kic(i,c)
                        %jump = zeros( sum(sum(Kic)), 1 );
                        jump = zeros( nx, 1 );
                        jump(xic+k-1) = jump(xic+k-1) - 1; %type c in stat i completes service
                        
                        % jump in blocked resources - remove currently used
                        if useB(i,c) > 0
                            for w = find(V(i,:,c)>0)
                                jump(q_indices(w,c)) = jump(q_indices(w,c)) - 1; % blocking class has a single phase
                                %jump(q_indicesP(w)) = jump(q_indicesP(w)) - 1; 
                            end
                        end
                        
                        jump(xjl) = jump(xjl) + 1; %type l job starts in stat j
                        % jump in blocked resources - add newly used
                        if useB(j,l) > 0
                            for w = find(V(j,:,l)>0)
                                jump(q_indices(w,l)) = jump(q_indices(w,l)) + 1; 
                                %jump(q_indicesP(w)) = jump(q_indicesP(w)) + 1; 
                            end
                        end
                        
                        jumps = [jumps jump;];
                    end
                    end
                end
            end
            end
        end
    end

    for i = 1 : M   %state changes from "next service phase" transition in phases 2...
        for c = 1:K
            if match(i,c)>0
            xic = q_indices(i,c);
            for k = 1 : (Kic(i,c) - 1)
                %jump = zeros( sum(sum(Kic)), 1 );
                jump = zeros( nx, 1 );
                jump(xic+k-1) = jump(xic+k-1) - 1;
                jump(xic+k) = jump(xic+k) + 1;
                jumps = [jumps jump;];
            end
            end
        end
    end        
end

function diff = ode(t,x)
    diff = all_jumps*ode_rates_new(x);%rate of change in state x
end

ode_h = @ode;

q_indices = zeros(M,K); 
Kic = zeros(M,K);
cumsum = 1;
for i = 1 : M
    for c = 1:K
        q_indices(i,c) = cumsum;
        numphases = length(Mu{i,c});
        Kic(i,c) = numphases;
        cumsum = cumsum + numphases; 
    end
end

%q_indB = cell(M,K); % state vector indices for each station and class that cause blocking  
%q_indS = cell(M,K); % state vector indices for each station and class that does not cause blocking  
q_indBstat = cell(M,1); % state vector indices for each station and all classes that cause blocking  
q_indSstat = cell(M,1); % state vector indices for each station and all classes that does not cause blocking  

for i = 1:M
    q_indBstat{i} = [];
    q_indSstat{i} = [];
    for k = 1:K
        if B(i,k) > 0 
            %q_indB{i,k} = q_indices(i,k):q_indices(i,k)+Kic(i,k)-1;
            q_indBstat{i} = [q_indBstat{i} q_indices(i,k):q_indices(i,k)+Kic(i,k)-1];
        else
            %q_indS{i,k} = q_indices(i,k):q_indices(i,k)+Kic(i,k)-1;
            q_indSstat{i} = [q_indSstat{i} q_indices(i,k):q_indices(i,k)+Kic(i,k)-1];
        end
    end
end



nx = cumsum - 1; % length of state space

% determines all the jumps, and saves them for later use
all_jumps = ode_jumps_new();
% determines a vector with the fixed part of the rates,
% and defines the indexes that correspond to the events that occur
[rateBase, eventIdx] = getRateBase();

end
