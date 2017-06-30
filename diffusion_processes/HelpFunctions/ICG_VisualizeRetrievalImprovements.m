function ICG_VisualizeRetrievalImprovements(query_ids,old_aff,new_aff,labels)
% ICG_VisualizeRetrievalImprovements visualizes results for some specific 
%   query IDs, ranking is shown
%
%   Parameter
%   ---------
%   query_ids ... Px1 vector of IDs of query elements to visualize 
%   old_aff ... NxN affinity matrix before diffusion
%   new_aff ... NxN afffinity matrix after diffusion
%   labels ... Ground truth labels Nx1 vector
%   
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

    warning off all;

    % specify path to images 
    image_path  = './Images/MPEG7/';
    
    % obtain rankings
    [~, poses_old] = sort(old_aff,2,'descend');
    [~, poses_new] = sort(new_aff,2,'descend');

    all_image_files = ICG_ListFilenames(image_path,'*.gif');
   
    NR_OF_ELEMS_TO_VISUALIZE = 20;
    for id = 1 :  numel(query_ids)
        corr_labels = labels == labels(query_ids(id));
        
        old_ranking = poses_old(query_ids(id),1:NR_OF_ELEMS_TO_VISUALIZE);
        new_ranking = poses_new(query_ids(id),1:NR_OF_ELEMS_TO_VISUALIZE);
        
        % Adapt all images to the same size for visualiztaion
        % Elements of same category are shown in green
        % Elements of different category are shown in red
        image_list_old = cell(length(old_ranking),1);
        image_list_new = cell(length(new_ranking),1);
        for c = 1 : length(old_ranking)
            curr_img = imread([image_path all_image_files{old_ranking(c)}]);
            curr_img = imresize(curr_img, [256 256]);
            bright_img = uint8(padarray(curr_img,[20 20],255));
            dark_img = uint8(padarray(curr_img,[20 20],0));
            if (ismember(old_ranking(c),find(corr_labels)))
                image_list_old{c}(:,:,1) = dark_img;
                image_list_old{c}(:,:,2) = bright_img;
                image_list_old{c}(:,:,3) = dark_img;
            else
                image_list_old{c}(:,:,1) = bright_img;
                image_list_old{c}(:,:,2) = dark_img;
                image_list_old{c}(:,:,3) = dark_img;
            end
            curr_img = imread([image_path all_image_files{new_ranking(c)}]);
            curr_img = imresize(curr_img, [256 256]);
            bright_img = uint8(padarray(curr_img,[20 20],255));
            dark_img = uint8(padarray(curr_img,[20 20],0));
            if (ismember(new_ranking(c),find(corr_labels)))
                image_list_new{c}(:,:,1) = dark_img;
                image_list_new{c}(:,:,2) = bright_img;
                image_list_new{c}(:,:,3) = dark_img;
            else
                image_list_new{c}(:,:,1) = bright_img;
                image_list_new{c}(:,:,2) = dark_img;
                image_list_new{c}(:,:,3) = dark_img;
            end
        end
       
        all_images = cat(1 , image_list_old , image_list_new);
        mon_struct = zeros([size(all_images{1}) length(all_images)]);
        for img_id = 1 : length(all_images)
            mon_struct(:,:,:,img_id) = all_images{img_id};
        end
        montage(mon_struct,'size',[2 numel(old_ranking)])
        title(['Rankings for element ' num2str(query_ids(id)) ' obtained before ' ...
            ' (first row) and after (second row) diffusion! -- Press to continue!'],'Color','blue','FontSize',24);
        ICG_MaximizeFigure;drawnow;
        disp('Retrieval results shown in figure - press to continue');
        pause;
    end
    close all;