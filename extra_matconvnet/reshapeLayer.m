function inp = reshapeLayer(inp, outSize, padType)

if nargin<3
  padType = 0;
end

if numel(outSize)<numel(size(inp))
  while numel(outSize) < numel(size(inp))
    outSize = [outSize 1];
  end
end

if size(inp,1) > outSize(1) %first dimension
  cropRows = (size(inp,1) - outSize(1))/2 ;
  startRow = floor(cropRows) + 1;
  
  if rem(cropRows,1) ~= 0
    endRow = size(inp,1)-floor(cropRows)-1;
  else
    endRow = size(inp,1)-cropRows;
  end
  
  inp = (inp(startRow:endRow,:,:,:));
  
elseif size(inp,1) < outSize(1)
  
  padRows = (outSize(1) - size(inp,1))/2;
  if rem(padRows,1) ~= 0
    padRowsU = floor(padRows);
    padRowsB = ceil(padRows);
  else
    padRowsU = padRows;
    padRowsB = padRows;
  end
  
  switch padType
    case 0 %Zero pad
      inp = [zeros(padRowsU,size(inp,2),size(inp,3),size(inp,4));...
        inp; zeros(padRowsB,size(inp,2),size(inp,3),size(inp,4))];
    case 1
    case 2
  end
  
end

if size(inp,2) > outSize(2) %second dimension
  cropCols = (size(inp,2) - outSize(2))/2;
  startCol = floor(cropCols) + 1;
  
  if rem(cropCols,1) ~= 0
    endCol = size(inp,2)-floor(cropCols)-1;
  else
    endCol = size(inp,2)-cropCols;
  end
  
  inp = (inp(:,startCol:endCol,:,:));
  
elseif size(inp,2) < outSize(2)
  
  padCols =  (outSize(2) - size(inp,2))/2 ;
  if rem(padCols,1) ~= 0
    padColsL = floor(padCols);
    padColsR = ceil(padCols);
  else
    padColsL = padCols;
    padColsR = padCols;
  end
  
  switch padType
    case 0 %Zero pad
      inp = [zeros(size(inp,1),padColsL,size(inp,3),size(inp,4))...
        inp zeros(size(inp,1),padColsR,size(inp,3),size(inp,4))];
    case 1
    case 2
  end
  
end