function sceneview = AlignSceneView(BUNDLE_MAT,image_names,projection_types,bbgt)

% Load bundle structure:
load(BUNDLE_MAT);

% Perform alignment:
for i = 1:length(image_names)
  img = imread(image_names{i});

  if nargin < 4
    bb_gt{i} = [1 size(img,2) 1 size(img,1)];
  end
  
  switch projection_types{i}
   case 'spherical'
    [params,x,X,nValid3D,nInliers] = AlignPanoToModel_v02(img,bundle);
% $$$     OUT_BUNDLE = 'http://grail.cs.washington.edu/projects/label3d/data/models/loggia_dei_lanzi/output';
% $$$     OUT_BUNDLE = './data/models/loggia_dei_lanzi/output';
% $$$     [params,x,X,nValid3D,nInliers] = AlignPanoToModel(img,bundle,OUT_BUNDLE);
   case 'perspective'
    [P,x,X,nValid3D,nInliers] = AlignImageToModel_v02(img,bundle,struct('do_resize',false));
    params.P = P;
   otherwise
    error('Invalid projection type');
  end
  
  doDisplay = 0;
  if doDisplay
    xi = ProjectToSceneView(X(1:3,nInliers),struct('projection_type',projection_types{i},'params',params));
% $$$     xi = world2pano(X(1:3,nInliers),params);
    figure;
    imshow(img);
    hold on;
    plot(x(1,nInliers),x(2,nInliers),'go')
    plot(xi(1,:),xi(2,:),'r+')
% $$$     plot(x(1,nValid3D),x(2,nValid3D),'r+')
  
    xx = ProjectToSceneView(bundle.X,struct('projection_type',projection_types{i},'params',params));
% $$$     xx = world2pano(bundle.X,params);
    figure;
    imshow(img);
    hold on;
    plot(xx(1,:),xx(2,:),'r.')
  end

  % Form sceneview structure:
  sceneview(i).fname = image_names{i};
  sceneview(i).img = img;
  sceneview(i).projection_type = projection_types{i};
  sceneview(i).params = params;
  sceneview(i).bbgt = bbgt{i};
  sceneview(i).x = x;
  sceneview(i).X = X;
  sceneview(i).nValid3D = nValid3D;
  sceneview(i).nInliers = nInliers;
end
