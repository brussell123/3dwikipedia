function x = ProjectToSceneView(X,sceneview)
% Inputs:
% X
% sceneview
%
% Outputs:
% x

switch sceneview.projection_type
 case 'spherical'
  x = world2pano(X,sceneview.params);
 case 'perspective'
  P = sceneview.params.P;
  x = bsxfun(@plus,P(:,1:3)*X,P(:,4));
  x = [x(1,:)./x(3,:); x(2,:)./x(3,:)];
 case 'perspective_nvm'
  f = sceneview.params.f;
  qq = sceneview.params.quaternion;
  t = sceneview.params.t;
  r = sceneview.params.k;
  R = quatrotate(qq',eye(3));
  x = R*bsxfun(@plus,X,-t);
  x = f*bsxfun(@rdivide,x(1:2,:),x(3,:));
  x(1,:) = x(1,:)+sceneview.params.imageSize(2)/2;
  x(2,:) = x(2,:)+sceneview.params.imageSize(1)/2;
 case 'cylindrical_rotunda002'
  x = world2pano_rotunda002(X);
 otherwise
  error('Invalid sceneview.projection_type');
end
