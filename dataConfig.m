function [d,imdb] = dataConfig(rootPath,expPrefix)
%Global configuration file

if nargin<2
  expPrefix = 'htx';
end

[~,dataName] = fileparts(rootPath);

%Paths configuration
d.path.root = fullfile(rootPath);
d.path.normdata = fullfile(d.path.root,'rgb');
d.path.pretrain = fullfile(d.path.root,'pretrain');
d.path.rawdata = fullfile(d.path.root,'rawdata');
d.path.metadata = fullfile(d.path.root,'metadata');

d.path.codes = fullfile(d.path.root,'codes');
d.path.models = fullfile(d.path.root,'models');
d.path.masks = fullfile(d.path.root,'masks');

d.path.imdb = fullfile(d.path.metadata,[dataName '_imdb.mat']);
d.path.imdbmeta = fullfile(d.path.metadata,[dataName '_meta.mat']);
d.path.groups = fullfile(d.path.metadata,[dataName '_groups.mat']);
d.path.index = fullfile(d.path.metadata,[dataName '_index.mat']);
d.path.hypotheses = fullfile(d.path.metadata,[dataName '_hypotheses.mat']);

d.path.pretrainModel = fullfile(d.path.pretrain,'ubodtd_small.mat');

if exist(d.path.codes,'dir') == 0
    mkdir(d.path.codes);
end
if exist(d.path.results,'dir') == 0
    mkdir(d.path.results);
end
if exist(d.path.models,'dir') == 0
    mkdir(d.path.models);
end

%Load imdb and meta
imdb = load(d.path.imdb);
imdb = imdb.imdb;
imdbmeta = load(d.path.imdbmeta);
imdbmeta = imdbmeta.imdbmeta;

%Get some metadata
d.meta.imExt = 'tiff';
d.meta.nChannels = imdbmeta.nChannels;
d.meta.mainChannel = imdbmeta.mainChannel;
d.meta.imPerComp = imdbmeta.imPerComp;
d.meta.resize = imdbmeta.resize;

%Centre crop size taken when encoding
d.opts.encodeCropSize = [512 512]; 

%For training cnn 
d.opts.rangeRescale = 2^4;
d.opts.numFetchThreads = 1;
d.opts.lite = false;
d.opts.modelType = 'fromMultiG_HistLoss_Adver';
d.opts.batchSize = 8;
d.opts.numPosPairs = 5; 
d.opts.repSize = 1024*3;

d.opts.train.prefetch = false;
d.opts.train.gpus = [1];
d.opts.train.numEpochs = 15;
d.opts.train.learningRate = logspace(-1, -3, d.opts.train.numEpochs); 
d.opts.train.derOutputs = {'objective',1,'objective1',1,'objective2',0.5};

d.opts.model.nChannels = d.meta.nChannels;
d.opts.model.colorSpace  = 'gray';

d.opts.inspectTraining = 0;
d.opts.inspectEpochs = d.opts.train.numEpochs;
d.opts.inspectHistBins = 100;

d.ex = [expPrefix '_' d.opts.modelType '_' num2str(d.opts.repSize)];
d.opts.expDir = fullfile(d.path.models,d.ex);

if exist(d.opts.expDir,'dir')==0
  mkdir(d.opts.expDir) ;
end

%Visualization 
d.vis.nDims = 2;
d.vis.perp = 50;
d.vis.KNNrange = [5 10 15 20 25];
d.vis.initKNN = 105;
d.vis.knnStep = 40;
d.vis.minKNN = 5;
d.vis.perpTol = 0.25;

%Enrichments 
d.enrich.probTH = 0.999;
d.enrich.pTH = 0.01; %p-value threshold
d.enrich.prepEnrch = 5;
