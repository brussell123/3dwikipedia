function doImageAlignment(DOWNLOAD_QUERY_EXPANSION_MAT,CACHE_DIR,BUNDLE_MAT,DATA_DIR,NdxRange)

Nrank = 1:6;

% Load bundle structure:
load(BUNDLE_MAT);

% Load list of object candidates:
load(DOWNLOAD_QUERY_EXPANSION_MAT);

if ~exist('NdxRange','var') || isempty(NdxRange)
  NdxRange = 1:length(obj_np);
end

for i = NdxRange%1:length(obj_np)
  % Read list of downloaded images:
  ff = dir(fullfile(DATA_DIR,obj_np(i).image_search_dir,'*.img'));

  % Create folder for image alignment outputs:
  if length(ff)==0
    continue;
  end
  if ~exist(fullfile(CACHE_DIR,obj_np(i).image_search_dir),'dir')
    mkdir(fullfile(CACHE_DIR,obj_np(i).image_search_dir));
  end
  
  for j = Nrank % ranked image to compute
    display(sprintf('(%d,%d) out of (%d,%d)',i,j,max(NdxRange),max(Nrank)));
  
    if length(ff) < j
      continue;
    end      
    
    % Image to match:
    try
      img = imread(fullfile(DATA_DIR,obj_np(i).image_search_dir,ff(j).name));
      if (ndims(img)>3) || islogical(img)
        error('Image has more than 3 dimensions or is not correct type');
      end
    catch
      P = []; x = []; X = []; nValid3D = []; nInliers = []; imageSize = [];    
      save(fullfile(CACHE_DIR,obj_np(i).image_search_dir,[ff(j).name '.mat']),'P','x','X','nValid3D','nInliers','imageSize');
      continue;
    end
    if size(img,3)==1
      img = repmat(img,[1 1 3]);
    end
    
    % Perform camera resectioning:
    tic;
    [P,x,X,nValid3D,nInliers,imageSize] = AlignImageToModel_v02(img,bundle);
    toc

    % Save output:
% $$$     parforSave(CACHE_DIR,dd(i).name,ff(j).name,P,x,X,nValid3D,nInliers,imageSize);
    save(fullfile(CACHE_DIR,obj_np(i).image_search_dir,[ff(j).name '.mat']),'P','x','X','nValid3D','nInliers','imageSize');
  end
end

return;

