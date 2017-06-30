function [P, gamma] = a2p_par(A, u, tol)
%Closely based on Laurens van der Maaten's d2p in matlab's t_SNE toolbox, 
%but for affinity matrices.


if ~exist('u', 'var') || isempty(u)
  u = 15;
end
if ~exist('tol', 'var') || isempty(tol)
  tol = 1e-4;
end

% Initialize some variables
n = size(A, 1);                     % number of instances
P = zeros(n, n);                    % empty probability matrix
gamma = ones(n, 1);                  % empty precision vector
logU = log(u);                      % log of perplexity (= entropy)

% Run over all datapoints
parfor i=1:n

  %         if ~rem(i, 500)
  %             disp(['Computed P-values ' num2str(i) ' of ' num2str(n) ' datapoints...']);
  %         end
  tempA = A(i,:);
  tempP = zeros(1,n);
  % Set minimum and maximum values for precision
  gammamin = -Inf;
  gammamax = Inf;
  
  % Compute the Gaussian kernel and entropy for the current precision
  [H, thisP] = Hgamma(tempA(1, [1:i - 1, i + 1:end]), gamma(i));
  
  % Evaluate whether the perplexity is within tolerance
  Hdiff = H - logU;
  tries = 0;
  while abs(Hdiff) > tol && tries < 50
    
    % If not, increase or decrease precision
    if Hdiff > 0
      gammamin = gamma(i);
      if isinf(gammamax)
        gamma(i) = gamma(i) * 2;
      else
        gamma(i) = (gamma(i) + gammamax) / 2;
      end
    else
      gammamax = gamma(i);
      if isinf(gammamin)
        gamma(i) = gamma(i) / 2;
      else
        gamma(i) = (gamma(i) + gammamin) / 2;
      end
    end
    
    % Recompute the values
    [H, thisP] = Hgamma(tempA(1, [1:i - 1, i + 1:end]), gamma(i));
    Hdiff = H - logU;
    tries = tries + 1;
  end
  
  % Set the final row of P
  %P(i, [1:i - 1, i + 1:end]) = thisP;
  tempP(1,[1:i - 1, i + 1:end]) = thisP;
  P(i, :) = tempP;
end
disp(['Mean value of gamma: ' num2str(mean(gamma))]);
disp(['Minimum value of gamma: ' num2str(min(gamma))]);
disp(['Maximum value of gamma: ' num2str(max(gamma))]);
end


function [H, P] = Hgamma(Arow, gamma)
P = Arow.^gamma;
sumP = sum(P);
P = P / sumP;
H = -sum(P(P>1e-10).* log(P(P>1e-10)));
end

