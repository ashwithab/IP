function myCQNCox = CQN2CQNCox(myCQN)
% B = CQN2CQNCOX(A) transforms a CQN model A (exponential service times) 
% into its equivalent representation as a CQNCOX model B (Coxian service times) 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

mu = cell(myCQN.M, myCQN.K);
phi = cell(myCQN.M, myCQN.K);
for i =1:myCQN.M
    for k = 1:myCQN.K
        mu{i,k} = myCQN.rates(i,k);
        phi{i,k} = 1;
    end
end
S = myCQN.S;

myCQNCox = CQNCox(myCQN.M, myCQN.K, myCQN.N, S, mu, phi, myCQN.sched, myCQN.P, myCQN.NK, myCQN.classMatch, myCQN.refNodes, myCQN.nodeNames,myCQN.classNames);
