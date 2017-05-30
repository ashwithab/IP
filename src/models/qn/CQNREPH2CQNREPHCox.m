function myCQNCox = CQNREPH2CQNREPHCox(myCQN, resetRules)
% B = CQNRE2CQNRECOX(A) transforms a CQNREPH model A (exponential service times) 
% into its equivalent representation as a CQNREPHCOX model B (Coxian service times) 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

if nargin < 2
    resetRules = cell(myCQN.E,myCQN.E);
    for i = 1:myCQN.E
        for j = [1:i-1 i+1:myCQN.E]
            resetRules{i,j} = 'fullReset';
        end
    end
end
    
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
myCQNCox = CQNREPHCox(myCQN.M, myCQN.K, myCQN.E, myCQN.N, myCQN.ENV, myCQN.S, mu, phi, myCQN.sched, myCQN.P, myCQN.NK, myCQN.refNodes, resetRules, myCQN.nodeNames,myCQN.classNames);
