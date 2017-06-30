function varargout = htxGUI(varargin)
% htxGUI MATLAB code for htxGUI.fig
%      htxGUI, by itself, creates a new htxGUI or raises the existing
%      singleton*.
%
%      H = htxGUI returns the handle to a new htxGUI or the handle to
%      the existing singleton*.
%
%      htxGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in htxGUI.M with the given input arguments.
%
%      htxGUI('Property','Value',...) creates a new htxGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before htxGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to htxGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help htxGUI

% Last Modified by GUIDE v2.5 12-May-2017 11:51:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
  'gui_Singleton',  gui_Singleton, ...
  'gui_OpeningFcn', @htxGUI_OpeningFcn, ...
  'gui_OutputFcn',  @htxGUI_OutputFcn, ...
  'gui_LayoutFcn',  [] , ...
  'gui_Callback',   []);
if nargin && ischar(varargin{1})
  gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
  [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
  gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before htxGUI is made visible.
function htxGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to htxGUI (see VARARGIN)
global S
set(handles.status_text,'String','Status: Loading');
d = varargin{1};
S.data = d;
S.imdir = d.path.normdata;
S.expdir = d.opts.expDir;
S.index = varargin{2};
S.groups = varargin{3};
S.H = varargin{4};
S.D = varargin{5};
S.E = varargin{6};
S.parmName = 'knn';

dotsfiles = dir(fullfile(S.expdir,'2D*'));
[~,dotsfiles] = cellfun(@fileparts, {dotsfiles.name}, 'UniformOutput',false);
descIdx = 1:numel(dotsfiles);
S.dotsfiles = dotsfiles(sort(descIdx,'descend'));
S.parms = zeros(1,numel(S.dotsfiles));
meta = load(d.path.imdbmeta);
S.imdbmeta = meta.imdbmeta;

for i = 1:numel(S.dotsfiles)
  f = S.dotsfiles{i};
  p = strfind(f,S.parmName);
  S.parms(i) = str2double(f(p+length(S.parmName):end));
end

load(fullfile(S.expdir,S.dotsfiles{1}));
S.dots = xy;

% Choose default command line output for htxGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes htxGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%get compound, negative control and positive control indexes
types = zeros(1,size(S.index,1));
for i = 1:length(types)
  if strcmp(S.index{i,5},'mock') || strcmp(S.index{i,5},'control')
    types(i) = -inf;
  end
end

S.comps = find(~isinf(types));
S.negs = find(types == -Inf);
S.pos = find(types == Inf);

%Initialize plot
axisLim = findAxisLim(S);
axes(handles.axes1);
axis(axisLim);
set(handles.axes1,'visible','off');
set(handles.axes2,'visible','off');

%Initialize variables for UI sample selection 
S.inComp = false(numel(S.comps),1);
S.inNegs = false(numel(S.negs),1);
S.inPos = false(numel(S.pos),1);
S.inNegComp = false(numel(S.comps),1);
S.inNegNegs = false(numel(S.negs),1);
S.inNegPos = false(numel(S.pos),1);

%Initialize UI
set(handles.btn_compute_enrich, 'Enable', 'off');
set(handles.btn_compute_saliency, 'Enable', 'off');
set(handles.btn_select_neg_cluster, 'Enable', 'off');
set(handles.btn_clear, 'Enable', 'off');
dcm_obj = datacursormode(gcf); %change cursor update function
set(dcm_obj,'UpdateFcn',{@mydotupdatefcn,S.dots,S.index,S.imdir,handles})
set(handles.uipanel3, 'title', ['Granularity: ' num2str(1)]);
if ~isempty(S.E) %enrichment pop-up menu
S.E = sortE(S.E,2); %sort by p-value
for i = 1:numel(S.E)
  desc = [S.E(i).hypothesis '/' S.E(i).description];
  if numel(desc) > 30
    desc = [desc(1:27) '...'];
  end
  popstring{i} = [desc ' - p=' num2str(S.E(i).pVal,'%1.2e')];
end
set(handles.pop_enrichments,'String',popstring);
end
set(handles.radbtn_name,'Value',false);
set(handles.radbtn_pval,'Value',true);

%Configure slider bars
set(handles.slider1,'max', numel(S.parms),'min', 1,'value', 1,...
  'sliderStep', [1/(numel(S.parms)-1) 1/(numel(S.parms)-1)]);
set(handles.slider2,'max', numel(S.groups{1}),'min', 1,'value', 1,...
  'sliderStep', [1/(numel(S.groups{1})-1) 1/(numel(S.groups{1})-1)]);
if ~isempty(S.E)
set(handles.slider3,'max', numel(S.E),'min', 1,'value', 1,...
  'sliderStep', [1/(numel(S.E)-1) 1/(numel(S.E)-1)]);
end

plot_visualization(handles,S);
set(handles.status_text,'String','Status: Visualizing Data');

end

% --- Outputs from this function are returned to the command line.
function varargout = htxGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

function txt = mydotupdatefcn(empt,event_obj,dots,index,imPath,handles)
% Customizes text of data tips
position = get(event_obj,'Position');
idx = find(dots(:,1) == position(1) & dots(:,2) == position(2));
set(handles.txt_selsample,'String',num2str(idx));
plate = index{idx,3};
row = index{idx,4}(1);
col = index{idx,4}(2:3);
comp = index{idx,6};
txt = {comp};

modifiers = get(handles.figure1,'currentModifier');
ctrlIsPressed = ismember('control',modifiers);
showCheck = get(handles.checkbox_show,'Value');

if ctrlIsPressed || showCheck
  frame = imread(fullfile(imPath, index{idx,2}, [index{idx,1}{1} '.jpg']));
  imshow(frame, 'Parent', handles.axes2);
  set(handles.plotted_sample_text,'String',...
    ['Plotted sample: Plate ' plate...
    ' - row ' num2str(row) ' - col ' num2str(col) ' - FOV 1']);
  set(handles.slider2,'Value',1);
end

set(handles.sel_sample_text,'String',['Selected sample: Plate ' plate...
  ' - row ' num2str(row) ' - col ' num2str(col), ...
  ' - treatment: ',comp]);
end

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global S

value = get(hObject,'Value');
load(fullfile(S.expdir, S.dotsfiles{round(value)}));
set(handles.uipanel3, 'title', ['Granularity: ' num2str(round(value))]);
set(handles.sel_sample_text,'String','Selected sample: None');

S.dots = xy;

%change cursor update function
dcm_obj = datacursormode(gcf);
set(dcm_obj,'UpdateFcn',{@mydotupdatefcn,S.dots,S.index,S.imdir,handles})

plot_visualization(handles,S);
end

function axisLim = findAxisLim(S)
maxX = 0;
maxY = 0;
for i = 1:numel(S.dotsfiles)
  load(fullfile(S.expdir, S.dotsfiles{i}));
  mx = max(abs(xy(:,1)));
  my = max(abs(xy(:,2)));
  if mx > maxX
    maxX = mx;
  end
  if my > maxY;
    maxY = my;
  end
end
axisLim = [-maxX-10 maxX+10 -maxY-10 maxY+10];
end

% --- Executes on button press in btn_select_cluster.
function btn_select_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to btn_select_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global S

axes(handles.axes1);
[x, y] = getline;
cla;

inComp = inpolygon(S.dots(S.comps,1),S.dots(S.comps,2),x,y);
inNegs = inpolygon(S.dots(S.negs,1),S.dots(S.negs,2),x,y);
inPos = inpolygon(S.dots(S.pos,1),S.dots(S.pos,2),x,y);

S.inComp = inComp;
S.inNegs = inNegs;
S.inPos = inPos;

plot_visualization(handles,S);

set(handles.btn_compute_enrich, 'Enable', 'on');
set(handles.btn_compute_saliency, 'Enable', 'on');
set(handles.btn_select_neg_cluster, 'Enable', 'on');
set(handles.btn_clear, 'Enable', 'on');
end

function plot_visualization(handles,S)
axes(handles.axes1);
cla;

hold on;

plot(S.dots(S.comps(~S.inComp & ~S.inNegComp),1), S.dots(S.comps(~S.inComp & ~S.inNegComp),2), '*r','MarkerSize',8,'LineWidth',2);
plot(S.dots(S.negs(~S.inNegs & ~S.inNegNegs),1), S.dots(S.negs(~S.inNegs & ~S.inNegNegs),2), 'ob','MarkerSize',6,'LineWidth',2);
plot(S.dots(S.pos(~S.inPos & ~S.inNegPos),1), S.dots(S.pos(~S.inPos & ~S.inNegPos),2), '+k','MarkerSize',8,'LineWidth',2);

plot(S.dots(S.comps(S.inComp),1), S.dots(S.comps(S.inComp),2), '*','color',[1 0.7 0.4],'MarkerSize',8,'LineWidth',2);
plot(S.dots(S.negs(S.inNegs),1), S.dots(S.negs(S.inNegs),2), 'oc','color',[0.5 0.5 0.5],'MarkerSize',6,'LineWidth',2);
plot(S.dots(S.pos(S.inPos),1), S.dots(S.pos(S.inPos),2), '+','color',[0.5 0.5 0.5],'MarkerSize',8,'LineWidth',2);

plot(S.dots(S.comps(S.inNegComp),1), S.dots(S.comps(S.inNegComp),2), '*','color',[0.2 0.2 0.2],'MarkerSize',8,'LineWidth',2);
plot(S.dots(S.negs(S.inNegNegs),1), S.dots(S.negs(S.inNegNegs),2), 'o','color',[0 0 0.5],'MarkerSize',6,'LineWidth',2);
plot(S.dots(S.pos(S.inNegPos),1), S.dots(S.pos(S.inNegPos),2), '+','color',[0.25 0.25 0.25],'MarkerSize',8,'LineWidth',2);

hold off;
set(gca,'visible','off');

%build legend
leg = {};
if ~isempty(S.comps) && any(~S.inComp & ~S.inNegComp)
  leg{end+1} = 'Compounds';
end
if ~isempty(S.negs) && any(~S.inNegs & ~S.inNegNegs)
  leg{end+1} = 'Neg. ctrls';
end
if ~isempty(S.pos) && any(~S.inComp & ~S.inNegComp)
  leg{end+1} = 'Pos. ctrls';
end
if any(S.inComp)
  leg{end+1} = 'Compounds selected';
end
if any(S.inNegs)
  leg{end+1} = 'Neg. ctrls selected';
end
if any(S.inPos)
  leg{end+1} = 'Pos. ctrls selected';
end
if any(S.inNegComp)
  leg{end+1} = 'Compounds selected for contrast';
end
if any(S.inNegNegs)
  leg{end+1} = 'Neg. ctrls selected for contrast';
end
if any(S.inNegPos)
  leg{end+1} = 'Pos. ctrls selected for contrast';
end

legend(leg,'location','northwest','fontsize',10);
end

% --- Executes on button press in btn_compute_enrich.
function btn_compute_enrich_Callback(hObject, eventdata, handles)
% hObject    handle to btn_compute_enrich (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global S

numHypot = size(S.H,1);
pVals = zeros(numHypot,1);
numExp = numHypot; %for bonferroni correction
pTH = 0.05;

inSel = [S.comps(S.inComp) S.pos(S.inPos) S.negs(S.inNegs)];
M = numel(S.comps) + numel(S.pos) + numel(S.negs);

set(handles.status_text,'String','Status: Testing Hypotheses');

for h = 1:numHypot
  disp(['Testing hypothesis ' num2str(h) '/' num2str(numHypot)]);
  posSamp = S.H{h,1};
  K = numel(posSamp);
  x = numel(find(ismember(inSel,posSamp))); %sampels in this cluster with the property activated
  N = numel(inSel); %number of samples in cluster
  pVals(h) = sum(hygepdf(x:N,M,K,N))*numExp;
end

enrichments = find((pVals <= pTH) & (pVals ~= 0));
[~,orderedEnrichments] = sort(pVals(enrichments));
enrichments = enrichments(orderedEnrichments);

tab = {};
for e = enrichments'
  disp(['Enrichment found for property ' S.H{e,2}...
    ' with p-value ' num2str(pVals(e))]);
  tab = [tab ; S.H{e,2} S.H{e,3} {pVals(e)}];
end

f = figure('Position',[100,100,600,400]);
title([num2str(numel(enrichments)) ' enrichments found']);
set(gca,'visible','off');
t = uitable(f);
t.Position = [20 50 550 300];
t.Data = tab;
t.ColumnWidth = {200 200 100};
t.ColumnName = {'Hypothesis','Description','P-value'};
axis off;

set(handles.status_text,'String','Status: Visualizing Data');

end

% --- Executes on button press in btn_retrieve.
function btn_retrieve_Callback(hObject, eventdata, handles)
% hObject    handle to btn_retrieve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global S

topk = 16;
idx = str2double(get(handles.txt_selsample,'String'));
sampsdist = S.D(idx,:);
[rvals,ridx] = sort(sampsdist,'ascend');

sz = [850 1150]; % figure size
screensize = get(0,'ScreenSize');
xpos = ceil((screensize(3)-sz(2))/2); 
ypos = ceil((screensize(4)-sz(1))/2); 

figure('Name','Retrieval','Position',[xpos, ypos, sz(2), sz(1)]);

pidx = 1;
for i = 1:topk
  frame = imread(fullfile(S.imdir, S.index{ridx(i),2}, [S.index{ridx(i),1}{1} '.jpg']));
  vl_tightsubplot(topk,i,'box','inner') ;
  imshow(frame); 
  text(10,10,[num2str(i) ') Dist: ' num2str(rvals(i),'%1.3f') ...
    ' - Idx: ' num2str(ridx(i)) ' - ' lower(S.index{ridx(i),6})],...
    'background','w',...
    'verticalalignment','top', ...
    'fontsize', 8) ;
  pidx = pidx + 1;
end

end

% --- Executes on button press in seeAll_btn.
function seeAll_btn_Callback(hObject, eventdata, handles)
% hObject    handle to seeAll_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global S

idx = str2double(get(handles.txt_selsample,'String'));

nF = size(S.index{idx,1});

for f = 1:nF(1)
  figure;
  frame = imread(fullfile(S.imdir, S.index{idx,2}, [S.index{idx,1}{f} '.jpg']));
  imshow(frame);
end

end

% --- Executes on button press in btn_compute_saliency.
function btn_compute_saliency_Callback(hObject, eventdata, handles)
% hObject    handle to btn_compute_saliency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global S

import dagnn.*
type = 'svm';
clust = ['cluster' get(handles.edit_cluster_name,'String')];
negs = 'ctrl';
suf = [clust '_' negs '_' type];

%compute classifier
newModelPath = fullfile(S.expdir, ['mainNetVis_' suf '.mat']);
if 1%exist(newModelPath,'file') == 0
  set(handles.status_text,'String','Status: Computing Classifier');
  drawnow;
  labels = zeros(numel(S.groups),1);
  posSamps = [S.comps(S.inComp) S.negs(S.inNegs) S.pos(S.inPos)];
  
  if ~any(S.inNegComp) && ~any(S.inNegNegs) && ~any(S.inNegPos)
    negSamps = find(strcmp(S.index(:,5),'control') |...
      strcmp(S.index(:,5),'mock'));
  else
    negSamps = [S.comps(S.inNegComp) S.negs(S.inNegNegs) S.pos(S.inNegPos)];
  end
  
  labels(negSamps) = 1;
  labels(posSamps) = 2;
  FC = computeFC(S.data,labels);
  modelPath = fullfile(S.expdir, 'mainNetVis.mat');
  net = load(modelPath);
  net = dagnn.DagNN.loadobj(net);
  
  net.addLayer('L2', ...
    dagnn.LRN('param',[3072*2 0 1 0.5]), ...
    'code', ...
    'code_n');
  
  lp = [1 1 1024*3 2 1 0]; %Params of the block
  name = 'fc1';
  block = Conv();
  block.size = [lp(1) lp(2) lp(3) lp(4)];
  block.hasBias = false;
  block.opts{1} = 'cuDNN';
  block.pad = lp(6);
  block.stride = lp(5);
  
  inputs = {'code_n'};
  outputs = {'prediction'};
  
  params = struct(...
    'name', {}, ...
    'value', {}, ...
    'learningRate', [], ...
    'weightDecay', []);
  
  params(1).name = sprintf('%sf',name);
  params(1).value = reshape(FC,lp(1), lp(2), lp(3), lp(4));
  params(1).learningRate = 1;
  params(1).weightDecay = 1;
  
  net.addLayer(...
    name, ...
    block, ...
    inputs, ...
    outputs, ...
    {params.name}) ;
  
  findex = net.getParamIndex(params(1).name);
  net.params(findex).value = params(1).value;
  net.params(findex).learningRate = params(1).learningRate;
  net.params(findex).weightDecay = params(1).weightDecay;
  
  net_ = net.saveobj();
  save(newModelPath, '-struct', 'net_');
  clear net_;
else
  set(handles.status_text,'String','Status: Loading Classifier');
  net = load(newModelPath);
  net = dagnn.DagNN.loadobj(net);
end

set(handles.status_text,'String','Status: Computing Saliency');
drawnow;
net.mode = 'test';
finalLayer = 'prediction';
finalLayerFilter = 'fc1f';
penultimateLayer = 'code';
contrastOutputLayer = 'input';
net.vars(net.getVarIndex(penultimateLayer)).precious = 1;

net.move('gpu');
testGroup = str2double(get(handles.txt_selsample,'String'));
frameNum = round(get(handles.slider2,'Value'));
stackName = [S.index{testGroup,1}{frameNum} '.tif'];
im_ = imread(fullfile(S.data.path.rawdata,S.index{testGroup,2},stackName));

im_ = single(im_)/S.data.opts.rangeRescale;
if(strcmp(net.device,'gpu'))
  im_ = gpuArray(im_);
end

bpropLabel = single(cat(3,0,1));
if(strcmp(net.device,'gpu'))
  bpropLabel = gpuArray(bpropLabel);
end

% Net Input
net.vars(net.getVarIndex('prediction')).precious = 1;
netInput = {'input', im_};
% Net Output
derOutput = {finalLayer, bpropLabel};

% Invert Top/Final Layer Weights
net.params(net.getParamIndex(finalLayerFilter)).value = net.params(net.getParamIndex(finalLayerFilter)).value .* -1;
net.eval(netInput,derOutput);
penultimateDerPrime = net.vars(net.getVarIndex(penultimateLayer)).der;
net.reset;

% Invert Back
net.params(net.getParamIndex(finalLayerFilter)).value = net.params(net.getParamIndex(finalLayerFilter)).value .* -1;
net.eval(netInput,derOutput);
score = squeeze(gather(net.vars(end).value));
penultimateDer = net.vars(net.getVarIndex(penultimateLayer)).der;
net.reset;

% Compute Contrastive Signal: Backward From Penultimate Derivative
contrastDer = penultimateDer - penultimateDerPrime;
derOutput = {penultimateLayer, contrastDer};

% Forward -> Backward
net.eval(netInput,derOutput);
indDers = gather(net.vars(net.getVarIndex(contrastOutputLayer)).der);

%plot
colors = S.imdbmeta.normParms;
sumColor = sum(colors,2);
colors = bsxfun(@rdivide,colors,sumColor);
posIndDers = vl_imsmooth(indDers,1);
posIndDers = max(0,posIndDers);
imNorm = zeros(size(indDers,1), size(indDers,2), 3);

salEnergy = sum(sum(posIndDers,1),2);
[~,mCh] = max(salEnergy);

maxEnergyChan = posIndDers(:,:,mCh);
[maxEnergyChanHist,histEdges] = hist(maxEnergyChan(:),100);
maxEnergyChanHist = maxEnergyChanHist/sum(maxEnergyChanHist);
cumHist = cumsum(maxEnergyChanHist);
sumTH = find(cumHist>0.99,1);
maxRange = histEdges(sumTH);

for c = 1:size(indDers,3)
  normChan = im2uint8(imadjust(posIndDers(:,:,c),...
    [0,maxRange]));
  imNorm(:,:,1) = imNorm(:,:,1) + colors(c,1)*double(normChan);
  imNorm(:,:,2) = imNorm(:,:,2) + colors(c,2)*double(normChan);
  imNorm(:,:,3) = imNorm(:,:,3) + colors(c,3)*double(normChan);
end

imNorm(:,:,1) = imNorm(:,:,1)/sum(colors(:,1));
imNorm(:,:,2) = imNorm(:,:,2)/sum(colors(:,2));
imNorm(:,:,3) = imNorm(:,:,3)/sum(colors(:,3));
imNorm = uint8(imNorm);

imNorm = imadjust(imNorm,[0.1 0.9],[]);

imName = [S.index{testGroup,1}{frameNum} '.jpg'];
im = imread(fullfile(S.data.path.normdata,S.index{testGroup,2},imName));

sz = [450 1000]; % figure size
screensize = get(0,'ScreenSize');
xpos = ceil((screensize(3)-sz(2))/2); 
ypos = ceil((screensize(4)-sz(1))/2); 

figure('Name','Saliency','Position',[xpos, ypos, sz(2), sz(1)]);
h = vl_tightsubplot(1,2,1);
imshow(im);
title('Original')
h = vl_tightsubplot(1,2,2);
imshow(imNorm);
title(['Saliency - (FOV score: ' num2str(score(2),'%1.2f') ')']);

set(handles.status_text,'String','Status: Visualizing Data');
%set(handles.btn_select_neg_cluster, 'Enable', 'off');

end

% --- Executes on button press in btn_select_neg_cluster.
function btn_select_neg_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to btn_select_neg_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global S

axes(handles.axes1);
[x, y] = getline;

cla;

inComp = inpolygon(S.dots(S.comps,1),S.dots(S.comps,2),x,y);
inNegs = inpolygon(S.dots(S.negs,1),S.dots(S.negs,2),x,y);
inPos = inpolygon(S.dots(S.pos,1),S.dots(S.pos,2),x,y);

S.inNegComp = inComp;
S.inNegNegs = inNegs;
S.inNegPos = inPos;

plot_visualization(handles,S);
end

% --- Executes on button press in btn_clear.
function btn_clear_Callback(hObject, eventdata, handles)
% hObject    handle to btn_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global S

value = get(handles.slider1,'Value');
load(fullfile(S.expdir, S.dotsfiles{round(value)}));
%set(handles.text2, 'string', ['Granularity: ' num2str(round(value))]);
set(handles.uipanel3, 'title', ['Granularity: ' num2str(round(value))]);

S.dots = xy;

%change cursor update function
dcm_obj = datacursormode(gcf);
set(dcm_obj,'UpdateFcn',{@mydotupdatefcn,S.dots,S.index,S.imdir,handles})

S.inComp = false(numel(S.comps),1);
S.inNegs = false(numel(S.negs),1);
S.inPos = false(numel(S.pos),1);
S.inNegComp = false(numel(S.comps),1);
S.inNegNegs = false(numel(S.negs),1);
S.inNegPos = false(numel(S.pos),1);
plot_visualization(handles,S);
set(handles.btn_compute_enrich, 'Enable', 'off');
set(handles.btn_compute_saliency, 'Enable', 'off');
set(handles.btn_select_neg_cluster, 'Enable', 'off');
set(handles.btn_clear, 'Enable', 'off');
end

% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global S

idx = str2double(get(handles.txt_selsample,'String'));
if ~isnan(idx)
  value = round(get(hObject,'Value'));
  plate =  S.index{idx,3};
  row =  S.index{idx,4}(1);
  col =  S.index{idx,4}(2:3);
  frame = imread(fullfile(S.imdir, S.index{idx,2}, [S.index{idx,1}{value} '.jpg']));
  imshow(frame, 'Parent', handles.axes2);
  set(handles.plotted_sample_text,'String',['Plate: ' plate...
    ' - row: ' num2str(row) ' - col: ' num2str(col) ' - FOV: ' num2str(value)]);
else
  set(handles.plotted_sample_text,'String','No sample is currently selected');
end
end

% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global S

menuSel = round(get(hObject,'Value'));
set(handles.pop_enrichments,'Value',menuSel);

inComp = ismember(S.comps,S.E(menuSel).HEcluster)';
inNegs = false(numel(S.negs),1);
inPos = false(numel(S.pos),1);

S.inComp = inComp;
S.inNegs = inNegs;
S.inPos = inPos;

plot_visualization(handles,S);

set(handles.btn_compute_enrich, 'Enable', 'on');
set(handles.btn_compute_saliency, 'Enable', 'on');
set(handles.btn_select_neg_cluster, 'Enable', 'on');
set(handles.btn_clear, 'Enable', 'on');
end

% --- Executes on selection change in pop_enrichments.
function pop_enrichments_Callback(hObject, eventdata, handles)
% hObject    handle to pop_enrichments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_enrichments contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_enrichments
global S

menuSel = get(hObject,'Value');
set(handles.slider3,'Value',menuSel);

inComp = ismember(S.comps,S.E(menuSel).HEcluster)';
inNegs = false(numel(S.negs),1);
inPos = false(numel(S.pos),1);

S.inComp = inComp;
S.inNegs = inNegs;
S.inPos = inPos;

plot_visualization(handles,S);

set(handles.btn_compute_enrich, 'Enable', 'on');
set(handles.btn_compute_saliency, 'Enable', 'on');
set(handles.btn_select_neg_cluster, 'Enable', 'on');
set(handles.btn_clear, 'Enable', 'on');
end

% --- Executes during object creation, after setting all properties.
function pop_enrichments_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_enrichments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function edit_cluster_name_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cluster_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cluster_name as text
%        str2double(get(hObject,'String')) returns contents of edit_cluster_name as a double
end

% --- Executes during object creation, after setting all properties.
function edit_cluster_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_cluster_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

function txt_selsample_Callback(hObject, eventdata, handles)
% hObject    handle to txt_selsample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_selsample as text
%        str2double(get(hObject,'String')) returns contents of txt_selsample as a double
end

% --- Executes during object creation, after setting all properties.
function txt_selsample_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_selsample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in checkbox_show.
function checkbox_show_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_show (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_show
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over btn_compute_enrich.
function btn_compute_enrich_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to btn_compute_enrich (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in radbtn_pval.
function radbtn_pval_Callback(hObject, eventdata, handles)
% hObject    handle to radbtn_pval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radbtn_pval
global S

S.E = sortE(S.E,2); 
for i = 1:numel(S.E)
  desc = [S.E(i).hypothesis '/' S.E(i).description];
  if numel(desc) > 30
    desc = [desc(1:27) '...'];
  end
  popstring{i} = [desc ' - p=' num2str(S.E(i).pVal,'%1.2e')];
end
set(handles.pop_enrichments,'String',popstring);
set(hObject,'Value',true);
set(handles.radbtn_name,'Value',false);
end

% --- Executes on button press in radbtn_name.
function radbtn_name_Callback(hObject, eventdata, handles)
% hObject    handle to radbtn_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radbtn_name
global S

S.E = sortE(S.E,1); 
for i = 1:numel(S.E)
  desc = [S.E(i).hypothesis '/' S.E(i).description];
  if numel(desc) > 30
    desc = [desc(1:27) '...'];
  end
  popstring{i} = [desc ' - p=' num2str(S.E(i).pVal,'%1.2e')];
end
set(handles.pop_enrichments,'String',popstring);
set(hObject,'Value',true);
set(handles.radbtn_pval,'Value',false);
end

function E = sortE(E,f)
fields = fieldnames(E);
switch f
  case 1 %hypothesis name
    [~,order] = sort({E.(fields{1})});
  otherwise %p-value
    [~,order] = sort([E.(fields{3})]);
end
E = E(order);
end
