function [out,loc] = minmaxk_sort(D,k,type,dim)

if nargin<4 
  dim = 1;
end
if dim>2
  error('dim must be 1 or 2');
end

if dim == 2
  D = D';
end

out = zeros(k,size(D,dim),'like',D);
loc = zeros(k,size(D,dim),'like',D);

for c = 1:size(D,2)
  thisCol = D(:,c);
  if strcmp(type,'min')
    [thisCol,thisLoc] = sort(thisCol,'ascend');
  elseif strcmp(type,'max')
    [thisCol,thisLoc] = sort(thisCol,'descend');    
  else
    error('Unrecognized option');
  end
  out(:,c) = thisCol(1:k);
  loc(:,c) = thisLoc(1:k);
end

if dim == 2
  out = out';
  loc = loc';
end
