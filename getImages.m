function [imo,empt] = getImages(images, varargin)
%Load, preprocess, and pack images for CNN evaluation

opts.impath = '';
opts.maskpath = '';
opts.imageSize = [227, 227] ;
opts.outputSize = [1, 1];
opts.border = [29, 29] ;
opts.keepAspect = true ;
opts.numAugments = 1 ;
opts.transformation = 'none' ;
opts.averageImage = [] ;
opts.rgbVariance = zeros(0,3,'single') ;
opts.interpolation = 'bilinear' ;
opts.numThreads = 1 ;
opts.prefetch = false ;
opts.nChannels = 3;
opts.rangeRescale = 1;
opts.numPosPairs = 1;
opts.randomRotation = 0;
opts.numPlates = '';
opts = vl_argparse(opts, varargin);


empt = zeros(1,numel(images),'uint8');

tfs = [.5 ;.5 ; 0 ];

[~,transformations] = sort(rand(size(tfs,2), numel(images)), 1);

if ~isempty(opts.rgbVariance) && isempty(opts.averageImage)
  opts.averageImage = zeros(1,1,opts.nChannels);
end
if numel(opts.averageImage) == opts.nChannels
  opts.averageImage = reshape(opts.averageImage, 1,1,opts.nChannels);
end

imo = zeros(opts.imageSize(1), opts.imageSize(2), opts.nChannels, ...
  numel(images)*opts.numAugments, 'single');

si = 1 ;
for i=1:numel(images)
  
  % acquire image
  imt = single(imread(fullfile(opts.impath,images(i).folder,...
    images(i).filename),'tiff'))/opts.rangeRescale;
  
  % acquire mask
  [~,filename] = fileparts(images(i).filename);
  mask = load(fullfile(opts.maskpath,images(i).folder,...
    [filename '.mat']));
  
  mask = mask.ncROI.cMask | mask.ncROI.nMask;
  
  % crop & flip
  w = size(imt,2) ;
  h = size(imt,1) ;
  for ai = 1:opts.numAugments
    
    tf = tfs(:, transformations(mod(ai-1, numel(transformations)) + 1)) ;
    sz = opts.imageSize(1:2) ;
    dx = floor((w - sz(2)) * tf(2)) + 1 ;
    dy = floor((h - sz(1)) * tf(1)) + 1 ;
    flip = tf(3) ;
    
    sx = round(linspace(dx, sz(2)+dx-1, opts.imageSize(2))) ;
    sy = round(linspace(dy, sz(1)+dy-1, opts.imageSize(1))) ;
    if flip, sx = fliplr(sx) ; end
    
    if ~isempty(opts.averageImage)
      offset = opts.averageImage ;
      if ~isempty(opts.rgbVariance)
        offset = bsxfun(@plus, offset,...
          reshape(opts.rgbVariance * randn(opts.nChannels,1), 1,1,opts.nChannels)) ;
      end
      imo(:,:,:,si) = bsxfun(@minus, imt(sy,sx,:), offset) ;
    else
      imo(:,:,:,si) = imt(sy,sx,:) ;
    end
    thisMask = mask(sy,sx,:);
    if nnz(thisMask)<opts.imageSize(1)*opts.imageSize(2)*0.1
      empt(i) = 1;
    end
    si = si + 1 ;
  end
end