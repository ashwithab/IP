%% EXAMPLE_PMIF_1 exemplifies the use of LINE to analize PMIF models. 
%
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.

clear;
%% obtain CQN representation from PMIF description
myCQN = PMIF2CQN(fullfile(pwd,'data','PMIF','pmif_example_closed.xml'), 1);

if ~isempty(myCQN)
    % compute performance measures
    max_iter = 1000;
    delta_max = 0.01;
    RT = 1;
    RTrange = [0.01:0.01:0.99]'; 
    solver = 2; % amva-qd
    verbose = 1;
    [Q, U, R, X, ~, RT_CDF, ~] = CQN_analysis(myCQN, [], [], [], max_iter, delta_max, RT, RTrange, solver, verbose)
end

