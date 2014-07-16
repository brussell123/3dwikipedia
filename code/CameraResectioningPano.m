function [paramsPano,nInliers] = CameraResectioningPano(X,x,imageSize,inlierThresh)
% Inputs:
% X
% x
% imageSize
% inlierThresh
%
% Outputs:
% paramsPano
% nInliers

if nargin < 4
  inlierThresh = 0.01*imageSize(1);
end

K = 10000; % Number of ransac iterations
doNormalization = 0;%1;

if size(X,2) ~= size(x,2)
  error('X and x must have same number of columns');
  return;
end

% Put points into homogeneous coordinates:
Npoints = size(x,2);
if size(x,1) < 3
  x = [x; ones(1,Npoints)];
else
  x = [x(1,:)./x(3,:); x(2,:)./x(3,:); ones(1,Npoints)];
end
if size(X,1) < 4
  X = [X; ones(1,Npoints)];
else
  X = [X(1,:)./X(4,:); X(2,:)./X(4,:); X(3,:)./X(4,:); ones(1,Npoints)];
end

% $$$ if doNormalization
% $$$   % Normalize 3D points:
% $$$   mu = mean(X(1:3,:),2);
% $$$   sc = mean(sum((X(1:3,:)-repmat(mu,1,Npoints)).^2,1).^0.5);
% $$$   U = [sqrt(3)/sc 0 0 -mu(1)*sqrt(3)/sc; 0 sqrt(3)/sc 0 -mu(2)*sqrt(3)/sc; 0 0 sqrt(3)/sc -mu(3)*sqrt(3)/sc; 0 0 0 1];
% $$$   X = U*X;
% $$$ end

% theta - x axis
% phi - y axis
% For initialization, assume middle of image is phi=0.

% Transform 2D points to spherical coordinates:
sigma = imageSize(2)/2/pi;
ang_t = (0.5*imageSize(2)-x(1,:))/sigma;
ang_p = (0.5*imageSize(1)-x(2,:))/sigma;

% Transform 2D points to unit vectors:
xu = [cos(ang_p).*sin(ang_t); sin(ang_p); cos(ang_p).*cos(ang_t)];

% Perform RANSAC:
nInliers = [];
P = [];
paramsPano.R = eye(3);
paramsPano.t = zeros(3,1);
paramsPano.phi_offset = 0;
paramsPano.imageSize = imageSize;
for i = 1:K
  rp = randperm(Npoints);
  nChoose = rp(1:6);
  Pi = EstimateAlgebraic(X(:,nChoose),xu(:,nChoose));
  for j = [1 -1]
    xi = world2pano(j*Pi*X,paramsPano);
    n = find(sum((xi-x(1:2,:)).^2,1) <= inlierThresh^2);
    if length(n) > length(nInliers)
      nInliers = n;
      P = j*Pi;
    end
  end
end

display(sprintf('Number of inliers: %d',length(nInliers)));

% $$$ P = EstimateAlgebraic(X(:,nInliers),xu(:,nInliers));
% $$$ xi = world2pano(P*X(:,nInliers),paramsPano);
% $$$ err_pos = mean(sum((xi-x(1:2,nInliers)).^2,1));
% $$$ xi = world2pano(-P*X(:,nInliers),paramsPano);
% $$$ err_neg = mean(sum((xi-x(1:2,nInliers)).^2,1));
% $$$ if err_neg < err_pos
% $$$   P = -P;
% $$$ end

doDisplay = 0;
if doDisplay
  xi = world2pano(P*X(:,nInliers),paramsPano);
  figure;
  plot(x(1,nInliers),x(2,nInliers),'go');
  hold on;
  plot(xi(1,:),xi(2,:),'r+');
  plot([x(1,nInliers); xi(1,:)],[x(2,nInliers); xi(2,:)],'y');
end

doDisplay = 0;
if doDisplay
  foo = paramsPano;
  foo.R = R';
  foo.t = -R*C;

  xi = world2pano(P*X(:,nInliers),paramsPano);
  xi = world2pano([R -R*C]*X(:,nInliers),paramsPano);
  xi = world2pano(X(1:3,nInliers),foo);
  figure;
  plot(x(1,nInliers),x(2,nInliers),'go');
  hold on;
  plot(xi(1,:),xi(2,:),'r+');
  plot([x(1,nInliers); xi(1,:)],[x(2,nInliers); xi(2,:)],'y');
end

[K,R,C] = decomposeP(P);
paramsPano.R = R';
paramsPano.t = -R*C;

% Optimize geometric error:
paramsPano = PanoResectioning_geometric(paramsPano,X(:,nInliers),x(:,nInliers));
% $$$ paramsPano = CameraResectioning_inliers(paramsPano,X(:,nInliers),x(:,nInliers));

doFindMore = 1;
if doFindMore
  % Find more inliers:
  xi = world2pano(X(1:3,:),paramsPano);
  nInliers = find(sum((xi-x(1:2,:)).^2,1) <= inlierThresh^2);
  display(sprintf('Found %d inliers',length(nInliers)));
  paramsPano = PanoResectioning_geometric(paramsPano,X(:,nInliers),x(:,nInliers));
% $$$   paramsPano = CameraResectioning_inliers(paramsPano,X(:,nInliers),x(:,nInliers));

  % Find more inliers:
  xi = world2pano(X(1:3,:),paramsPano);
  nInliers = find(sum((xi-x(1:2,:)).^2,1) <= inlierThresh^2);
  display(sprintf('Found %d inliers',length(nInliers)));
  paramsPano = PanoResectioning_geometric(paramsPano,X(:,nInliers),x(:,nInliers));
