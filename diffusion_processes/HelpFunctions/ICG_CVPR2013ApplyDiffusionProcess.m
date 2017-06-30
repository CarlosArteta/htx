function [bullseye nr_iterations] = ICG_CVPR2013ApplyDiffusionProcess(dataset_name, aff_matrix, ...
             labels, diffusion_process, BULLSEYE_RANGE, NR_OF_KNN, ALPHA_VALUE)
% [bullseye nr_iterations] = ICG_CVPR2013ApplyDiffusionProcess(dataset_name, aff_matrix, ...
%             labels, diffusion_process, BULLSEYE_RANGE, NR_OF_KNN, ALPHA_VALUE) 
%   ICG_CVPR2013ApplyDiffusionProcess applies a diffusion process to the affinity matrix
%   according to the framework described in the CVPR 2013 paper (see below)
%
%   Parameter
%   ---------
%   dataset_name ... Name of data_set
%   aff_matrix ... NxN affinity matrix (higher is more similar)
%   labels ... Ground Truth labels for evaluating the bullseye score
%   diffusion process ... 1x3 vector defining the diffusion variant
%       diffusion process(1) ... INIT: (1) aff_matrix (2) I (3) P (4) P_knn
%       diffusion process(2) ... TRANSITION: (1) P (2) P_pers (3) P_nc 
%                                            (4) P_knn (5) P_ds (6) aff_matrix
%       diffusion process(2) ... UPDATE (1) Random Walk (2) Tensor (3) Game Theory 
%   BULLSEYE_RANGE ... Number of first ranked elements to consider 
%   NR_OF_KNN ... Number of nearest neighbors
%   ALPHA_VALUE ... Value for alpha, for pesonalized dynamics
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
    
	% Set Default parameters
    if ~exist('NR_OF_KNN','var'),
        NR_OF_KNN = 10;
    end
    if ~exist('ALPHA_VALUE','var'),
        ALPHA_VALUE = 0.85;
    end

    bullseye = 0;
    nr_iterations = 0;
       
    %% Initialization   
    switch diffusion_process(1)
        case 1
            % Affinity matrix
            init_mat = aff_matrix;
        case 2
            % Identity matrix
            init_mat = eye(size(aff_matrix));
        case 3
            % transition matrix 
            P = ICG_MatNormalizeRow(aff_matrix);
            init_mat = P;
        case 4
            % kNN Transition Matrix
            P = ICG_MatNormalizeRow(aff_matrix);
            [~ , knn_ids] = sort(P,2,'descend');
            P_red = zeros(size(aff_matrix));
            for iter_nr = 1 : size(aff_matrix,1)
                P_red(iter_nr,knn_ids(iter_nr,1:NR_OF_KNN)) = P(iter_nr,knn_ids(iter_nr,1:NR_OF_KNN));
            end
            init_mat = ICG_MatNormalizeRow(P_red);
        otherwise 
            disp('diffusion_process(1)==Initialization has to be in range 1-4');
            return;
    end
    
    %% Transition Matrix
    P = ICG_MatNormalizeRow(aff_matrix);
    switch diffusion_process(2)
        case 1
            % Standard P
            trans_mat = P;
        case 2
            % Personalized Page Rank
            M_pers = speye(size(aff_matrix));
            P_pers = ( (speye(size(aff_matrix,1)) - ALPHA_VALUE*P') ...
                \ M_pers ).* (1-ALPHA_VALUE);
            trans_mat = P_pers';
        case 3
            % Normalized Cut transition matrix
            trans_mat = ICG_MatNormalizedCuts(aff_matrix);
        case 4
            % kNN P_red
            [~ , knn_ids] = sort(P,2,'descend');
            P_red = zeros(size(aff_matrix));
            for iter_nr = 1 : size(aff_matrix,1)
                P_red(iter_nr,knn_ids(iter_nr,1:NR_OF_KNN))=P(iter_nr,knn_ids(iter_nr,1:NR_OF_KNN));
            end
            P_red = ICG_MatNormalizeRow(P_red);
            trans_mat = P_red;
        case 5
            % Dominant Set Neighbors
            % ****Pre-Calculated**** due to enormous computation complexity
            % Based on "Affinity Learning on a Tensor Product Graph
            % with Applications to Shape and Image Retrieval"
            % Xingwei Yang and Longin Jan Latecki, CVPR 2011
            % Params
            %Thresh = 0.0001;
            %stop_th = 0.000000001;
            %select_th = 0;
            %trans_mat = DominantNeighbors(aff_matrix,Thresh, stop_th, select_th,NR_OF_KNN);
            %trans_mat = trans_mat.* aff_matrix;
            %trans_mat = ICG_MatNormalizeRow(trans_mat);
            %save([dataset_name '_DOMINANT_NEIGHBORS'],'trans_mat');
            load(['./Data/' dataset_name '_DOMINANT_NEIGHBORS']);
        case 6
            trans_mat = aff_matrix;
        otherwise 
            disp('diffusion_process(2) has to be in range 1-6');
    end
    
    
    %% Diffusion Process starts here
    curr_mat = init_mat;
    
    % Maximum number of iterations (Not important, never reached)
    NR_ITERATIONS = 15;
    bullseye = NaN(NR_ITERATIONS,1);
    
    % Save ranking to define the stopping criterion
    [~ , old_ranks] = sort(curr_mat,2,'descend');
    
    average_nr_of_changed_ranks = zeros(1,NR_ITERATIONS);
    for iter_nr = 1 : NR_ITERATIONS
        % Apply diffusion step
        switch diffusion_process(3)
            case 1
                % Standard
                curr_mat = ALPHA_VALUE * trans_mat * curr_mat + (1-ALPHA_VALUE) ...
                   * eye(size(trans_mat)); 
            case 2
                % Tensor
                curr_mat = trans_mat * curr_mat * trans_mat';
            case 3
                % Game Theory
                new_matrix = curr_mat * trans_mat .* curr_mat';
                degree = sum(new_matrix,2);
                degree(degree < 1/size(new_matrix,1)) = 1/size(new_matrix,1);
                D = diag(degree);
                curr_mat = D^-1 * new_matrix;
        end
        
        % Get current bullseyerating
        bullseye(iter_nr) = ICG_RetrievalBullsEyeScore(curr_mat,labels,BULLSEYE_RANGE);
         
        %  Check how much is changed in the ranking
        [~ , ranks] = sort(curr_mat,2,'descend');
        similar = zeros(size(ranks,1),1);
        for s = 1 : size(ranks,1)
            similar(s) = length(intersect(ranks(s,1:BULLSEYE_RANGE),old_ranks(s,1:BULLSEYE_RANGE)));
        end
        old_ranks = ranks;
        average_nr_of_changed_ranks(iter_nr) = mean(similar);
        
        % Stopping criterion, checks change in rankings
        STOPPING_CRITERION = 0.3;
        % Game Theory diffusion should at least diffuse for 2 iterations
        if diffusion_process(3) == 1
            MIN_DIFF_ROUNDS = 2;
        else
            MIN_DIFF_ROUNDS = 1;
        end
        
        % Check if rankings converged
        if (iter_nr > MIN_DIFF_ROUNDS) && (average_nr_of_changed_ranks(iter_nr) - average_nr_of_changed_ranks(iter_nr-1) < STOPPING_CRITERION)
            bullseye(isnan(bullseye)) = [];
            bullseye(end) = [];
            break;
        end
        
    end
    nr_iterations = iter_nr;
    