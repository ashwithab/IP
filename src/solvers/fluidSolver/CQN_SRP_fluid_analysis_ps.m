function [ode_h,q_indices] = CQN_SRP_fluid_analysis_ps(N, Mu, Phi, P, S, Sp, W)
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
Mp = length(Sp);    % number of passive stations
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

% indicator of active resource/class that use passive resources
pasInd = zeros(M, K); 
for i = 1:M
    for k = 1:K
        pasInd(i,k) = sum(W(i,:,k))>0; 
    end
end

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
    %nP = sum(reshape( x(q_indicesP(1,1):end), Mp, K ),2); % total number of jobs in each passive station
    nP = x(q_indicesP(1):end); % total number of jobs in each passive station
    % build variable rate vector 
    for i = 1:M
        idxIni = q_indices(i,1);
        idxEnd = q_indices(i,K) + Kic(i,K) - 1;
        if S(i) == sum(N)
            n(i) = 1;
        else
            n(i) = sum( x(idxIni:idxEnd) );
        end
        if n(i) > 0
            rates(idxIni:idxEnd) = x(idxIni:idxEnd)/n(i) * min(n(i),S(i));
            if sum(pasInd(i,:)) > 0 
                for k = find(pasInd(i,:)>0)
                    for w = find(W(i,:,k)>0)
                        rates(q_indices(i,k):q_indices(i,k)+Kic(i,k)-1) = ...
                            min( rates(q_indices(i,k):q_indices(i,k)+Kic(i,k)-1), x(q_indices(i,k):q_indices(i,k)+Kic(i,k)-1)/nP(w) * min(nP(w),Sp(w)) ); 
                            %min( rates(q_indices(i,k):q_indices(i,k)+Kic(i,k)-1), x(q_indicesP(w,k))/nP(w) * min(nP(w),Sp(w)) ); 
                    end
                end
            end
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
                        
                        % jump in passive resources - remove currently used
                        if pasInd(i,c) > 0
                            for w = find(W(i,:,c)>0)
                                %jump(q_indicesP(w,c)) = jump(q_indicesP(w,c)) - 1; 
                                jump(q_indicesP(w)) = jump(q_indicesP(w)) - 1; 
                            end
                        end
                        % jump in passive resources - add newly used
                        jump(xjl) = jump(xjl) + 1; %type l job starts in stat j
                        if pasInd(j,l) > 0
                            for w = find(W(j,:,l)>0)
                                %jump(q_indicesP(w,l)) = jump(q_indicesP(w,l)) + 1; 
                                jump(q_indicesP(w)) = jump(q_indicesP(w)) + 1; 
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

% q_indicesP = zeros(Mp,K); % passive indices
% for i = 1:Mp
%     for c = 1:K
%         q_indicesP(i,c) = cumsum;
%         cumsum = cumsum + 1; 
%     end
% end

q_indicesP = zeros(Mp,1); % passive indices
for i = 1:Mp
    q_indicesP(i) = cumsum;
    cumsum = cumsum + 1; 
end


nx = cumsum - 1; % length of state space

% determines all the jumps, and saves them for later use
all_jumps = ode_jumps_new();
% determines a vector with the fixed part of the rates,
% and defines the indexes that correspond to the events that occur
[rateBase, eventIdx] = getRateBase();

end
