function D = computePairDistances(d,groups)
%Computes pairwise euclidean distances between vectors indicated in paths

opts = d.opts;

if exist(fullfile(opts.expDir,'D.mat'),'file') == 0
  codespath = fullfile(d.path.codes,d.ex);
  nIm = numel(groups); 
  X = zeros(nIm,opts.repSize,'single');
  
  for i = 1:nIm
    code = load(fullfile(codespath,[num2str(i) '.mat']));
    X(i,:) = code.code;
  end
  
  %Compute and save pariwise euclidean distances
  D = squareform(pdist(X,'cosine'));
  save(fullfile(opts.expDir,'D.mat'),'D');
  
  disp('Distances computed');
else
  load(fullfile(opts.expDir,'D.mat'));
  disp('Distances loaded');
end




