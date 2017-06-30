function net = deployCNNvis(net,addAvgIm)
%Deploy the texture network, modified for the visualization case by
%replacing standard MatConvNet layers with those required for the
%excitation backpropagation method

%remove training layers
dagRemoveLayersOfType(net, 'dagnn.Loss');
dagRemoveLayersOfType(net, 'dagnn.DropOut');

%merge batch norm
dagMergeBatchNorm(net);
dagRemoveLayersOfType(net, 'dagnn.BatchNorm');

%replace relevant layer for excitation BP
dagChangeLayersOfType(net, 'dagnn.Conv') ;
dagChangeLayersOfType(net, 'dagnn.Pooling') ;

if addAvgIm
  avIm = net.meta.normalization.averageImage;
  avIm = reshape(avIm,1,1,numel(avIm));
  filter = net.params(1).value;
  fSize = size(filter);
  avIm = repmat(avIm,fSize(1),fSize(2));
  nb = vl_nnconv(avIm,filter,[]);
  net.params(2).value = net.params(2).value - nb(:);  
end

% -------------------------------------------------------------------------
function layers = dagFindLayersWithOutput(net, outVarName)
% -------------------------------------------------------------------------
layers = {} ;
for l = 1:numel(net.layers)
  if any(strcmp(net.layers(l).outputs, outVarName))
    layers{1,end+1} = net.layers(l).name ;
  end
end

% -------------------------------------------------------------------------
function layers = dagFindLayersOfType(net, type)
% -------------------------------------------------------------------------
layers = [] ;
for l = 1:numel(net.layers)
  if isa(net.layers(l).block, type)
    layers{1,end+1} = net.layers(l).name ;
  end
end

% -------------------------------------------------------------------------
function dagRemoveLayersOfType(net, type)
% -------------------------------------------------------------------------
names = dagFindLayersOfType(net, type) ;
for i = 1:numel(names)
  layer = net.layers(net.getLayerIndex(names{i})) ;
  net.removeLayer(names{i}) ;
  net.renameVar(layer.outputs{1}, layer.inputs{1}, 'quiet', true) ;
end

% -------------------------------------------------------------------------
function dagMergeBatchNorm(net)
% -------------------------------------------------------------------------
names = dagFindLayersOfType(net, 'dagnn.BatchNorm') ;
for name = names
  name = char(name) ;
  layer = net.layers(net.getLayerIndex(name)) ;
  
  % merge into previous conv layer
  playerName = dagFindLayersWithOutput(net, layer.inputs{1}) ;
  playerName = playerName{1} ;
  playerIndex = net.getLayerIndex(playerName) ;
  player = net.layers(playerIndex) ;
  if ~isa(player.block, 'dagnn.Conv')
    error('Batch normalization cannot be merged as it is not preceded by a conv layer.') ;
  end
  
  % if the convolution layer does not have a bias,
  % recreate it to have one
  if ~player.block.hasBias
    block = player.block ;
    block.hasBias = true ;
    net.renameLayer(playerName, 'tmp') ;
    net.addLayer(playerName, ...
      block, ...
      player.inputs, ...
      player.outputs, ...
      {player.params{1}, sprintf('%s_b',playerName)}) ;
    net.removeLayer('tmp') ;
    playerIndex = net.getLayerIndex(playerName) ;
    player = net.layers(playerIndex) ;
    biases = net.getParamIndex(player.params{2}) ;
    net.params(biases).value = zeros(block.size(4), 1, 'single') ;
  end
  
  filters = net.getParamIndex(player.params{1}) ;
  biases = net.getParamIndex(player.params{2}) ;
  multipliers = net.getParamIndex(layer.params{1}) ;
  offsets = net.getParamIndex(layer.params{2}) ;
  moments = net.getParamIndex(layer.params{3}) ;
  
  [filtersValue, biasesValue] = mergeBatchNorm(...
    net.params(filters).value, ...
    net.params(biases).value, ...
    net.params(multipliers).value, ...
    net.params(offsets).value, ...
    net.params(moments).value) ;
  
  net.params(filters).value = filtersValue ;
  net.params(biases).value = biasesValue ;
end

% -------------------------------------------------------------------------
function [filters, biases] = mergeBatchNorm(filters, biases, multipliers, offsets, moments)
% -------------------------------------------------------------------------
% wk / sqrt(sigmak^2 + eps)
% bk - wk muk / sqrt(sigmak^2 + eps)
a = multipliers(:) ./ moments(:,2) ;
b = offsets(:) - moments(:,1) .* a ;
biases(:) = biases(:) + b(:) ;
sz = size(filters) ;
numFilters = sz(4) ;
filters = reshape(bsxfun(@times, reshape(filters, [], numFilters), a'), sz) ;

% -------------------------------------------------------------------------
function net = dagChangeLayersOfType(net, type)
% -------------------------------------------------------------------------
names = dagFindLayersOfType(net, type);

for i = 1:numel(names)
  layer = net.layers(net.getLayerIndex(names{i}));
  name = [names{i} '_ebp'];   
  inputs = layer.inputs;
  outputs = layer.outputs;
  params = struct(...
    'name', {}, ...
    'value', {}, ...
    'learningRate', [], ...
    'weightDecay', []);
  
  switch type
    case 'dagnn.Conv'
      block = Conv_ebp();
      block.size = layer.block.size;
      block.hasBias = layer.block.hasBias;
      block.opts{1} = layer.block.opts{1};
      block.pad = layer.block.pad;
      block.stride = layer.block.stride;
      block.exBackprop = true;      
      
      findex = net.getParamIndex([names{i} 'f']);
      params(1).name = sprintf('%sf',name);
      params(1).value = net.params(findex).value;
      params(1).learningRate = net.params(findex).learningRate;
      params(1).weightDecay = net.params(findex).weightDecay;
      if block.hasBias
        bindex = net.getParamIndex([names{i} 'b']);
        params(2).name = sprintf('%sb',name);
        params(2).value =  net.params(bindex).value;
        params(2).learningRate = net.params(bindex).learningRate;
        params(2).weightDecay = net.params(bindex).weightDecay;
      end
      
      net.addLayer(...
        name, ...
        block, ...
        inputs, ...
        outputs, ...
        {params.name});
      
      findex = net.getParamIndex(params(1).name);
      net.params(findex).value = params(1).value;
      net.params(findex).learningRate = params(1).learningRate;
      net.params(findex).weightDecay = params(1).weightDecay;
      
      bindex = net.getParamIndex(params(2).name);
      net.params(bindex).value = params(2).value;
      net.params(bindex).learningRate = params(2).learningRate;
      net.params(bindex).weightDecay = params(2).weightDecay;
      
    case 'dagnn.Pooling'
      block = Pooling_ebp();
      block.method = layer.block.method;
      block.poolSize = layer.block.poolSize;
      block.opts{1} = layer.block.opts{1};
      block.pad = layer.block.pad;
      block.stride = layer.block.stride;
      if strcmp(block.method,'avg')
        block.exBackprop = true;
      else
        block.exBackprop = false;
      end
      net.addLayer(...
        name, ...
        block, ...
        inputs, ...
        outputs, ...
        {params.name});
  end
  net.removeLayer(names{i});
  %net.renameVar(layer.outputs{1}, layer.inputs{1}, 'quiet', true);
end

