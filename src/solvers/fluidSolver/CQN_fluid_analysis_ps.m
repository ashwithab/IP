function [ode_h,q_indices] = CQN_fluid_analysis_ps(N, Mu, Phi, P, S)
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

M = length(S);    % number of stations
K = size(Mu,2);   % number of classes

match = zeros(M,K); % indicates whether a class is served at a station
for i = 1:M
    for c = 1:K
        %match(i,c) = sum( P(:,(i-1)*K+c) ) > 0;
        %changed to consider rows instead of colums, for response time
        %analysis (first articial class never returns to delay node)
        match(i,c) = sum( P((i-1)*K+c,:) ) > 0;
    end
end

function xj = get_index(j,k)
    % n is the state vector
    % j is the queue station index
    % k is the class index
    % RETURNS THE INDEX of the queue-length element xi! % in the state description
    xj = 1;
    for z = 1 : (j-1)
        for y = 1:K
            xj = xj + Kic(z,y);
        end
    end
    for y = 1:k-1
        xj = xj + Kic(j,y);
    end

end

function rates = ode_rates(x)
    rates = [];
    n = zeros(1,M); % total number of jobs in each station
    for i = 1:M
        for c = 1:K
            xic = q_indices(i,c);
            n(i) = n(i) + sum( x(xic:xic+Kic(i,c)-1 ) );
        end
        if S(i) == sum(N)
            n(i) = 1;
        end
    end



    for i = 1 : M           %transition rates for departures from any station to any other station
        for c = 1:K         %considers only transitions from the first service phase (enough for exp servers)
            if match(i,c)>0
            xic = q_indices(i,c);
            for j = 1 : M
                for l = 1:K
                    if P((i-1)*K+c,(j-1)*K+l) > 0 
                    for k = 1:Kic(i,c)
                        %pure ps + fcfs correction
                        if x(xic+k-1) > 0 && n(i) > S(i)
                            rates = [rates; Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k) * x(xic+k-1)/n(i) * S(i);]; % f_k^{dep}
                        elseif x(xic+k-1) > 0
                            rates = [rates; Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k) * x(xic+k-1);]; % f_k^{dep}
                        else
                            rates = [rates; 0;]; % f_k^{dep}
                        end
                    end
                    end
                end
            end
            end
        end
    end

    for i = 1 : M           %transition rates for "next service phase" (phases 2...)
        for c = 1:K
            if match(i,c)>0
            xic = q_indices(i,c);
            for k = 1 : (Kic(i,c) - 1)
                if x(xic+k-1) > 0 
                    rates = [rates; (1-Phi{i,c}(k))*Mu{i,c}(k)*x(xic+k-1)/n(i)];
                else
                    rates = [rates; 0 ]
                end
            end
            end
        end
    end

end

function d = ode_jumps(x)
    d = [];         %returns state changes triggered by all the events
    for i = 1 : M   %state changes from departures in service phases 2...
        for c = 1:K
            if match(i,c)>0
            xic = q_indices(i,c);
            for j = 1 : M
                for l = 1:K
                    if P((i-1)*K+c,(j-1)*K+l) > 0 
                    xjl = q_indices(j,l);
                    for k = 1 : Kic(i,c)
                        jump = zeros(length(x),1);
                        jump(xic) = jump(xic) - 1; %type c in stat i completes service
                        jump(xjl) = jump(xjl) + 1; %type c job starts in stat j
                        d = [d jump;];
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
                jump = zeros(length(x),1);
                jump(xic+k-1) = jump(xic+k-1) - 1;
                jump(xic+k) = jump(xic+k) + 1;
                d = [d jump;];
            end
            end
        end
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
    %rates = zeros(size(rateBase));
    rates = zeros(nx,1);
    n = zeros(1,M); % total number of jobs in each station
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
        end
    end
    rates = rates(eventIdx);
    %built effective rate vector
    rates = rateBase.*rates;
end
 
function jumps = ode_jumps_new()
    jumps = [];         %returns state changes triggered by all the events
    for i = 1 : M   %state changes from departures in service phases 2...
        for c = 1:K
            if match(i,c)>0
            xic = q_indices(i,c);
            for j = 1 : M
                for l = 1:K
                    if P((i-1)*K+c,(j-1)*K+l) > 0 
                    xjl = q_indices(j,l);
                    for k = 1 : Kic(i,c)
                        jump = zeros( sum(sum(Kic)), 1 );
                        jump(xic+k-1) = jump(xic+k-1) - 1; %type c in stat i completes service
                        jump(xjl) = jump(xjl) + 1; %type c job starts in stat j
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
                jump = zeros( sum(sum(Kic)), 1 );
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
nx = cumsum - 1;

% determines all the jumps, and saves them for later use
all_jumps = ode_jumps_new();
% determines a vector with the fixed part of the rates,
% and defines the indexes that correspond to the events that occur
[rateBase, eventIdx] = getRateBase();

end
