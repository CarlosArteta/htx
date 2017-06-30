function bullseye = ICG_RetrievalBullsEyeScore(affinity_matrix,labels,bullseye_range)
% bullseye = ICG_RetrievalBullsEyeScore(affinity_matrix,labels,bullseye_range)
%   ICG_RetrievalBullsEyeScore calculates the bullseye score (a retrieval
%   quality measure, i.e. the average percentage of instances of the same class as
%   the query within the bullseye_range first elements
%
%   Paramter
%   --------
%   affinity_matrix ... NxN matrix of affinities (higher is more similar!)
%   labels ... the ground truth labels
%   bullseye_range ... the number of of first-rank elemwnts to consider
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

    if any(any(affinity_matrix ~= affinity_matrix'))
        % Matrix is not symmetric -> symmetrize by (A+A')/2
        affinity_matrix = (affinity_matrix + affinity_matrix') / 2;
    end

    nrinstances = size(affinity_matrix,1);
    
    % Check if distance or affinity matrix
    % !!!Assumes that self-distances are always 0, which is valid for 
    % affinity matrices considered in the experiments, but might be 
    % not fulfilled by some!!!
    if sum(diag(affinity_matrix)) < sum(diag(affinity_matrix,2))
        % disp('Input is distance matrix - Convert!');
        affinity_matrix = max(affinity_matrix(:)) - affinity_matrix;
    end
    
    % Ensure that the self-affinity is the most similar
    affinity_matrix(logical(eye(size(affinity_matrix)))) = max(affinity_matrix(:))+eps;
    
    all_counts = 0;
    required_counts = 0;
    for id = 1 : nrinstances
        % Find instances of same label
        correct_ids = find(labels == labels(id));
        required_counts = required_counts + length(correct_ids);
        
        % rank the elements
        [ ~ , positions] = sort(affinity_matrix(id,:),'descend');
        
        % count the number of elements with same class label
        counts = length(intersect(correct_ids,positions(1:bullseye_range)));
        all_counts = all_counts + counts;
    end
    bullseye = (all_counts / required_counts) * 100;
   
   
        
    