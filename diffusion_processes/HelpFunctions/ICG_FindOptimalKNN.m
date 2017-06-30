function [bullseye_scores best_k best_bullseye baseline] = ICG_FindOptimalKNN(dataset_id, visualize)
% [bullseye_for_k best_k best_bullseye baseline] = ICG_FindOptimalKNN(dataset_id,visualize)
%   ICG_FindOptimalKNN, tests different k-values for the
%   building the local affinity neighborhood graph
%
%   Parameter
%   ---------
%   dataset_id ... ID of data set
%       1 ... MPEG-7
%       2 ... ORL
%       3 ... YALE
%   visualize ... Show plot for bullseye score in dependence on kNN
%       (Default: false)
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

    if ~exist('visualize','var'),
        visualize = false;
    end

    % Fix diffusion process - Adapt here if you want to see dependency
    % for a different diffusion variant
    diffusion_process = [4 4 2];

    Diff = [];labels = [];sigma_range = [];
    BULLSEYE_RANGE = 0;dataset_name='';
    
     switch dataset_id
        case 1
            load('./Data/MPEG7');
        case 2
            load('./Data/ORL');
        case 3
            load('./Data/YALE');
        otherwise
            disp('dataset_id has to be 1->MPEG-7 or 2->ORL or 3->YALE');
            return;
    end
    
    % Fix KNN Range
    KNN_RANGE = 2 : 15;
    
    bullseye_for_k = zeros(length(KNN_RANGE),length(sigma_range));
   
    % Simply replace parfor with for, if no multi-core is 
    % available, or with the desired number of cores to use
    matlabpool open 2;
    parfor NR_OF_KNN = KNN_RANGE(1):KNN_RANGE(end)
        help_values = zeros(length(sigma_range),1);
        for sigma = 1 : length(sigma_range) 
            % Normalize distance matrix
            aff_matrix = exp((-(Diff.^2)) * (2*sigma_range(sigma)^2));
            
            % Apply Diffusion
            [bullseye_scores nr_iterations] = ICG_CVPR2013ApplyDiffusionProcess(dataset_name, aff_matrix, ...
                 labels, diffusion_process, BULLSEYE_RANGE, NR_OF_KNN);
            disp(['*********Found ' num2str(bullseye_scores(end)) '% of ' num2str(size(aff_matrix,1)) ...
             ' in ' num2str(nr_iterations) ' iterations!***']);
            
         help_values(sigma) = bullseye_scores(end);
        end
        bullseye_for_k(NR_OF_KNN-1,:) = help_values;
    end
    matlabpool close;
    
    % Select optimal sigma for each K
    bullseye_scores = max(bullseye_for_k,[],2);
    [best_bullseye best_k] = max(bullseye_scores);
    
    bullseye_scores = [KNN_RANGE' bullseye_scores];
    
    % Estimate baseline
    baseline = ICG_RetrievalBullsEyeScore(Diff,labels,BULLSEYE_RANGE);
    
    disp(['Optimal K value: ' num2str(best_k) ' yields a bullseye score of ' ...
         num2str(best_bullseye) ' for diffusion variant: ' num2str(diffusion_process)]);
    
    if (visualize)
        % Draw Figure
        close all;
        figure1 = figure;
        axes1 = axes('Parent',figure1,'FontSize',30);
        box(axes1,'on');
        plot(bullseye_scores(:,1), bullseye_scores(:,2),'Parent',axes1,'LineWidth',8,'DisplayName',dataset_name);
        hold(axes1,'all');
        xlabel('Number of kNN','FontSize',30);
        ylabel('Bullseye Rating','FontSize',30);
        legend(axes1,'show');
        units=get(figure1,'units');
        set(figure1,'units','normalized','outerposition',[0 0 1 1]);
        set(figure1,'units',units);
        line([KNN_RANGE(end); 0], [baseline ; baseline],'Parent',axes1,'LineWidth',3,'Color',[1 0 0]);
    end
