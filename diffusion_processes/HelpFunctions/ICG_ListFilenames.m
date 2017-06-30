function namelist = ICG_ListFilenames(directory, extensions)
%namelist = ICG_ListFilenames(directory, extensions)
%   ICG_ListFilename lists all filenames in the specified dirctory
%   outgoing edge weights) for the provided affinity matrix
%
%   Parameter
%   ---------
%   directory ... Directory to analyze
%   extensions ... Filetypes as string (e.g. '*.png;*.jpg'
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
    
    if ~exist('extensions','var'),extensions='';end
    
    direc = dir(directory);
    p = 1;
    for d = 1 : numel(direc)
        if (~isdir(direc(d).name) && isempty(strfind(direc(d).name(1),'.')))
            if (isempty(extensions)) || numel( strfind(extensions,direc(d).name(end-2:end)) ) > 0
                namelist{p} = direc(d).name;
                p = p + 1;
            end
        end
    end
    if exist('namelist','var')
        namelist = sort(namelist);
    else 
        namelist = [];
    end