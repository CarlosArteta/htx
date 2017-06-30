function [groups,index] = buildIndex(d,imdb)
%Build auxiliary structures groups and index

if exist(d.path.groups,'file') == 0 || exist(d.path.index,'file') == 0
  groups = cell(floor(length(imdb)/d.meta.imPerComp),1);
  index = cell(floor(length(imdb)/d.meta.imPerComp),4);
  thisPlate = imdb(1).plateID;
  thisWell = imdb(1).wellpos;
  thisRole = imdb(1).role;
  gIdx = 1;
  index{1,2} = imdb(1).folder;
  index{1,3} = imdb(1).plateID;
  index{1,4} = thisWell;
  index{1,5} = thisRole;
  index{1,6} = imdb(1).treatment;
  for i = 1:floor(length(imdb))
    
    [~,filename] = fileparts(imdb(i).filename);
    
    if strcmp(imdb(i).plateID,thisPlate) && ...
        strcmp(imdb(i).wellpos,thisWell)
      groups{gIdx} = [groups{gIdx} ; i];
      index{gIdx,1} = [index{gIdx,1} ; {filename}]; 
    else
      gIdx = gIdx + 1;
      thisPlate = imdb(i).plateID;
      thisWell = imdb(i).wellpos;
      thisRole = imdb(i).role;
      groups{gIdx} = i;
      index{gIdx,1} = {filename};
      index{gIdx,2} = imdb(i).folder;
      index{gIdx,3} = thisPlate;
      index{gIdx,4} = thisWell;
      index{gIdx,5} = thisRole;
      index{gIdx,6} = imdb(i).treatment;
    end
    
  end
  save(d.path.groups,'groups');
  save(d.path.index,'index');
else
  load(d.path.groups,'groups');
  load(d.path.index,'index');
end