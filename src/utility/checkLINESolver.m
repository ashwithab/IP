function [solver,RT] = checkLINESolver(solver,RT,myCQN)
% CHECKLINESOLVER checks whether the selected solver is adequate given the 
% required output (response time distribution) and the characteristics
% of the queueing network model to analyze. It also assigns the automatic 
% solver. 
%
% Parameters:
% solver:   solver originally selected
% RT:       1 if response-time distributions are to be computed, 0
%           otherwise
% myCQN:    CQN model to analyze
% 
% Copyright (c) 2012-2017, Imperial College London 
% All rights reserved.


%% define solver
if solver == 0  || strcmpi(solver,'AUTO') % 'AUTO'
    solver = 1; % set default solver to fluid
elseif solver == 2 || strcmpi(solver,'QD-AMVA') % 'QD-AMVA'
    if RT > 0 % response time distribution requested
        warning(sprintf(['Response time distribution requested with solver QD-AMVA. ', ...
                 '\t Solver QD-AMVA cannot compute response time distributions. ', ...
                 '\t Response time distributions will not be computed. ', ...
                 '\t To compute response time distributions please select AUTO or FLUID solvers. ']));
        RT = 0;
    end

    if myCQN.C ~= myCQN.K % class switching present
        warning(sprintf(['The queueing network features class-switching with solver QD-AMVA. ', ...
                 '\t Solver QD-AMVA cannot consider queueing networks with class-switching. ', ...
                 '\t Solver will be modified to FLUID (1) to consider the class-switching behavior. ']));
        solver = 1;
    end
elseif solver == 3  || strcmpi(solver,'JMT') % 'JMT'
        solver = 3;
        if RT > 0 % response time distribution requested
        warning(sprintf(['Response time distribution requested with solver JMT.\n', ...
                 '\t Solver JMT cannot compute response time distributions.\n', ...
                 '\t Response time distributions will not be computed.\n', ...
                 '\t To compute response time distributions please select AUTO or FLUID solvers. ']));
        RT = 0;
    end
elseif solver ~= 1
    warning(['Warning: Solver option ', solver, ' not recognized. ', ...
             'Using default solver: FLUID (1). ' ]);
    solver = 1;
end