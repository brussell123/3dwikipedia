function [paramsPano,xout,Xout,nValid3D,nInliers] = AlignPanoToModel_v02(img,bundle)
% Inputs:
% img - Image
% BUNDLE_DIR - Directory containing Bundler outputs
%
% Outputs:
% paramsPano - Panorama parameters
% x - SIFT keypoint locations
% X - 3D locations corresponding to SIFT keypoint locations
% nValid3D - Indices with valid putative 3D information
% nInliers - Indices of inliers to 3D model

% Parameters:
minCorrespondences = 10; % Minimum number of correspondences needed for
                         % camera resectioning
minPointsPerImage = 5;

imgOrig = img;

% Extract SIFT features.
[f,d] = ComputeSIFT(img);

if isempty(f)
  paramsPano = []; xout = []; Xout = []; nValid3D = []; nInliers = [];
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

% Perform camera resectioning:
% $$$ inlierThresh = round(0.01*size(img,1));
inlierThresh = round(0.02*size(img,1));
% $$$ inlierThresh = round(0.05*size(img,1));
[paramsPano,nInliers] = CameraResectioningPano(Xout(:,nValid3D),xout(1:2,nValid3D),size(img),inlierThresh);
nInliers = nValid3D(nInliers);

doDisplay = 0;
if doDisplay
  xx = world2pano(Xout(:,nInliers),paramsPano);
  xi = xout(1:2,nInliers);
  
  figure;
  imshow(img);
  hold on;
  plot(xx(1,:),xx(2,:),'r+');
  plot(xi(1,:),xi(2,:),'go');
  plot([xx(1,:); xi(1,:)],[xx(2,:); xi(2,:)],'y');



  xx = world2pano(Xout(:,nValid3D),paramsPano);
  xi = xout(1:2,nValid3D);
  figure;
  imshow(img);
  hold on;
  plot(xx(1,:),xx(2,:),'r+');
  plot(xi(1,:),xi(2,:),'go');
  plot([xx(1,:); xi(1,:)],[xx(2,:); xi(2,:)],'y');

  
  xx = world2pano(bundle.X,paramsPano);
  figure;
  imshow(img);
  hold on;
  plot(xx(1,:),xx(2,:),'r.');

end

return;

addpath ./code/LIBS/vlfeat-0.9.16/toolbox;
addpath ./code;

BUNDLER_DIR = './data/models/inside_pantheon_rome_ORIGS';

outBundle = readBundleFile(BUNDLER_DIR);

img = imread('./data/toy_data/pantheon360_landy_large.jpg');

[paramsPano,x,X,nValid3D,nInliers] = AlignPanoToModel(img,outBundle,BUNDLER_DIR);

save data/toy_data/pantheon360_landy_large_paramsPano.mat paramsPano xout Xosave data/toy_data/pantheon360_landy_large_paramsPano.mat paramsPano x X nValid3D nInliers;
