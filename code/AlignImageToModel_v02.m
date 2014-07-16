function [P,xout,Xout,nValid3D,nInliers,imageSize] = AlignImageToModel_v02(img,bundle,options)
% Inputs:
% img - Image
% bundle - Bundle structure
%
% Outputs:
% P - Camera matrix
% x - SIFT keypoint locations
% X - 3D locations corresponding to SIFT keypoint locations
% nValid3D - Indices with valid putative 3D information
% nInliers - Indices of inliers to 3D model

% Parameters:
minCorrespondences = 10; % Minimum number of correspondences needed for
                         % camera resectioning
maxRes = 800;
minPointsPerImage = 5;

if nargin < 3
  options.do_resize = true;
end

if options.do_resize && (max(size(img)) > maxRes)
  img = imresize(img,maxRes/max(size(img)),'bicubic');
end

imageSize = [size(img,1) size(img,2)];

% Extract SIFT features.
[f,d] = ComputeSIFT(img);

if isempty(f)
  P = []; xout = []; Xout = []; nValid3D = []; nInliers = [];
  return;
end

% Record keypoints:
Xout = zeros(3,size(f,2));
xout = f;
nValid3D = logical(zeros(1,size(f,2)));

matches = mex_keyMatchSIFT(bundle.keys,d);
matches = double(matches([2 1],:));

% Make matches be 1-1:
camNdx = bundle.xCameraNdx(matches(2,:));
ndx = unique(camNdx);
for i = 1:length(ndx)
  n = find(camNdx==ndx(i));
  cts = hist(matches(1,n),1:max(matches(1,n)));
  nRem = find(cts>1);
  nRem = n(ismember(matches(1,n),nRem));
  camNdx(nRem) = [];
  matches(:,nRem) = [];
end

% Remove points from images that contribute less than 2 matches:
camNdx = bundle.xCameraNdx(matches(2,:));
cts = hist(camNdx,1:length(bundle.f));
ndxRem = find(cts<=minPointsPerImage);
ndxRem = find(ismember(camNdx,ndxRem));
matches(:,ndxRem) = [];

xout = [xout f(:,matches(1,:))];
Xout = [Xout bundle.X(:,bundle.x3dNdx(matches(2,:)))];
nValid3D = [nValid3D logical(ones(1,size(matches,2)))];
nValid3D = find(nValid3D);


% $$$ for i = 1:length(bundle.validCameras)
% $$$ % $$$   display(sprintf('%d out of %d',i,length(bundle.validCameras)));
% $$$ 
% $$$   j = bundle.validCameras(i);
% $$$   n = find(bundle.xCameraNdx==j);
% $$$ 
% $$$   if length(n) >= 10
% $$$     % Perform matching:
% $$$ % $$$     matches = mex_keyMatchSIFT(d,bundle.keys(:,n));
% $$$     matches = mex_keyMatchSIFT(bundle.keys(:,n),d);
% $$$     matches = matches([2 1],:);
% $$$     
% $$$     if ~isempty(matches)
% $$$       xout = [xout f(:,matches(1,:))];
% $$$       Xout = [Xout bundle.X(:,bundle.x3dNdx(n(matches(2,:))))];
% $$$       nValid3D = [nValid3D logical(ones(1,size(matches,2)))];
% $$$     end
% $$$   end
% $$$ end
% $$$ nValid3D = find(nValid3D);

% $$$ % Get unique correspondences:
% $$$ [junk,n] = unique([xout(:,nValid3D); Xout(:,nValid3D)]','rows');
% $$$ n2 = setdiff(1:size(xout,2),nValid3D);
% $$$ xout = [xout(:,n2) xout(:,nValid3D(n))];
% $$$ Xout = [Xout(:,n2) Xout(:,nValid3D(n))];
% $$$ nValid3D = [length(n2)+1:length(n2)+length(n)];

if length(nValid3D) < minCorrespondences
  P = [];
  nInliers = [];
  return;
end

% Perform camera resectioning:
inlierThresh = round(0.01*max(size(img)));
[P,nInliers] = CameraResectioning(Xout(:,nValid3D),xout(1:2,nValid3D),inlierThresh);
nInliers = nValid3D(nInliers);

% Get unique inlier correspondences:
[junk,n] = unique([xout(:,nInliers); Xout(:,nInliers)]','rows');
nInliers = nInliers(n);

doDisplay = 0;
if doDisplay
  xx = P*[Xout(:,nInliers); ones(1,length(nInliers))];
  xx = [xx(1,:)./xx(3,:); xx(2,:)./xx(3,:)];
  xi = xout(1:2,nInliers);
  
  figure;
  imshow(img);
  hold on;
  plot(xx(1,:),xx(2,:),'r+');
  plot(xi(1,:),xi(2,:),'go');
  plot([xx(1,:); xi(1,:)],[xx(2,:); xi(2,:)],'y');
end

return;


function [P,xout,Xout,nValid3D,nInliers] = AlignImageToModel_v02_single(img,bundle,BUNDLER_DIR)
% Inputs:
% img - Image
% bundle - Bundle structure
% BUNDLE_DIR - Directory containing Bundler outputs
%
% Outputs:
% P - Camera matrix
% x - SIFT keypoint locations
% X - 3D locations corresponding to SIFT keypoint locations
% nValid3D - Indices with valid putative 3D information
% nInliers - Indices of inliers to 3D model

% Parameters:
minCorrespondences = 10; % Minimum number of correspondences needed for
                         % camera resectioning

% Extract SIFT features.
[f,d] = ComputeSIFT(img);

% Record keypoints:
Xout = zeros(3,size(f,2));
xout = f;
nValid3D = logical(zeros(1,size(f,2)));

% Perform matching:
matches = mex_keyMatchSIFT(d,bundle.keys);

if ~isempty(matches)
  xout = [xout f(:,matches(1,:))];
  Xout = [Xout bundle.X(:,matches(2,:))];
  nValid3D = [nValid3D logical(ones(1,size(matches,2)))];
end
nValid3D = find(nValid3D);

if length(nValid3D) < minCorrespondences
  P = [];
  nInliers = [];
  return;
end

% Perform camera resectioning:
inlierThresh = round(0.01*max(size(img)));
[P,nInliers] = CameraResectioning(Xout(:,nValid3D),xout(1:2,nValid3D),inlierThresh);
nInliers = nValid3D(nInliers);

doDisplay = 0;
if doDisplay
  xx = P*[Xout(:,nInliers); ones(1,length(nInliers))];
  xx = [xx(1,:)./xx(3,:); xx(2,:)./xx(3,:)];
  xi = xout(1:2,nInliers);
  
  figure;
  imshow(img);
  hold on;
  plot(xx(1,:),xx(2,:),'r+');
  plot(xi(1,:),xi(2,:),'go');
  plot([xx(1,:); xi(1,:)],[xx(2,:); xi(2,:)],'y');
end

return;
