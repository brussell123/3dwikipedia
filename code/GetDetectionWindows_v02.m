function DET = GetDetectionWindows_v02(obj_np,ALIGN_DIR,sceneview,IMAGES_DIR)
% Inputs:
%
% ALIGN_DIR - Path to alignment outputs.
% sceneview - Structure for scene view (see below).
% IMAGES_DIR - (optional) Path to query images.  This is used to get
%              original query images that were used for alignment.
%
% sceneview(i).fname - File name of display image (e.g. panorama).
% sceneview(i).params - Structure of parameters for projecting onto
%                       display image.
%
% Outputs:
%
% DET(i).obj_name - Object name.
% DET(i).bb - 1x4 scene view bounding box for object [xmin xmax ymin ymax].
% DET(i).x - 2xN matrix of projected 3D points onto scene view.
% DET(i).conf - Detection confidence.
% DET(i).ranks - 1xK indices of images that contribute to bb.
% DET(i).all_bb - Kx4 bounding boxes that were merged to produce final bb.
% DET(i).sceneview_fname - File name of display image.
% DET(i).img_names - 1xK cell array of image file names.

if nargin < 4
  IMAGES_DIR = '';
end

DET = [];
for i = 1:length(obj_np)
  display(sprintf('%d out of %d',i,length(obj_np)));
  
  ff = dir(fullfile(ALIGN_DIR,obj_np(i).image_search_dir,'*.mat'));
  
  % Get object name:
  obj_name = obj_np(i).NP;

  % Get file names for images and output structures:
  fnameImages = cellfun(@(x) fullfile(IMAGES_DIR,obj_np(i).image_search_dir,strrep(x,'.mat','')),{ff(:).name},'UniformOutput',false);
  fnameAlignStructs = cellfun(@(x) fullfile(ALIGN_DIR,obj_np(i).image_search_dir,x),{ff(:).name},'UniformOutput',false);

  % For now, assume only one display image and that it is a panorama
  % (extend this later):
  DET_i = MergeDetectionWindows(fnameAlignStructs,obj_name,sceneview,fnameImages);

  % Discard large bounding boxes:
  nrem = [];
  for j = 1:length(DET_i)
    bb = DET_i(j).bb;
    if (bb(2)-bb(1)) > 0.2*size(sceneview.img,2)
      nrem(end+1) = j;
    end
  end
  DET_i(nrem) = [];
  
  if length(DET_i) > 0
    % Insert indices into "obj_np":
    for j = 1:length(DET_i)
      DET_i(j).ndx_obj_np = i;
    end
    
    % Accumulate detections:
    DET = [DET DET_i];
  end
end

return;
