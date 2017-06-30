%Process HTS data with HTX
clc;
disp('====================================');
disp('------High-Throughput eXplorer------');
disp('====================================');

%% Add paths
p = mfilename('fullpath');
cd(fileparts(p));
addpath(fileparts(p));

if exist('vl_setup','file') == 0
    error('Vl_feat required');
end

if exist('vl_setupnn','file') == 0
    error('MatConvNet required');
end

if exist('tsne_p','file') == 0
    error('t-SNE toolbox required');
end

addpath('diffusion_processes/');
addpath('extra_matconvnet/');
addpath('utils/');

%% Setup

%%%%%%%%%%%%%%%%
dataPath = ''; % ---> path to data, models, etc.
%%%%%%%%%%%%%%%%

if isempty(dataPath)
  error('Path to root folder required');
end

experimentPrefix = 'gram';
[data, imdb] = dataConfig(dataPath,experimentPrefix);
disp(['Processing: ' data.path.root '-' data.ex])

%% Index
[groups,index] = buildIndex(data,imdb);

%% Fine-tune CNN
net = finetuneNet(data,imdb);

%% Encode Data
encodeData(data,net,imdb,groups);
clear net;

%% Compute Pairwise Distance Matrix
D = computePairDistances(data,groups);

%% Generate sequence of embeddings
genVisualizations(data,D);

%% Enrichments
if exist(data.path.hypotheses,'file')==0
  H = [];
  E = [];
else
  H = load(data.hypothesespath);
  H = H.H;
  E = findErichments(data,D,H);
end

%% Load GUI
htxGUI(data,index,groups,H,D,E);
