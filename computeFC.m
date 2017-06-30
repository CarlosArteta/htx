function FC = computeFC(d,labels)
%Computes an SVM binary classifier

opts = d.opts;

codespath = fullfile(d.path.codes,d.ex);
valid = find(labels>0);
labels(labels==0) = [];
nIm = numel(valid);
X = zeros(nIm,opts.repSize,'single');
prior = [nnz(labels==1) nnz(labels==2)]/nIm;
CRange = [0.0001 0.0005 0.001 0.005 0.01 0.1 1 10];

for i = 1:nIm
  code = load(fullfile(codespath,[num2str(valid(i)) '.mat']));
  X(i,:) = code.code;
end

tic;

Y = zeros(numel(labels),1);
Y(labels==1) = -1;
Y(labels==2) = 1;
bestAcc = 0;
for i = 1:numel(CRange)
  C = CRange(i);
  w = vl_svmtrain(X',Y',C);
  s = X*w;
  pred = sign(s);
  acc = single(pred==Y);
  acc(Y==-1) = acc(Y==-1)/prior(1);
  acc(Y==1) = acc(Y==1)/prior(2);
  acc = sum(acc);
  if acc>bestAcc
    bestAcc = acc;
    bestW = w;
    bestC = C;
  end
end

FC = single([-1*bestW bestW]);

disp(['Best C: ' num2str(bestC)]);
disp(['Took ' num2str(toc) ' secs for ' type]);