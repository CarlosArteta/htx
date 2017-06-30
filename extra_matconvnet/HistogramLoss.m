classdef HistogramLoss < GenericLoss
  properties
    histDim = 100;
    epsilon = 1e-2;
  end
  
  methods
    function outputs = forward(obj, inputs, params)
      outputs{1} = histloss(inputs{1},inputs{2},[],'histDim', obj.histDim);
      obj.account(inputs, outputs);
    end
    
    function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
      dzdx = histloss(inputs{1},inputs{2},derOutputs{1}, 'histDim', obj.histDim);
      derInputs = {dzdx,[]};
      derParams = {} ;
    end
    
    function obj = HistogramLoss(varargin)
      obj.load(varargin{:}) ;
    end
  end
end