function bullseye = ICG_RelativeRetrievalBullsEyeScore(affinity_matrix,labels, REL_RANGE)
% bullseye = ICG_RelativeRetrievalBullsEyeScore(affinity_matrix,labels,REL_RANGE)
%   ICG_RetrievalBullsEyeScore calculates the realtive bullseye score 
%   (a retrieval quality measure, i.e. the average percentage of instances 
%   of the same class as the query within the bullseye_range x number of 
%   elements with the same class label
%
%   Paramter
%   --------
%   affinity_matrix ... NxN matrix of affinities (higher is more similar!)
%   labels ... the ground truth labels
%   REL_RANGE ... (double value) the relative number of elements to consider, i.e.
%       1 means that we check exactly the number of elements with the same 
%       label, and 2 e.g. that we check twice the number
%       (Default: 1)
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

    addpath('./MinMaxSelection');
    if ~exist('maxk','file')
        % We require the efficient Min/Max selection tool by Bruno Luong
         unzip('http://www.mathworks.com/matlabcentral/fileexchange/23576-minmax-selection?download=true');
         addpath('./MinMaxSelection');
         pause(1);
         minmax_install
    end

    if ~exist('REL_RANGE','var'),
        REL_RANGE = 1;
    end

    if any(any(affinity_matrix ~= affinity_matrix'))
        % Matrix is not symmetric ->symmetrize by (A+A')/2
        affinity_matrix = (affinity_matrix + affinity_matrix') / 2;
    end

    nrinstances = size(affinity_matrix,1);
        
    % Check if distance or affinity matrix
    if sum(diag(affinity_matrix)) < sum(diag(affinity_matrix,2))
        % disp('Input is distance matrix - Convert!');
        affinity_matrix = max(affinity_matrix(:)) - affinity_matrix;
    end
    
    % Ensure that the self-similarity is the most similar
    affinity_matrix(logical(speye(size(affinity_matrix)))) = max(affinity_matrix(:))+eps;
    
    % Find closest k elements
    labels_tab = tabulate(labels);
    max_nr_labels = max(labels_tab(:,2));
    [~, loc] = maxk(affinity_matrix, floor(REL_RANGE*max_nr_labels), 2 );
    
    all_counts = 0;
    required_counts = 0;
    for id = 1 : nrinstances
        % Find instances of same class
        correct_ids = find(labels == labels(id));
        required_counts = required_counts + length(correct_ids);
        
        % Calculate rel. bullseye score
        positions = loc(id,1:floor(REL_RANGE*length(correct_ids)));
        
        counts = length(intersect(correct_ids,positions));
        all_counts = all_counts + counts;
    end
    bullseye = (all_counts / required_counts) * 100;
   
   
        
    