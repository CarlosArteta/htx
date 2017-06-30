%Setup data and IMDB for BBBC021v1

%Paths
rootpath = '';
dpath = fullfile(rootpath,'BBBC021_xxuM_MCF7','metadata');
linesToRead = 1000;
annotFormat = '%q %q %q %q %q %q %q %q %q %q %q %q %q';

%Tiff tags for packing images
ti.bitsPerSamp = 16;
ti.sampPerpixel = 3;
ti.nRows = 1024;
ti.nCols = 1280;

%Read smiles
try
  fid1 = fopen([dpath, '/BBBC021_v1_compound.csv']);
catch
  error('could not open file');
end
S = textscan(fid1,'%q %q',1,'Delimiter',','); %header
S = textscan(fid1,'%q %q',113,'Delimiter',',');

%Read image info
try
  fid = fopen([dpath, '/BBBC021_v1_image.csv']);
catch
  error('could not open file');
end

lineCounter = 1;
f = 1; %field counter
compIdx = 1;
compList = {};

C = textscan(fid,annotFormat,1,'Delimiter',','); %header

while ~feof(fid)  
  C = textscan(fid,annotFormat,linesToRead,'Delimiter',',');
  
  for c = 1:numel(C{1})
    
    %DAPI channel
    filen1 =  C{3}{c};
    sep = strfind(C{4}{c},'/');
    foldern1 =  C{4}{c}(sep+1:end);
    if exist(fullfile(dpath,foldern1,filen1),'file')==0
      im1 = [];
    else
      im1 = imread(fullfile(dpath,foldern1,filen1));
    end
    
    %Tubulin channel
    filen2 =  C{5}{c};
    sep = strfind(C{6}{c},'/');
    foldern2 =  C{6}{c}(sep+1:end);
    if exist(fullfile(dpath,foldern2,filen2),'file')==0
      im2 = [];
    else
      im2 = imread(fullfile(dpath,foldern2,filen2));
    end
    
    %Actin channel
    filen3 =  C{7}{c};
    sep = strfind(C{8}{c},'/');
    foldern3 =  C{8}{c}(sep+1:end);
    if exist(fullfile(dpath,foldern3,filen3),'file')==0
      im3 = [];
    else
      im3 = imread(fullfile(dpath,foldern3,filen3));
    end
    
    newName =  [filen1(1:end-4) '_stack.tif'];
    newFolder = foldern1;
    imdb(f).filename = newName;
    imdb(f).folder = newFolder;
    
    if ~isempty(im1)
      im = cat(3,im1,im2,im3);
      t = Tiff(fullfile(dpath,newFolder,newName),'w');
      t.setTag('Photometric',Tiff.Photometric.MinIsBlack);
      t.setTag('BitsPerSample',ti.bitsPerSamp);
      t.setTag('SamplesPerPixel',ti.sampPerpixel);
      t.setTag('ImageLength',ti.nRows);
      t.setTag('ImageWidth',ti.nCols);
      t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
      t.write(im);
      t.close();
    end
    
    %%
    compound = C{12}{c};
    if strcmp(compound,'DMSO')
      imdb(f).role = 'control';
    else
      imdb(f).role = 'treated';
    end
    
    imdb(f).treatment = [compound '-' C{13}{c}];
    
    imdb(f).wellpos = C{10}{c};
    wellsite = strfind(filen1,'_s');
    imdb(f).wellsite = str2double(filen1(wellsite+2));
    imdb(f).plateID = C{9}{c};
    
    matchComp = find(ismember(compList,imdb(f).treatment));
    
    if numel(matchComp) > 1
      warning('Repeated entry in compound list');
    end
    
    if isempty(matchComp)
      compList{compIdx} = imdb(f).treatment;
      imdb(f).class = compIdx;
      compIdx = compIdx + 1;
    else
      imdb(f).class = matchComp;
    end
    
    %WARNING: delete other tiff files
    if ~isempty(im1)
      delete(fullfile(dpath,foldern1,filen1))
      delete(fullfile(dpath,foldern2,filen2))
      delete(fullfile(dpath,foldern3,filen3))
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    f = f + 1;
  end
  
  disp(['Line counter: ' num2str(lineCounter*linesToRead)]);
  lineCounter = lineCounter + 1;
  
end

%Set plate class
[~,~,plateClass] = unique({imdb(:).plateID});
for i = 1:numel(imdb)
  imdb(i).plateclass = plateClass(i);
end

%Finish
save([dpath, '/BBBC021_xxuM_MCF7_imdb.mat'],'imdb');
save([dpath, '/BBBC021_xxuM_MCF7_compList.mat'],'compList');
disp(['--Added ' num2str(f) ' fields--']);

