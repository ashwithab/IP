function myCQNCox = CQNRE2CQNRECox(myCQN)
% B = CQNRE2CQNRECOX(A) transforms a CQNRE model A (exponential service times) 
% into its equivalent representation as a CQNRECOX model B (Coxian service times) 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.
    
mu = cell(myCQN.E, myCQN.M, myCQN.K);
phi = cell(myCQN.E, myCQN.M, myCQN.K);
for e = 1:myCQN.E
    for i = 1:myCQN.M
        for k = 1:myCQN.K
            mu{e,i,k} = myCQN.rates{e}(i,k);
            phi{e,i,k} = 1;
        end
    end
end
myCQNCox = CQNRECox(myCQN.M, myCQN.K, myCQN.E, myCQN.N, myCQN.ENV, myCQN.S, mu, phi, myCQN.sched, myCQN.P, ...
                            myCQN.NK, myCQN.classMatch, myCQN.refNodes, myCQN.resetRules, myCQN.nodeNames,myCQN.classNames, myCQN.adhocResetRules);
