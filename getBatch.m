function inputs = getBatch(opts, useGpu, type, classGroups, imdb, batch)

images = imdb(batch);
bs = numel(batch);

if ~strcmp(type,'main')
  plateLabels = [images(:).plateclass];
  uniDist = 1/(opts.numPlates*ones(1,1,opts.numPlates));
  fpp = opts.numPosPairs; %fixed positive pairs
  labels = zeros(fpp*numel(batch),fpp*numel(batch));
  imClass = zeros(1,numel(batch));
  pImClass = zeros(1,(fpp-1)*numel(batch));
  pi = 1;
end

if ~strcmp(type,'main')
  %find fpp positive pairs
  posPairs = zeros(1,bs*(fpp-1));
  for i = 1:numel(batch)
    thisClass = imdb(batch(i)).class;
    %cands = find([imdb.class] == thisClass);
    cands = classGroups{thisClass};
    thisCand = cands==batch(i);
    cands = cands(~thisCand);
    if numel(cands)>=fpp
      posPairs(pi:pi+fpp-2) = randsample(cands,fpp-1,false);
    else
      posPairs(pi:pi+fpp-2) = randsample(cands,fpp-1,true);
    end
    imClass(i) = thisClass;
    pImClass(pi:pi+fpp-2) = thisClass;
    pi = pi + fpp - 1;
  end
  posImages = imdb(posPairs);
  imClass = [imClass pImClass];
  plateLabels = [plateLabels [imdb(posPairs).plateclass]];
end

opts.transformation = 'none';
[im, emptIm] = getImages(images, opts);

if ~strcmp(type,'main')
  [pim, emptPim] = getImages(posImages, opts);
  emptIm = [emptIm emptPim];
  imClass(emptIm==1) = -1;
  for i = 1:fpp*numel(batch)
    %0 for dissimilar images, 1 for similar
    labels(i,:) = imClass == imClass(i);
  end
end

if nargout > 0
  if useGpu
    im = gpuArray(im);
    if ~strcmp(type,'main')
      pim = gpuArray(pim);
      im = cat(4,im,pim);
      if opts.randomRotation
        im = rot90(im,randi([0 3]));
      end
    end
  end
  
  if strcmp(type,'main')
    inputs = {'input',im};
  elseif opts.numPlates > 1
    inputs = {'input',im,'labels', labels,...
      'plate_labels', plateLabels, 'target_dist', repmat(uniDist,1,1,1,bs*fpp)};
  else
    inputs = {'input',im,'labels', labels};
  end
  
end