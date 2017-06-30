function aff_matrix = ICG_MatrixNormalization(distance_matrix, kth)
% aff_matrix = ICG_MatrixNormalization(distance_matrix, kth)
%   ICG_MatrixNormalization normalizes a distance matrix (the higher 
%   the more different) by the method proposed in 
%   "Self-tuning spectral clustering" 
%   from Zelnik-Manor and Perona, in NIPS 2004
%
%   Parameter
%   ---------
%   distance_matrix ... The input matrix (the higher the more different)
%   kth ... The kth nearest neigbor to be considered
%
%   Returns
%   -------
%   s_matrix ... Normalized affinity matrix (values between 0 (different) 
%       and 1 (similar))
%
%   Example
%   -------
%   aff_matrix = ICG_DistanceMatrixNormalization(distance_matrix, 10)
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

    addpath('./HelpFunctions');
    addpath('./MinMaxSelection');
    
    if ~exist('kth','var')
        kth = 10;
    end
        
    if ~exist('maxk','file')
        % We require the efficient Min/Max selection tool by Bruno Luong
         unzip('http://www.mathworks.com/matlabcentral/fileexchange/23576-minmax-selection?download=true');
         addpath('./MinMaxSelection');
		 pause(1);
         minmax_install
    end
    
    vals = maxk(distance_matrix, kth, 2 );
    sigmas_i = vals(:, kth);
    W = sigmas_i*sigmas_i';
    aff_matrix = exp(-distance_matrix.^2./W);
    