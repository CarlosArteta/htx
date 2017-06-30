function Y = histloss(X, C, dzdy, varargin)
%HISTLOSS computes the histogram loss described in [1]
%
% Y = HISTLOSS(X, c) computes the histogram loss incurred by the samples 
% in X, where each pair of samples has a similarity indicated by C: 
% 1 = similar, 0 = dissimilar.
%
% The variable X is of size H x W x D x N, while C is N X N.
%
% The similarity between pairs of vectors is computed as a cosine
% similarity over the vectorized inputs of size HWD.
%
% DZDX = HISTLOSS(X,C,DZDY) computes the derivative of the histogram loss
% projected onto the derivative DZDY. DZDX has the same dimensions as X.
%
% [1] E. Ustinova and V. Lempitsky. "Learning Deep Embeddings with 
% Histogram Loss". NIPS 2016

opts.histDim = 100;
opts.epsilon = 1e-2;

if nargin > 3
  opts = vl_argparse(opts, varargin);
end

sz = [size(X,1) size(X,2) size(X,3) size(X,4)];
ne = sz(4);
nDim = sz(1)*sz(2)*sz(3);

assert(all(size(C) == [ne ne]),...
  'Labels must be of size Num. Inputs X Num. Inputs');
assert(nnz(C>1) == 0, 'Entries in C are limited to 0 and 1');
if ~isempty(dzdy)
assert(nnz(C==1) > 0 & nnz(C==0) >0,...
  'The loss requires similar and dissimilar in the same batch');
end
%%
%build histogram structures
delta = 2/(opts.histDim-1);
bins = linspace(-1-delta,1+delta,opts.histDim);
hPos = zeros(1,opts.histDim);
hNeg = zeros(1,opts.histDim);

%compute cosine similarities
X = reshape(X,1,1,nDim,ne);
Xnorm = vl_nnnormalizelp(X,[],'epsilon',opts.epsilon);
Xnorm = reshape(Xnorm, nDim, ne);
sim = gather(Xnorm'*Xnorm);

%fill bins
for r = 2:opts.histDim-1
  rg = [bins(r-1) bins(r) bins(r+1)];
  posSim1 = (C==1 & sim>=rg(1) & sim<rg(2));
  posSim2 = (C==1 & sim>=rg(2) & sim<rg(3));
  negSim1 = (C==0 & sim>=rg(1) & sim<rg(2));
  negSim2 = (C==0 & sim>=rg(2) & sim<rg(3));
  
  hPos(r) = sum([sim(posSim1)-rg(1) ; rg(3)-sim(posSim2)])/delta;
  hNeg(r) = sum([sim(negSim1)-rg(1) ; rg(3)-sim(negSim2)])/delta;
end

cardSpos = nnz(C==1);
cardSneg = nnz(C==0);

hPos = hPos/cardSpos;
hNeg = hNeg/cardSneg;

%cumulative positive histogram
cumhPos = cumsum(hPos);

%figure, plot(1:opts.histDim,hPos,'b',1:opts.histDim,hNeg,'r',1:opts.histDim,cumhPos,'k', 'linewidth',3)
%legend('Positive dist.','Negative dist.','Cumulative positive dist.');

if isempty(dzdy) %Forward
  Y = hNeg*cumhPos'*100;
  
else %Backward
  dzdhp = cumsum(hNeg,'reverse'); 
  dzdhn = cumhPos; 
  
  dhpds = zeros(opts.histDim,ne^2);
  dhnds = zeros(opts.histDim,ne^2);
  
  for r = 2:opts.histDim-1
    dhprds = zeros(ne,ne);
    dhnrds = zeros(ne,ne);
    
    rg = [bins(r-1) bins(r) bins(r+1)];
    posSim1 = (C==1 & sim>=rg(1) & sim<rg(2));
    posSim2 = (C==1 & sim>=rg(2) & sim<rg(3));
    negSim1 = (C==0 & sim>=rg(1) & sim<rg(2));
    negSim2 = (C==0 & sim>=rg(2) & sim<rg(3));
    
    dhprds(posSim1) = 1/(delta*cardSpos);
    dhprds(posSim2) = -1/(delta*cardSpos);
    dhnrds(negSim1) = 1/(delta*cardSneg);
    dhnrds(negSim2) = -1/(delta*cardSneg);
    
    dhpds(r,:) = reshape(dhprds,ne*ne,1);
    dhnds(r,:) = reshape(dhnrds,ne*ne,1);
  end
  
  dzds = dzdhn*dhnds + dzdhp*dhpds; 

  dsdxinorm = Xnorm';
   
  dzdxnorm = zeros(size(Xnorm),'like',X); 
  for i = 1:ne
    dzdxnorm(:,i) = 2*dzds(1+(i-1)*ne:ne+(i-1)*ne)*dsdxinorm;
  end
  
  dzdxnorm = reshape(dzdxnorm,1,1,nDim,ne);
  dzdx = vl_nnnormalizelp(X,dzdxnorm,'epsilon',opts.epsilon);
  dzdx = reshape(dzdx,sz);
    
  Y = dzdy.*dzdx*100;
  
end
