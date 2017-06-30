function net = deployCNN(net,suf)

if net.meta.numPlates > 1
  net.removeLayer('KLloss');
  net.removeLayer('s1_klloss');
  net.removeLayer('softmax');
  
  net.removeLayer('top5err');
  net.removeLayer('top1err');
  net.removeLayer('batchloss');
  net.removeLayer('s2_batchloss');
  net.removeLayer('fc1');
  net.removeLayer('s1_batchloss');
end

net.removeLayer('errorHist');
net.removeLayer('loss');

for i = numel(net.layers):-1:1
  ln = net.layers(i).name;
  isCopy = ~isempty(strfind(ln,suf));
  if isCopy
    net.removeLayer(ln);
  end
end
