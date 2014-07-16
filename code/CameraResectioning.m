function [P,nInliers] = CameraResectioning(X,x,inlierThresh,K)
% Performs camera resectioning given 2D<->3D correspondences via RANSAC.
% Minimize geometric reprojection error.
%
% Inputs:
% X - 3D points [3xN] array
% x - 2D points [2xN] array
% inlierThresh - Inlier threshold (in pixels)
% K - Number of RANSAC iterations to run
%
% Outputs:
% P - 3x4 camera matrix
% nInliers - Indices of inlier correspondences

if nargin < 4
  K = 10000;
end

minCorrespondences = 9;%10;
doNormalization = 1;

if size(X,2) ~= size(x,2)
  error('X and x must have same number of columns');
  return;
end

Npoints = size(x,2);
P = [];
nInliers = [];
if Npoints < 6
  return;
end

% Put points into homogeneous coordinates:
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

if doNormalization
  % Normalize 2D points:
  mu = mean(x(1:2,:),2);
  sc = mean(sum((x(1:2,:)-repmat(mu,1,Npoints)).^2,1).^0.5);
  T = [-sqrt(2)/sc 0 mu(1)*sqrt(2)/sc; 0 -sqrt(2)/sc mu(2)*sqrt(2)/sc; 0 0 1];
% $$$   T = [sqrt(2)/sc 0 -mu(1)*sqrt(2)/sc; 0 sqrt(2)/sc -mu(2)*sqrt(2)/sc; 0 0 1];
  x = T*x;
  
  % Normalize threshold:
  inlierThresh = inlierThresh*sqrt(2)/sc;
  sc1 = sc;

  % Normalize 3D points:
  mu = mean(X(1:3,:),2);
  sc = mean(sum((X(1:3,:)-repmat(mu,1,Npoints)).^2,1).^0.5);
  U = [sqrt(3)/sc 0 0 -mu(1)*sqrt(3)/sc; 0 sqrt(3)/sc 0 -mu(2)*sqrt(3)/sc; 0 0 sqrt(3)/sc -mu(3)*sqrt(3)/sc; 0 0 0 1];
  X = U*X;

  sc2 = sc;
else
  sc1 = sqrt(2);
  sc2 = sqrt(3);
end

