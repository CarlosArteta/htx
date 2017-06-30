function Y = gramMat(X,dzdy,type)
%Gramian Matrix computation
%type is the shape of the output: Matrix or Vector

if nargin<3
  type = 'matrix';
end

sz = [size(X,1) size(X,2) size(X,3) size(X,4)];

if isempty(dzdy) %forward
  
  v = reshape(X, [sz(1)*sz(2) sz(3) 1 sz(4)]);
  Y = zeros(size(v,2),size(v,2),1,size(v,4),'like',X);
  n = sz(1)*sz(2)*sz(3);
  
  for i = 1:sz(4)
    Y(:,:,:,i) = v(:,:,:,i)'*v(:,:,:,i)/n;
  end
  
  if strcmp(type,'vector')
    Y = reshape(Y,[1 1 size(v,2)*size(v,2) size(v,4)]);
  end
  
else %backward
  
  X = reshape(X, [sz(1)*sz(2) sz(3) 1 sz(4)]);
  Y = zeros(sz,'like',X);
  n = sz(1)*sz(2)*sz(3);
  
  if strcmp(type,'vector')
    dzdy = reshape(dzdy,[sqrt(size(dzdy,3)) sqrt(size(dzdy,3))...
      1 size(dzdy,4)]);
  end
  
  for i = 1:sz(4)
    Y(:,:,:,i) = ...
      reshape(X(:,:,:,i)*(dzdy(:,:,:,i)+dzdy(:,:,:,i)'), sz(1:3))/n;
  end
  
end