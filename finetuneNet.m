function net = finetuneNet(d,imdb)
%Fine tune the texture description network on the target dataset

opts = d.opts;

modelPath = fullfile(opts.expDir, 'mainNet.mat');
modelPathVis = fullfile(opts.expDir, 'mainNetVis.mat');

if exist(modelPath,'file')~=0 && exist(modelPathVis,'file')~=0 
  net = load(modelPath);
  net = dagnn.DagNN.loadobj(net);
  return;
end

%Load pretrained model
load(d.path.pretrainModel, 'net');
net = dagnn.DagNN.loadobj(net);

%Convert 
net = buildNet(net,opts.model.nChannels,max([imdb.plateclass]));
net.meta.trainOpts.batchSize = opts.batchSize;
net.meta.trainOpts.learningRate = opts.train.learningRate;
net.meta.trainOpts.numEpochs = opts.train.numEpochs;
net.meta.opts.trainOpts.derOutputs = opts.train.derOutputs;

%Define train/val set
rng(0);
valSet = randperm(numel(imdb),round(numel(imdb)*0.2));
imdb(1).set = [];
[imdb.set] = deal(1);
[imdb(valSet).set] = deal(2);

% Set the class names in the network
classes = [imdb.class];
valSet = [imdb.set] == 2;
classGroups = cell(1,max(classes)); 
for i = 1:max(classes)
  classGroups{i} = find(classes==i & ~valSet);
end

%Copy some variables over to the net structure
net.meta.impath = d.path.rawdata;
net.meta.maskpath = d.path.masks;
net.meta.normalization.averageImage = [];
net.meta.augmentation.rgbVariance = [];
net.meta.augmentation.transformation = [];
net.meta.rangeRescale = d.opts.rangeRescale;
net.meta.numPlates = max([imdb.plateclass]);

%Compute image statistics (mean, RGB covariances, etc.)
imageStatsPath = fullfile(opts.expDir, 'imageStats.mat') ;
if exist(imageStatsPath)
  load(imageStatsPath, 'chanMean', 'chanCovariance') ;
else
  [averageImage, chanMean, chanCovariance] = getImageStats(opts, net.meta, imdb) ;
  save(imageStatsPath, 'chanMean', 'chanCovariance','averageImage') ;
end

%Set the image average (use either an image or a color)
net.meta.normalization.averageImage = chanMean ;

%Set data augmentation statistics
[v,u] = eig(chanCovariance) ;
net.meta.augmentation.chanVariance = 0.1*sqrt(u)*v' ;
clear v u ;

%Run
[net, info] = cnn_train_dag_htx(net, imdb,...
  getBatchFn(opts, net.meta, 'all', classGroups), ...
  'expDir', opts.expDir, ...
  net.meta.trainOpts,...
  opts.train) ;

%Inspect
if d.opts.inspectTraining 
  inspectTrainingHTX(d,imdb,getBatchFn(opts, net.meta, 'main', classGroups));
end

% -------------------------------------------------------------------------
%                                                                    Deploy
% -------------------------------------------------------------------------
net = deployCNN(net,'_s'); 

%encoding network
net_ = net.saveobj();
save(modelPath, '-struct', 'net_');

%visualization network
net = deployCNNvis(net,'true'); 
net_ = net.saveobj();
save(modelPathVis, '-struct', 'net_');
clear net_;

% -------------------------------------------------------------------------
function fn = getBatchFn(opts, meta, type, classGroups)
% -------------------------------------------------------------------------
useGpu = numel(opts.train.gpus) > 0 ;

bopts.numThreads = opts.numFetchThreads;
bopts.nChannels = opts.model.nChannels;
bopts.averageImage = meta.normalization.averageImage ;
bopts.rgbVariance = meta.augmentation.rgbVariance ;
bopts.transformation = meta.augmentation.transformation ;
bopts.impath = meta.impath;
bopts.maskpath = meta.maskpath;
bopts.outputSize = meta.outputSize;
bopts.rangeRescale = meta.rangeRescale;
bopts.numPosPairs = opts.numPosPairs;
bopts.numPlates = meta.numPlates;
bopts.randomRotation = meta.augmentation.randomRotation ;

fn = @(x,y) getBatch(bopts,useGpu,type,classGroups,x,y) ;

% -------------------------------------------------------------------------
function [averageImage, rgbMean, rgbCovariance] = getImageStats(opts, meta, imdb)
% -------------------------------------------------------------------------
bs = 64 ;
step = 10;
fn = getBatchFn(opts, meta, 'main',[]) ;
avg = {}; rgbm1 = {}; rgbm2 = {};

for t=1:bs*step:numel(imdb)
  batch_time = tic ;
  batch = t:step:min(t+bs*step-1, numel(imdb));
  fprintf('collecting image stats: batch starting with image %d ...', batch(1)) ;
  temp = fn(imdb, batch) ;
  temp = gather(temp{2});
  z = reshape(permute(temp,[3 1 2 4]),opts.model.nChannels,[]) ;
  n = size(z,2) ;
  avg{end+1} = mean(temp, 4) ;
  rgbm1{end+1} = sum(z,2)/n ;
  rgbm2{end+1} = z*z'/n ;
  batch_time = toc(batch_time) ;
  fprintf(' %.2f s (%.1f images/s)\n', batch_time, numel(batch)/ batch_time) ;
end
averageImage = mean(cat(4,avg{:}),4) ;
rgbm1 = mean(cat(2,rgbm1{:}),2) ;
rgbm2 = mean(cat(3,rgbm2{:}),3) ;
rgbMean = rgbm1 ;
rgbCovariance = rgbm2 - rgbm1*rgbm1' ;
