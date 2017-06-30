classdef Switch < dagnn.Layer
  properties
    pos = 'close';
    scale = 1;
  end
  
  methods
    function outputs = forward(obj, inputs, params)
      outputs{1} = inputs{1};
    end
    
    function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
      if strcmp(obj.pos,'open')
        derInputs{1} = [];
      else
        derInputs{1} = obj.scale.*derOutputs{1} ;
      end
      derParams{1} = [];
    end
    
    function outputSizes = getOutputSizes(obj, inputSizes)
      outputSizes{1} = inputSizes{1};
    end
    
    function obj = Switch(varargin)
      obj.load(varargin) ;
    end
  end
end
