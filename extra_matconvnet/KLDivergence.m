classdef KLDivergence < GenericLoss
  properties
    inIsLog = false;
  end

  methods
    function outputs = forward(obj, inputs, params)
      outputs{1} = vl_nnkldiv(inputs{1}, inputs{2}, [], ...
        'inIsLog', obj.inIsLog) ;
      obj.account(inputs, outputs);
    end

    function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
      derInputs{1} = vl_nnkldiv(inputs{1}, inputs{2}, derOutputs{1}, ...
        'inIsLog', obj.inIsLog) ;
      derInputs{2} = [] ;
      derParams = {} ;
    end

    function obj = KLDivergence(varargin)
      obj.load(varargin) ;
    end
  end
end