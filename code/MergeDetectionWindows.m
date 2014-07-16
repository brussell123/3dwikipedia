function Dnm = MergeDetectionWindows(fnameAlignStructs,obj_name,sceneview,fnameImages)
% Given the set of aligned query expansion images for a candidate object
% tag, this function finds valid aligned images, computes their
% corresponding detection windows, and then merges highly overlapping
% detection windows.
%
% Inputs:
% fnameAlignStructs - Cell array of filenames pointing to alignment structs
% obj_name - String containing object name
% sceneview - sceneview structure
% fnameImages - Cell array of filenames pointing to query expansion images
%
% Outputs:
% Dnm - Merged detection windows structure
%   Dnm(i).obj_name - object name
%   Dnm(i).bb - 1x4 bounding box
%   Dnm(i).x - 4xN list of inlier 2D points on panorama
%   Dnm(i).conf - scalar confidence
%   Dnm(i).ranks - indices of images that contribute to detection window
%   Dnm(i).all_bb - Kx4 all bounding boxes
%   Dnm(i).img_names - cell array of query expansion image names

Dnm = [];

%%% Step 1: Get valid detection windows from aligned query expansion images.
pp = 0;
for j = 1:length(fnameAlignStructs);
  % Get fitted parameters:
  out = load(fnameAlignStructs{j});
  bb = GetSceneViewFrustum(out.P,out.imageSize,out.X(:,out.nInliers),sceneview);

  if IsValidViewpoint(out,sceneview)
    pp = pp+1;
    xp = ProjectToSceneView(out.X(:,out.nInliers),sceneview);
    D(pp).obj_name = obj_name;
    D(pp).bb = bb;
    D(pp).all_bb = bb;
    D(pp).x = xp;
    D(pp).conf = -j; % Confidence is based on rank
    D(pp).ranks = j;
    if exist('fnameImages','var') && ~isempty(fnameImages)
      D(pp).img_names = {fnameImages{j}};
    end
  end
end

%%% Step 2: Merge overlapping detection windows:
if exist('D','var')
  % Perform non-max suppression:
  [v,n] = sort([D(:).conf],'descend');
  Dnm = D(n(1));
  for j = 2:length(n)
    isAdded = 0; % Keep track if current window has been merged
    for k = 1:length(Dnm)
      if ~isAdded && bbOverlap(Dnm(k).bb,D(n(j)).bb) >= 0.5
        % Window overlaps with more confident window, so merge:
        Dnm(k).x = [Dnm(k).x D(n(j)).x];
        Dnm(k).ranks = [Dnm(k).ranks D(n(j)).ranks];
        Dnm(k).conf = -min(Dnm(k).ranks);

        % Detection window is the mean of the more confident window and
        % current window:
        Dnm(k).bb = [mean([Dnm(k).bb(1),D(n(j)).bb(1)]) mean([Dnm(k).bb(2),D(n(j)).bb(2)]) mean([Dnm(k).bb(3),D(n(j)).bb(3)]) mean([Dnm(k).bb(4),D(n(j)).bb(4)])];

        Dnm(k).all_bb(end+1,:) = D(n(j)).bb;
        if isfield(Dnm,'img_names')
          Dnm(k).img_names = [Dnm(k).img_names D(n(j)).img_names];
        end
        isAdded = 1;
      end
    end
    if ~isAdded
      Dnm(end+1) = D(n(j));
    end
  end
end
