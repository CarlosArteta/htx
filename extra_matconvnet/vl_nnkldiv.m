function [ y ] = vl_nnkldiv( in, tgt, dzdy, varargin )
%VL_NNKLDIV Kullback-Leibler divergence.
%   Y = VL_NNKLDIV(X, TGT) computes the KL-Divergence between the
%   probability distribution X and target prob. dist. TGT.
%   X and TGT have dimension H x W x D x N, packing N arrays of W x H
%   D-dimensional vectors. Both X and TGT must be a valid probability
%   distribution.
%   The KL-Divergence is computed for each sample as:
%
%   Y(i, j, 1) = SUM_d (TGT(i,j,d) * log(TGT(i,j,d) / X(i,j,d)))
%
%   Y = VL_NNKLDIV(X, TGT, [], 'inIsLog', true) assumes that the logarithm
%   has been already applied to the input array, instead calculating:
%
%   Y(i, j, 1) = SUM_d (TGT(i,j,d) * (log(TGT(i,j,d)) - X(i,j,d)))
%
%   DZDX = VL_NNKLDIV(X, TGT, DZDY)
%   DZDX = VL_NNKLDIV(X, TGT, DZDY, 'inIsLog', true) computes the
%   derivative of the block projected onto DZDY. X and DZDY have the same
%   dimensions as X and Y respectively.
%
%   VL_NNKLDIV(___, 'OPT', VAL, ...) accepts the following options:
%
%   `Epsilon`:: 1e-100
%      When computing derivatives, quantities that are divided in are
%      lower boudned by this value.

% Copyright (C) 2016 Karel Lenc and Andrea Vedaldi.
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

if ~exist('dzdy', 'var'), dzdy = []; end;
if ischar(dzdy), varargin = [{dzdy} varargin]; dzdy = []; end;
opts.epsilon = 1e-100;
opts.inIsLog = false;
opts = vl_argparse(opts, varargin);

szin = size(in); sztgt = size(tgt); nel = size(in, 4);
assert(numel(szin) == numel(sztgt), 'Invalid dimensionality');
assert(all(szin == sztgt), 'Invalid input sizes.');

in = reshape(in, [], nel);
tgt = reshape(tgt, [], nel);
checkdistr(tgt, 1e-4, 'tgt');
if ~opts.inIsLog
  checkdistr(in, 1e-4, 'in');
  if any(in(:) == 0 & tgt(:) ~= 0)
    warning('KL Divergence not defined for `in = 0 & tgt ~= 0`.');
  end
  inl = log(in);
  sel = tgt > opts.epsilon & in > opts.epsilon;
else
  checkdistr(exp(in), 1e-4, 'tgt');
  inl = in;
  sel = tgt > opts.epsilon;
end
doder = ~isempty(dzdy);

if ~doder;
  y = sum(tgt(sel) .* (log(tgt(sel)) - inl(sel)));
else
  if opts.inIsLog
    y = - tgt * dzdy;
  else
    y = - (tgt ./ max(in,1e-10)) * dzdy;
    y(~sel) = 0;
  end
  y = reshape(y, szin);
end
end

function checkdistr(x, epsilon, name)
  if any(abs(sum(x, 1) - 1) > epsilon) || any(x(:) < 0)
    error('%s must be a valid distribution.', name);
  end
end