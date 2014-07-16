function bb = GetSceneViewFrustum(P,imageSize,X,sceneview)
% Inputs:
% P - Camera matrix for viewpoint.
% imageSize - Image size for viewpoint.
% X - Inlier 3D points for viewpoint.
% sceneview
%
% Outputs:
% bb - [xmin xmax ymin ymax]

switch sceneview.projection_type
 case 'spherical'
  bb = frustrum2pano(P,imageSize,X,sceneview.params);
 case 'perspective'
  bb = frustum2persp(P,imageSize,X,sceneview.params);
 case 'cylindrical_rotunda002'
  bb = frustum2rotunda(P,imageSize,X,sceneview.params);
 otherwise
  error('Invalid sceneview.projection_type.');
end
