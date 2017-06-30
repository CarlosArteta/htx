function E = findErichments(d,D,H)
%find erichments of the properties in H
%H is a list of hypotheses and positive samples to them.

opts = d.opts;

if exist(fullfile(opts.expDir,'E.mat'),'file')==0
  
  N=size(D,1);
  neighbs = cell(1,N);
  
  D = D / max(D(:));
  pMatrix = d2p_par(D .^ 2,d.prepEnrch,d.perpTol);
  
  for s = 1:N
    sample = pMatrix(s,:);
    [sorted,idxs] = sort(sample,'descend');
    N_s = find(cumsum(sorted) < d.probTH,1,'last');
    neighbs{s} = [s idxs(1:N_s)];
  end
  
  %%
  numHypot = size(H,1);
  numNeighbs = numel(neighbs);
  pVals = ones(numHypot,numNeighbs);
  pTH = d.pTH;
  
  for hypot = 1:numHypot
    disp(['Testing hypothesis ' num2str(hypot) '/' num2str(numHypot)]);
    posSamp = H{hypot,1};
    
    %find all the neighbourhoods with positive samples
    c = cellfun(@(x)(ismember(posSamp,x)),neighbs,'UniformOutput',false);
    numPosSamplesInNeigh = cellfun(@nnz,c);
    neighsWithPos = find(numPosSamplesInNeigh>0);
    
    %compute p-value using hypergeometric test for each cluster
    K = numel(posSamp);
    
    for i = neighsWithPos
      x = numPosSamplesInNeigh(i); %samples in this cluster with the property activated
      n = numel(neighbs{i}); %number of samples in cluster
      pVals(hypot,i) = sum(hygepdf(x:n,N,K,n)) *...
        numHypot * numel(neighsWithPos);%bonferroni correction
      if pVals(hypot,i) < pTH
        disp(['Enrichment found with p-value: ' num2str(pVals(hypot,i))]);
      end
    end
  end
  
  %% Get most enriched
  [h,c] = find(pVals < d.pTH);
  v = pVals(sub2ind(size(pVals),h,c));
  [~,topEnrichments] = sort(v, 'ascend');
  topEnrichmentsHypot = h(topEnrichments);
  uniqueTopHypot = unique(topEnrichmentsHypot);
  highestEnrichPerHypot = zeros(numel(uniqueTopHypot),1);
  E = [];
  disp('------Top Enrichments------');
  
  for i = 1:numel(uniqueTopHypot)
    
    %Get the most enriched cluster for this hypothesis
    [minPinThis,mostEnrichedClusterForHypothesis] = ...
      min(pVals(uniqueTopHypot(i),:));
    %Get all the samples with the property
    posSamp = H{uniqueTopHypot(i),1};
    %Get the (index of) samples in clusters enriched with the property
    HEcluster = neighbs{mostEnrichedClusterForHypothesis(1)};
    %Get the samples within the enriched clusters that contained the property
    posSampInHECluster = posSamp(ismember(posSamp,HEcluster));
    %Get all the clusters enriched with this hypothesis and merge them
    mergedClusters = unique(cell2mat(neighbs(c(h==uniqueTopHypot(i)))));
    
    E(i).hypothesis =  H{uniqueTopHypot(i),2};
    E(i).description = H{uniqueTopHypot(i),3};
    E(i).pVal = minPinThis;
    E(i).posSamp = posSamp;
    E(i).posSampInHECluster = posSampInHECluster;
    E(i).HEcluster = HEcluster;
    E(i).mergedClusters = mergedClusters;
    
    disp(' ');
    disp(['Hypothesis: ' E(i).hypothesis]);
    disp(['Best p-value: ' num2str(E(i).pVal)]);
    disp(['Clusters with this characteristic: ' num2str(mostEnrichedClusterForHypothesis')]);
    
  end
  save(fullfile(opts.expDir,'E.mat'),'E');
else
  load(fullfile(opts.expDir,'E.mat'),'E');
end
