function [QN, X, runtime] = CQN_amvaqd(myCQN, delta_max, yinit, verbose)
% Q = CQN_AMVAQD(myCQN) solves the QN by the AMVAQD method
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
S = myCQN.S;
NK = myCQN.NK;  % initial population per class

%% initialization
if nargin < 2 || isempty(delta_max); delta_max = 1e-6; end
% queue-dependent functions to capture multi-server and delay stations
gamma = @(n) multi_core(n,S);
beta = @(n) ones(M,K); 

% determine expected demands
L = zeros(M,K); 
for k = 1:K
    eventualVisit = zeros(1,M); 
    % routing matrix for each class
    myP = P(k:K:end,k:K:end); 
    idxNR = [1:myCQN.refNodes(k)-1 myCQN.refNodes(k)+1:M]; % no reference nodes
    Ptrans = myP(idxNR,idxNR); %transient transition matrix for non-reference nodes
    eventualVisit(idxNR) = myP(myCQN.refNodes(k),idxNR) * inv( eye(size(Ptrans)) - Ptrans );
    eventualVisit(myCQN.refNodes(k)) = 1; % reference node
    nonNullNodes = eventualVisit > 0;
    L(nonNullNodes,k) = eventualVisit(nonNullNodes)' ./ rates(nonNullNodes,k); 
end

Tstart = tic;
[QN,X]=amvaqd(L, NK', gamma, beta, yinit, delta_max);
runtime = toc(Tstart);

if verbose > 0
    fprintf('QD-AMVA analysis completed in %f sec\n',runtime);
end

return
end