% $$$ keyboard;
% $$$ 
% $$$ % Find homography:
% $$$ H = [];
% $$$ nInliers = [];
% $$$ for i = 1:K
% $$$   rp = randperm(Npoints);
% $$$   nChoose = rp(1:4);
% $$$   if size(unique(x(:,nChoose)','rows'),1) ~= length(nChoose)
% $$$     continue;
% $$$   end
% $$$   Hi = EstimateAlgebraicH(X(1:3,nChoose),x(1:2,nChoose));
% $$$   xi = Hi*X(1:3,:); xi = [xi(1,:)./xi(3,:); xi(2,:)./xi(3,:)];
% $$$   n = find(sum((xi-x(1:2,:)).^2,1) <= inlierThresh^2);
% $$$   
% $$$   if length(n) > length(nInliers)
% $$$     nInliers = n;
% $$$     H = Hi;
% $$$   end
% $$$ end
% $$$ 
% $$$ figure;
% $$$ plot(x(1,nInliers),x(2,nInliers),'go');
% $$$ hold on;
% $$$ xi = H*X(1:3,:); xi = [xi(1,:)./xi(3,:); xi(2,:)./xi(3,:)];
% $$$ plot(xi(1,nInliers),xi(2,nInliers),'r+');
% $$$ 
% $$$ Xi = X(:,nInliers);
% $$$ figure;
% $$$ plot3(Xi(1,:),Xi(2,:),Xi(3,:),'b.');
% $$$ axis equal;

% Perform RANSAC:
P = [];
nInliers = [];
for i = 1:K
  rp = randperm(Npoints);
  nChoose = rp(1:6);
  Pi = EstimateAlgebraic(X(:,nChoose),x(:,nChoose));
% $$$   if isempty(Pi) || (rcond(Pi(:,1:3))<=(1e-04/rcond(inv(T))))
  if isempty(Pi)
    continue;
  end
  xi = Pi*X; xi = [xi(1,:)./xi(3,:); xi(2,:)./xi(3,:)];
  n = find(sum((xi-x(1:2,:)).^2,1) <= inlierThresh^2);
  
  % Get points in front of camera:
  n = n(sign(det(Pi(:,1:3)))*(Pi(3,:)*X(:,n))>=0);

  if length(n) > length(nInliers)
    nInliers = n;
    P = Pi;
  end
end

Ninliers = size(unique(x(1:2,nInliers)','rows'),1);
display(sprintf('Found %d inliers out of %d',Ninliers,size(X,2)));
if Ninliers < minCorrespondences
  display('Did not find enough correspondences for geometric estimation');
  P = [];
  nInliers = [];
  return;
end

% $$$ X = inv(U)*X;

% $$$ figure
% $$$ plot3(X(1,:),X(2,:),X(3,:),'g.');
% $$$ hold on;
% $$$ plot3(X(1,nInliers),X(2,nInliers),X(3,nInliers),'ro');
% $$$ % $$$ [K,R,C] = decomposeP([1 0 0; 0 -1 0; 0 0 1]*P);
% $$$ % $$$ [K,R,C] = decomposeP([-1 0 0; 0 -1 0; 0 0 1]*P);
% $$$ [K,R,C] = decomposeP(P);
% $$$ plot3(C(1),C(2),C(3),'bs');
% $$$ axis equal;

% $$$ P = EstimateAlgebraic(X(:,nInliers),x(:,nInliers));
Pi = CameraResectioning_inliers(P,X(:,nInliers),x(:,nInliers));

if any(isnan(Pi(:))) || any(isnan(P(:)))
  display('NaN P...');
  keyboard;
end

P = Pi;

% $$$ xx = P*X(:,nInliers);
% $$$ figure;
% $$$ plot(x(1,nInliers),x(2,nInliers),'go');
% $$$ hold on;
% $$$ plot(xx(1,:)./xx(3,:),xx(2,:)./xx(3,:),'r+');
% $$$ plot([x(1,nInliers); xx(1,:)./xx(3,:)],[x(2,nInliers); xx(2,:)./xx(3,:)],'y');

if doNormalization
  % Undo normalization:
  P = single(inv(T)*P*U);
end

return;


function P = EstimateAlgebraic(X,x)

N = size(X,2);
A = [zeros(N,4) X' -bsxfun(@times,X(1:3,:),x(2,:))'; ...
     X' zeros(N,4) -bsxfun(@times,X(1:3,:),x(1,:))'];
% $$$ A = [zeros(N,4) X' -[X(1:3,:).*repmat(x(2,:),3,1)]'; ...
% $$$      X' zeros(N,4) -[X(1:3,:).*repmat(x(1,:),3,1)]'];
b = [x(2,:) x(1,:)]';

if rank(A) < 11
  P = [];
  return;
end

P = [A\b; 1];
P = reshape(P,4,3)';

return;


function H = EstimateAlgebraicH(X,x)

N = size(X,2);

A = [X' zeros(N,3) -[X(1:2,:).*repmat(x(1,:),2,1)]'; ...
     zeros(N,3) X' -[X(1:2,:).*repmat(x(2,:),2,1)]'];
b = [X(3,:).*x(1,:) X(3,:).*x(2,:)]';

H = [A\b; 1];
H = reshape(H,3,3)';

return;


function P = CameraResectioning_inliers(P,X,x)

% Decompose estimated camera matrix:
[K,R,C] = decomposeP(P);

% Get rotation parameters:
w = RTow(R);

% Set parameters to be optimized:
params = double([mean(K([1 5])) K(7) K(8) w' C']);

% Get initial cost:
Finitial = costFunctionCameraResectioning_v02(params,double(X),double(x));

% Set up options:
options = optimset;
if isfield(options,'Algorithm')
  options = optimset('Jacobian','on','Display','off','Algorithm','levenberg-marquardt');
% $$$   options = optimset('NonlEqnAlgorithm','lm','Jacobian','on','Display','off','Algorithm','levenberg-marquardt');
else
  options = optimset('NonlEqnAlgorithm','lm','Jacobian','on','Display','off');
end

% Minimize geometric error:
[paramsOpt,fval,exitflag,output] = fsolve(@(p)costFunctionCameraResectioning_v02(p,double(X),double(x)),params,options);

display(sprintf('Reprojection error: (initial: %0.4f; final: %0.4f)',Finitial'*Finitial,fval'*fval));

% Get output camera matrix:
Ko = [paramsOpt(1) 0 paramsOpt(2); 0 paramsOpt(1) paramsOpt(3); 0 0 1];
Ro = wToR(paramsOpt(4:6)');
Co = paramsOpt(7:9)';
P = Ko*Ro*[eye(3) -Co];


return;


% Generate toy data:
P = rand(3,4);
X = rand(3,100);
x = P*[X; ones(1,size(X,2))];
x = [x(1,:)./x(3,:); x(2,:)./x(3,:)];

% Inject noise:
Nnoise = 20;
x(:,end-Nnoise+1:end) = rand(2,Nnoise);

% Perform camera resectioning:
inlierThresh = 0.005; % Need to set this
[Pest,nInliers] = CameraResectioning(X,x,inlierThresh);
