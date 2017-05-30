function r = multi_core(n,c)
% Copyright (c) 2016, Imperial College London 
% All rights reserved.


M = length(n);
r = zeros(1,M);

for i = 1:M
    if c(i) == -1 % delay server
        r(i) = 1/n(i);
    else % regular server with c(i) servers
        r(i) = 1./approximate(n(i),c(i),20);
    end
end

end

function value = approximate(x,y,k)
    value = - ((-x)*exp(-k*x) -y*exp(-k*y)) / (exp(-k*x) + exp(-k*y));
end