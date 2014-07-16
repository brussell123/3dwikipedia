function valid = IsValidViewpoint(align_struct,sceneview)
% Inputs:
% align_struct - Structure containing alignment output.
% sceneview - Structure for scene view.
%
% Outputs:
% valid - Boolean where true indicates that this is a valid viewpoint.

% Parameters:
NminInliers = 9;
minOverlap = 0.9;

% Valid bit to return:
valid = false;

% Check if camera matrix was returned:
if isempty(align_struct.P)
  return;
end

% Check if minimum number of inliers exist:
Ninliers = size(unique(align_struct.x(1:2,align_struct.nInliers)','rows'),1);
if Ninliers < NminInliers
  return;
end

% Check if viewpoint sufficiently overlaps with valid 3D region:
bbGT = sceneview(1).bbgt;
bb = GetSceneViewFrustum(align_struct.P,align_struct.imageSize,align_struct.X(:,align_struct.nInliers),sceneview);
if ~isempty(bb)
  % Convert bb to polygons:
  x1 = [bb(1) bb(2) bb(2) bb(1) bb(1)];
  y1 = [bb(3) bb(3) bb(4) bb(4) bb(3)];
  x2 = [bbGT(1) bbGT(2) bbGT(2) bbGT(1) bbGT(1)];
  y2 = [bbGT(3) bbGT(3) bbGT(4) bbGT(4) bbGT(3)];

  % Make clockwise:
  [x1,y1] = poly2cw(x1,y1);
  [x2,y2] = poly2cw(x2,y2);

  % Compute overlap:
  [xi,yi] = polybool('intersection',x1,y1,x2,y2);
  ai = polyarea(xi,yi);
  a1 = polyarea(x1,y1);
  overlap = ai/(a1+eps);
else
  overlap = -inf;
end

if overlap < minOverlap
  return;
end

% Passes all conditions, so return true:
valid = true;

return;

