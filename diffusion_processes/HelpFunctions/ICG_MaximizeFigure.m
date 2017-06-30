function ICG_MaximizeFigure(fig)
% ICG_MaximizeFigure maximizes the specified figure
%   This function is sometimes needed if you want to acquire images from
%   the figures
%
%   Parameter:
%   fig ... The figure to become maximized
%
%   Example:
%   ICG_MaximizeFigure(gcf);
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

	if nargin==0, fig=gcf; end
	units=get(fig,'units');
	set(fig,'units','normalized','outerposition',[0 0 1 1]);
	set(fig,'units',units);