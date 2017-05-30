function [mu, phi] = getCoxian(mean, scv, n)
% COXIAN finds a coxian representation (mu,phi) with specified mean and scv
% mu:  nx1 vector of rates
% phi: nx1 vector of completion probs
% n: number of phases (optional parameter)

if nargin == 2
    if scv == 1
        disp('exponential case')
        n = 1;
        mu = 1/mean;
        phi = 1;
    elseif scv < 1 
        disp('Erlang case')
        n = ceil(1/scv);
        disp([int2str(n),' phases']);
        lambda = n/mean;
        mu = lambda*ones(n,1); 
        phi = zeros(n,1);
        phi(n) = 1;
    else
        disp('Hyper-exponential case - 2 phases')
        n = 2;
        %find hyper expo representation (alpha1,mu1,mu2) - Whitt82
        %alpha1 = ( 1 + sqrt((scv-1)/(scv+1)) )/2;
        %mu1 = 2*alpha1/mean;
        %mu2 = 2*(1-alpha1)/mean;
        
        % validation
        %b = [alpha1 1-alpha1]
        %B = [-mu1 0 ; 0 -mu2]
        %meanHE = b*inv(-B)*ones(n,1)
        %meanHE2 = 2*b*inv(-B)^2*ones(n,1);
        %scvHE = meanHE2/meanHE^2-1
        
        
        
        %transform hyper expo into coxian
        mu = zeros(n,1);
        %mu(1) = mu1/alpha1;
        %%mu(2) = mu2 + mu1 -mu1/alpha1;
        %mu(2) = mu2 - mu1/alpha1;
        
        %mu(1) = mu1;
        %mu(2) = mu2 - mu1;
        
        %mu(1) = mu2;
        %mu(2) = mu1 - mu2;
        
        mu(1) = 2/mean;
        %mu(2) = scv*mu(1)/( mu(1)^2 - scv );
        mu(2) = mu(1)/( 2*scv );
        phi = zeros(n,1);
        phi(1) = 1 - mu(2)/mu(1);
        %phi(1) = 1-alpha1;
        phi(2) = 1;
    end
elseif nargin == 3
    if scv == 1
        disp('exponential case - %d phases',n)
    end
end

%test 
%PH represetation of coxian
a = [1 zeros(1,n-1)];
A = zeros(n);
for i = 1:n-1
    A(i,i) = -mu(i);
    A(i,i+1) = mu(i)*(1-phi(i));
end
A(n,n) = -mu(n);

%validation
%meanCox = a*inv(-A)*ones(n,1)
%meanCox2 = 2*a*inv(-A)^2*ones(n,1);
%scvCox = meanCox2/meanCox^2-1
%errorMean = (mean-meanCox)/mean
%errorScv = (scv-scvCox)/scv