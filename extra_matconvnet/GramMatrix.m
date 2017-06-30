classdef GramMatrix < dagnn.Layer
  %Computes Gram Matrix of input = vi'vj
  properties
    type = 'matrix';
  end
  
  methods
    function outputs = forward(obj, inputs, params)
      outputs{1} = gramMat(inputs{1},[],obj.type);
    end
    
    function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
      derInputs{1} = gramMat(inputs{1},derOutputs{1},obj.type);
      derParams = {};
    end
    
    function outputSizes = getOutputSizes(obj, inputSizes)
      outputSizes{1} = [size(inputSizes{1},1) size(inputSizes{1},2)];
    end
    
    function obj = GramMatrix(varargin)
      obj.load(varargin) ;
    end
  end
end
