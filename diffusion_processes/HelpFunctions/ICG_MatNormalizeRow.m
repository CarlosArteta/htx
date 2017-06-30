function P = ICG_MatNormalizeRow(aff_matrix)
% P = ICG_NormalizeRow(aff_matrix)
%   ICG_NormalizeRow creates a Markov Chain Transition matrix, where the
%   sum over all rows is normalized to 1
%
%   Parameter
%   ---------
%   aff_matrix ... N x N affinity matrix to normalize
%   
%   For more details see:
%   "Diffusion Processes for Retrieval Revisited"
%   Michael Donoser and Horst Bischof
%   Proceedings of Conference on Computer Vision 
%   and Pattern Recognition (CVPR), 2013
%
%   ****************************************************************
%	Copyright by Michael Donoser 
%	Institute for Computer Graphics and Vision
%	Graz University of Technology
%   Please email to michael.donoser@tugraz.at 
%   if you find bugs, or have suggestions or questions!
%   Licensed under the Lesser GPL [see License/lgpl.txt]
%   ****************************************************************

    P = ICG_MatInvDegree(aff_matrix)*aff_matrix;