% $$$   paramsPano = CameraResectioning_inliers(paramsPano,X(:,nInliers),x(:,nInliers));
end


% $$$ if doNormalization
% $$$   % Undo normalization:
% $$$   P = [R t]*U;
% $$$ % $$$   R = P(:,1:3);
% $$$   t = P(:,4);
% $$$ end

return;

function Pi = EstimateAlgebraic(X,xu)

% $$$ N = size(X,2);
% $$$ 
% $$$ X = X(1:3,:);
% $$$ 
% $$$ % Center the points:
% $$$ X1mu = X-repmat(mean(X,2),1,N);
% $$$ X2mu = xu-repmat(mean(xu,2),1,N);
% $$$ 
% $$$ % Recover general 3x3 transformation between points:
% $$$ A = [X1mu zeros(3,2*N); ...
% $$$      zeros(3,N) X1mu zeros(3,N); ...
% $$$      zeros(3,2*N) X1mu]';
% $$$ b = reshape(X2mu',3*N,1);
% $$$ T = reshape(A\b,3,3)';
% $$$ 
% $$$ % Get rotation and scale:
% $$$ [Q,R] = rq(T);
% $$$ s = abs(det(Q))^(1/3);
% $$$ 
% $$$ % Get translation:
% $$$ t = mean(xu,2) - s*R*mean(X,2);
% $$$ 
% $$$ if ~isreal(t)
% $$$   display('t not real');
% $$$   keyboard;
% $$$ end
% $$$ 
% $$$ Pi = [R t];

% $$$ z*(p24 + X*p21 + Y*p22 + Z*p23) - y*(p34 + X*p31 + Y*p32 + Z*p33)
% $$$ z*(p14 + X*p11 + Y*p12 + Z*p13) - x*(p34 + X*p31 + Y*p32 + Z*p33)
% $$$ % $$$ y*(p14 + X*p11 + Y*p12 + Z*p13) - x*(p24 + X*p21 + Y*p22 + Z*p23)

N = size(X,2);
A = [[X.*repmat(xu(3,:),4,1)]' zeros(N,4) -[X.*repmat(xu(1,:),4,1)]'; ...
     zeros(N,4) [X.*repmat(xu(3,:),4,1)]' -[X.*repmat(xu(2,:),4,1)]'; ...
     [X.*repmat(xu(2,:),4,1)]' -[X.*repmat(xu(1,:),4,1)]' zeros(N,4)];
[u,s,v] = svd(A'*A);

Pi = reshape(u(:,end),4,3)';

return;


function paramsPano = CameraResectioning_inliers(paramsPano,X,x)

R = paramsPano.R';
t = paramsPano.t;
phi0 = paramsPano.phi_offset;

% Get rotation parameters:
w = RTow(R);

% Set parameters to be optimized:
params = double([w' t' phi0]);

% Get initial cost:
[Finitial,J] = costFunctionPanoResectioning(params,double(X),double(x),paramsPano.imageSize);

% Set up options:
options = optimset;
if isfield(options,'Algorithm')
  options = optimset('NonlEqnAlgorithm','lm','Jacobian','on','Display','off','Algorithm','levenberg-marquardt');
% $$$   options = optimset('NonlEqnAlgorithm','lm','Jacobian','on','Display','off','Algorithm','levenberg-marquardt','PlotFcns',@optimplotfval);
% $$$   options = optimset('NonlEqnAlgorithm','lm','Jacobian','on','Display','off','Algorithm','levenberg-marquardt','DerivativeCheck','on','PlotFcns',@optimplotfval);
else
  options = optimset('NonlEqnAlgorithm','lm','Jacobian','on','Display','off');
end

% Minimize geometric error:
[paramsOpt,fval,exitflag,output] = fsolve(@(p)costFunctionPanoResectioning(p,double(X),double(x),paramsPano.imageSize),params,options);

display(sprintf('Mean squared reprojection error: (initial: %0.4f; final: %0.4f)',(Finitial'*Finitial)/length(Finitial)*2,(fval'*fval)/length(fval)*2));

% Set output parameters:
Ro = wToR(paramsOpt(1:3)');
to = paramsOpt(4:6)';
paramsPano.R = Ro';
paramsPano.t = to;
paramsPano.phi_offset = paramsOpt(7);

return;


addpath ./code;

% Pano parameters:
P = rand(3,4);
[K,R,C] = decomposeP(P);
t = -R*C;
imageSize = [100 100];
paramsPano.R = R;
paramsPano.t = t;
paramsPano.phi_offset = 0;
paramsPano.imageSize = imageSize;

% Generate random 3D points:
N = 100;
X = rand(3,N); X = X-repmat(mean(X,2),1,N);
X = R'*(X-repmat(t,1,N));

% Project points:
x = world2pano(X,paramsPano);

inlierThresh = 1;
[paramsPano_out,nInliers] = CameraResectioningPano(X,x,imageSize,inlierThresh);

xo = world2pano(X,paramsPano_out);

figure;
plot(x(1,:),x(2,:),'go');
hold on;
plot(xo(1,:),xo(2,:),'r+');
plot([x(1,:); xo(1,:)],[x(2,:); xo(2,:)],'y');

