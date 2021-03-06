function RT = CQN_RE_SCB_fluid_ps_RT(myCQN, max_iter, delta_max, ymean_emb, piemb, RTrange, verbose)
% CQN_RE_FLUID_PS_RT F(A) computes the overall response time distribution
% of the original classes in the Closed multi-class queueing network A
% wirh Coxian processing times, in a Random Environment (CQNRECox). 
% 
% Parameters: 
% myCQN:        CQNRECox object describing the network
% max_iter:     maximum number of iterations
% delta_max:    max change in the mean vector accepted for termination
% ymean_emb:    stationary state of the QN obtained via a fluid analysis
%               this state is used as the initial for response time analysis
% piemb:        stationary distribution of the Random environment
%               original classes (artificial classes are created for analysis purposes)
% RTrange:      percetiles of the response distribution requested (optional)
% verbose:      1 for screen output (optional) 
% 
% Returns:
% RT:           cell array containing the overall response time
%               distribution for each original class in the QN
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

M = myCQN.M;    %number of stations
K = myCQN.K;    %number of classes
E = myCQN.E;    %number of stages
N = myCQN.N;    %population
%origK = size(classMatch,1);
origK = myCQN.C;

RTall = cell(E,1);
%separate analysis for each stage 
nonNullE = find(piemb>0);
for e = nonNullE
    % build CQN for stage e
    Lambda = cell(M,K);
    Pi = cell(M,K);
    for i = 1:M
        for k = 1:K
            Lambda{i,k} = myCQN.mu{e,i,k};
            Pi{i,k} = myCQN.phi{e,i,k};
        end
    end
    
    %stageCQN = CQNCox(M, K,     N, myCQN.S{e}, Lambda, Pi, myCQN.sched, myCQN.P{e}, myCQN.NK, myCQN.classMatch, myCQN.refNodes, myCQN.nodeNames, myCQN.classNames);
    stageCQN = CQNCoxSCB (M, K, N, myCQN.S{e}, myCQN.V, Lambda, Pi, myCQN.sched, myCQN.P{e}, myCQN.NK, myCQN.classMatch, myCQN.refNodes, myCQN.nodeNames, myCQN.classNames);
    %RTall{e} = CQN_fluid_ps_RT(stageCQN, max_iter, delta_max, ymean_emb{end,e}, classMatch, [], verbose);
    %RTall{e} = CQN_fluid_ps_RT(stageCQN, max_iter, delta_max, ymean_emb{end,e}, [], verbose);
    RTall{e} =  CQN_SCB_fluid_ps_RT(stageCQN, max_iter, delta_max, ymean_emb{end,e}, [], verbose);
end


totRT = cell(origK,2); 
for k = 1:origK
    fullTgrid = []; 
    for e = nonNullE
        fullTgrid = [fullTgrid; RTall{e}{k,1}];
    end
    fullTgrid = sort(fullTgrid);
    maxT = max(fullTgrid); %maximum observed time
    fullRT = cell(E,1); 
    for e = nonNullE
        % add an observation at maxT = 1
        if max(RTall{e}{k,1}) < maxT
            RTall{e}{k,1} = [RTall{e}{k,1}; maxT];
            RTall{e}{k,2} = [RTall{e}{k,2}; 1];
        end
        fullRT{e} = interp1q(RTall{e}{k,1},RTall{e}{k,2},fullTgrid); 
    end

    totRT{k,1} = fullTgrid;
    totRT{k,2} = 0;
    for e = nonNullE
        totRT{k,2} = totRT{k,2} + fullRT{e}*piemb(e); 
    end
end
RT = totRT;

if verbose > 1
    for k = 1:origK
        a = ( RT{k,2}(1:end-1) + RT{k,2}(2:end) )/2;
        meanRT = sum(diff(RT{k,1}).*(1-a));
        disp(['Mean response time class ', int2str(k),': ', num2str(meanRT)]);
    end
end

% determine the value of the  percentiles requested (RTrange)
for k = 1:origK
    if ~isempty(RTrange) && RTrange(1) >=0 && RTrange(end) <=1
        percRT = interp1q(RT{k,2}, RT{k,1}, RTrange); 
        RT{k,1} = percRT;
        RT{k,2} = RTrange;
    end
end

return



function [value,isterminal,direction] = events(t,y)
    value = sum(y(idxN));
    isterminal = 1;
    direction = 0;
end


end

