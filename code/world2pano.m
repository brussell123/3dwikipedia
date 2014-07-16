function [x_] = world2pano(X,cam,mode)
% X in 3D coords, x in 2D pano coords

if numel(X)==0
    x_ = [];
    return
end

if nargin < 3
% $$$     mode = 'cylindrical';
    mode = 'spherical';
end

if strcmp(mode,'cylindrical')
    NORMALIZER_COLS = [1 3];
elseif strcmp(mode,'spherical')
    NORMALIZER_COLS = [1 2 3];
end

%% conversion from world to camera coordinates
X_cam = bsxfun(@plus,cam.R' * X,cam.t);
C_ = bsxfun(@rdivide,X_cam,sqrt(sum(X_cam(NORMALIZER_COLS,:).^2)));
theta_ = atan2(C_(1,:),C_(3,:));
if strcmp(mode,'cylindrical')
    x_ = [theta_; C_(2,:)];
elseif strcmp(mode,'spherical')
    phi_ = asin(C_(2,:));
    SCALE = cam.imageSize(2)/(2*pi);
    phi_ = (phi_+cam.phi_offset)*SCALE;
    theta_ = theta_*SCALE;
    x_ = xy2imgcoords([-theta_; phi_],cam.imageSize);
end

return;

% % perspective division
% p = bsxfun(@rdivide,-P(1:2,:),P(3,:));
% % remove radial distortion, multiply by focal length
% r = 1.0 + cam.k1*sum(p.^2,1) + cam.k2*sum(p.^2,1);
% % conversion to pixel coordinates
% p_ = cam.f .* bsxfun(@times,r,p);
% x = p_;
% z = P(3,:);

function x_ = xy2imgcoords(x,imageSize)

x_ = x;
x_(1,:) = x_(1,:) + imageSize(2)/2;
x_(2,:) = -x_(2,:) + imageSize(1)/2;
