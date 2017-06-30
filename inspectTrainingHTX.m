function inspectTrainingHTX(d,imdb,getBatch)
%Auxiliary function to inspect the result of finetuning in the target
%dataset

opts = d.opts;
useGpu = numel(opts.train.gpus) > 0 ;
modelspath = fullfile(d.path.models,d.ex);
batchSize = opts.batchSize*4;
histDim = d.opts.inspectHistBins;
delta = 2/(histDim-1);
bins = linspace(-1-delta,1+delta,histDim);
hPos = zeros(1,histDim);
hNeg = zeros(1,histDim);

%keep only val set
valSet = [imdb.set] == 2;
imdb = imdb(valSet);
X = zeros(opts.repSize,numel(imdb));

classMat = zeros(numel(imdb),numel(imdb));
classes = [imdb.class];

for i = 1:numel(imdb);
  thisClass = classes(i);
  classMat(i,classes==thisClass) = 1;
end

for e = d.opts.inspectEpochs 
  modelPath = @(ep) fullfile(modelspath, sprintf('net-epoch-%d.mat', ep));
  fprintf('Inspecting model at epoch %d\n', e);
  load(modelPath(e), 'net');
  net = dagnn.DagNN.loadobj(net);
  net.removeLayer('error');
  net.removeLayer('loss');
  
  if useGpu
    net.move('gpu');
  end
  
  net.mode = 'test';
  net.vars(net.getVarIndex('code')).precious = 1;
  
  for t = 1:batchSize:numel(imdb)
    batch = t:min(t+batchSize-1,numel(imdb));
    input = getBatch(imdb,batch);
    net.eval(input);
    code = gather(net.vars(net.getVarIndex('code')).value);
    X(:, t:min(t+batchSize-1,numel(imdb))) = ...
      reshape(code,[size(code,1)*size(code,2)*size(code,3) numel(batch)]);
  end
  X = normc(X);
  D = X'*X;
  hPos = hist(D(classMat==1),bins)/nnz(classMat==1);
  hNeg = hist(D(classMat==0),bins)/nnz(classMat==0);
  xAxis = ((((1:histDim) - 1)*2) / (histDim - 1)) - 1;
  figure, plot(xAxis,hPos,'b',xAxis,hNeg,'r','linewidth',3)
  legend('Positive dist.','Negative dist.','Location','NorthWest');
  title('Val. set cosine similarities','fontweight','bold','fontsize',14);
  xlabel('Cosine similarities','fontsize',14);
  save(fullfile(modelspath,['inspection_epoch-' num2str(e) '.mat']),'D','hPos','hNeg');   
end
 
disp('Done Inspecting');


