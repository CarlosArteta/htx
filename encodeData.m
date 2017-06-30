function encodeData(d,net,imdb,groups)
%Does the group-wise encoding and saves each code.

opts = d.opts;
useGpu = numel(opts.train.gpus) > 0;

if useGpu
  gpuDevice(d.opts.train.gpus);
  net.move('gpu');
end

net.mode = 'test';
net.meta.impath = d.path.rawdata;
net.meta.maskpath = d.path.masks;
net.meta.normalization.imageSize = opts.encodeCropSize;
net.vars(net.getVarIndex('code')).precious = 1 ;
getBatch = getBatchFn(opts, net.meta, 'main',[]);

codepath = fullfile(d.path.codes,d.ex);

if exist(codepath,'dir') == 0
  mkdir(codepath);
end

for ii = 1:length(groups)
  if exist(fullfile(codepath,[num2str(ii) '.mat']),'file')==0
    disp(['Encoding group ' num2str(ii)]);
    
    input = getBatch(imdb,groups{ii});
    net.eval(input);
    
    code = gather(net.vars(net.getVarIndex('code')).value);
    
    code = nanmean(code,4);
    code = reshape(code,[size(code,1)*size(code,2)*size(code,3) 1]);
    code = code./max(norm(code),1e-10);
    save(fullfile(codepath,[num2str(ii) '.mat']),'code');
  end
end

disp('Done Encoding');

% -------------------------------------------------------------------------
function fn = getBatchFn(opts, meta, type, classGroups)
% -------------------------------------------------------------------------
useGpu = numel(opts.train.gpus) > 0 ;

bopts.numThreads = opts.numFetchThreads;
bopts.nChannels = opts.model.nChannels;
bopts.imageSize = meta.normalization.imageSize;
bopts.averageImage = meta.normalization.averageImage;
bopts.rgbVariance = meta.augmentation.rgbVariance;
bopts.transformation = meta.augmentation.transformation;
bopts.impath = meta.impath;
bopts.maskpath = meta.maskpath;
bopts.outputSize = meta.outputSize;
bopts.rangeRescale = meta.rangeRescale;
bopts.numPosPairs = opts.numPosPairs;

fn = @(x,y) getBatch(bopts,useGpu,type,classGroups,x,y);
