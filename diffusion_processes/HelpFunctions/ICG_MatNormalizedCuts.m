function P_NC = ICG_MatNormalizedCuts(aff_matrix)
% P_NC = ICG_MatNormalizedCuts(aff_matrix)
%   ICG_MatNormalizedCuts creates a Transition matrix based on the
%   Normalized Cut principle where the sum over all rows is normalized to 1
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
    Dinv = spdiags(sum(aff_matrix,2),0,n,n);
    
    for i=1:n
        Dinv(i,i) = 1/sqrt(Dinv(i,i));
    end

    P_NC = Dinv * aff_matrix * Dinv;

