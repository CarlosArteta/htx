function inv_d = ICG_MatInvDegree(aff_matrix)
% inv_d = ICG_MatInvDegree(aff_matrix)
%   ICG_MatInvDegree creates the inverse of the degree matrix (sum of
%   outgoing edge weights) for the provided affinity matrix
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

    n = size(aff_matrix,1);
    d = sum(aff_matrix,2).^-1;
    d(isinf(d)) = 0;
    inv_d = spdiags(d,0,n,n);

