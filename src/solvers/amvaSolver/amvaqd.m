function [Q,X]=amvaqd(L,N,ga,be,Q0,tol)
% AMVAQD implements the QD-AMVA method proposed in the paper
% "QD-AMVA: Evaluating Systems with Queue-Dependent Service
% Requirements", by G. Casale, J. F. Perez, and W. Wang, accepted 
% to IFIP Performance 2015. 
% 
% Parameters:
% L:    MxR double array with the mean service demand of class-r users in 
%       station i, for r in {1,..,R} and i in {1,...,M}
% N:    1xR integer array with the number of users of each class
% ga:   Mx1 handle array with the handles of the gamma functions that
%       corresponds to each station
% be:   MxR handle array with the handles of the beta functions that
%       corresponds to each station and each user class
% tol:  stopping criteria - maximum difference in queue length between two 
%       consecutive iterations
% 
% Copyright (c) 2015-2017, Imperial College London 
% All rights reserved.

[M,R]=size(L);

if nargin < 5 || isempty(Q0)
    Q = rand(M,R);
    Q = Q ./ repmat(sum(Q,1),size(Q,1),1) .* repmat(N,size(Q,1),1);
else
    Q=Q0;
end

if nargin < 6
    tol = 1e-6;
end

delta  = (sum(N) - 1) / sum(N);
deltar = (N - 1) ./ N;

Q_1 = Q*10;

while max(max(abs(Q-Q_1))) > tol
    Q_1 = Q;
    for k=1:M
        for r=1:R
            Ak{r}(k) = 1 + delta * sum(Q(k,:));
            Akr(k,r) = 1 + deltar(r) * Q(k,r);
        end
    end
    
    %    Q
    for r=1:R
        g = ga(Ak{r});
        b = be(Akr);
        for k=1:M
            C(k,r) = L(k,r) * g(k) * b(k,r) * (1 + delta * sum(Q(k,:)));
        end
        
        X(r) = N(r) / sum(C(:,r));
        
        for k=1:M
            Q(k,r) = X(r) * C(k,r);
        end
    end
end

end
