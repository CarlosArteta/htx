function genVisualizations(d,D)
%Generate sequencial tSNE embeddings with diffusion processes

opts = d.opts;

if exist(fullfile(opts.expDir,...
      [num2str(d.vis.nDims) 'Dvis_knnDiff'...
      num2str(d.vis.KNNrange(end),'%02d') '.mat']),'file')==0
    
  disp('Computing visualizations');
  
  %Ensure matrix conditioning
  D(1:size(D,1) + 1:end) = 0;
  D = double(D);
  D = D/max(D(:));
  
  %Compute starting point for visualizations
  xy = tsne_d(D);
  
  %Diffusion-visualization loop
  for knn = d.vis.KNNrange
    aMatrix = applyDiffusionProcess(D,nan,knn,0);
    aMatrix = aMatrix/max(aMatrix(:));
    pMatrix = a2p(aMatrix,d.vis.perp,d.vis.perpTol);
    xy = tsne_p(pMatrix, [], xy);
    save(fullfile(opts.expDir, [num2str(d.vis.nDims)...
      'Dvis_knnDiff' num2str(knn,'%02d') '.mat']),'xy');
  end
  disp('Embedding sequences generated');
else
  disp('Embedding generation skipped');
end
