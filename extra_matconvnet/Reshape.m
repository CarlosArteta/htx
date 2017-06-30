classdef Reshape < dagnn.Layer
 %The layer reshapes the first 2 dimensions of the first input according to
 %the HEIGHT and WIDTH describe in the object property 'forwardSize'.
 %if a second input is available, the layer would use the size in the first
 %two dimensions of this input as 'forwardSize'.
  
  properties
    padType = 0
    suppressDer = 0
  end
  
  properties (Transient)
    forwardSize = [];
    backwardSize = [];
  end
  
  methods
    function outputs = forward(obj, inputs, params)
      obj.backwardSize = [size(inputs{1},1) size(inputs{1},2)];
      if numel(inputs)>1
        obj.forwardSize = [size(inputs{2},1) size(inputs{2},2)];
      end
      outputs{1} = reshapeLayer(inputs{1}, obj.forwardSize, obj.padType) ;
    end
    
    function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
      if ~obj.suppressDer
        derInputs{1} = reshapeLayer(derOutputs{1}, obj.backwardSize, obj.padType) ;
      else
        derInputs{1} = {};
      end
      if numel(inputs)>1
        derInputs{2} = {};
      end
      derParams = {} ;
    end
    
    function outputSizes = getOutputSizes(obj, inputSizes)
      if isempty(obj.forwardSize)
        outputSizes{1} = inputSizes{1};
      else
        outputSizes{1} = [obj.forwardSize(1) obj.forwardSize(2)...
          inputSizes{1}(3) inputSizes{1}(4)] ;
      end
    end
    
    function obj = Reshape(varargin)
      obj.load(varargin) ;
    end
  end
end
