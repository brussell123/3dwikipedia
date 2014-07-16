function bb = frustrum2pano(P,imageSize,X,paramsPano)
% Inputs:
% P
% imageSize
% X - Inlier 3D points
% paramsPano
% 
% Outputs:
% bb - Bounding box on pano [xmin xmax ymin ymax]

if isempty(P)
  bb = [];
  return;
end

N = size(X,2);

% Get camera center for pano:
Cp = -paramsPano.R*paramsPano.t;
rad = prctile(sqrt(sum((X-repmat(Cp,1,size(X,2))).^2,1)),25);
% $$$ rad = median(sqrt(sum((X-repmat(Cp,1,size(X,2))).^2,1)));

m3 = P(3,1:3)';
depth = sign(det(P(:,1:3)))*P(3,:)*[X; ones(1,N)]/sqrt(m3'*m3);
depth = median(depth);

[K,R,C] = decomposeP(P);

% Get camera center for pano:
Cp = -paramsPano.R*paramsPano.t;

% Get 2D coordinates for image corners:
x = [1 imageSize(2) imageSize(2) 1; ...
     1 1 imageSize(1) imageSize(1); ...
     1 1 1 1];

% Get 3D rays:
v = R'*(K\x);

doDisplay = 0;
if doDisplay
  figure;
  plot(Cp(1),Cp(2),'go');
  hold on;
  plot(C(1),C(2),'r+');
end

% Get X coordinates:
Xi = [];
for i = 1:size(v,2)
  di = get_d(Cp,C,v(:,i),rad,depth);
  if isempty(di)
    bb = [];
    return;
  end
  Xi(:,i) = C + di(1)*v(:,i);
end

% Project onto pano:
xp = world2pano(Xi,paramsPano);

bb = [min(xp(1,:)) max(xp(1,:)) min(xp(2,:)) max(xp(2,:))];

return;

function d = get_d(Cp,C,v,rad,depth)

d1 = (Cp(1)*v(1) - C(2)*v(2) - C(3)*v(3) - C(1)*v(1) + Cp(2)*v(2) + Cp(3)*v(3) + (2*C(1)*C(2)*v(1)*v(2) - C(1)^2*v(3)^2 - C(1)^2*v(2)^2 + 2*C(1)*C(3)*v(1)*v(3) + 2*C(1)*Cp(1)*v(2)^2 + 2*C(1)*Cp(1)*v(3)^2 - 2*C(1)*Cp(2)*v(1)*v(2) - 2*C(1)*Cp(3)*v(1)*v(3) - C(2)^2*v(1)^2 - C(2)^2*v(3)^2 + 2*C(2)*C(3)*v(2)*v(3) - 2*C(2)*Cp(1)*v(1)*v(2) + 2*C(2)*Cp(2)*v(1)^2 + 2*C(2)*Cp(2)*v(3)^2 - 2*C(2)*Cp(3)*v(2)*v(3) - C(3)^2*v(1)^2 - C(3)^2*v(2)^2 - 2*C(3)*Cp(1)*v(1)*v(3) - 2*C(3)*Cp(2)*v(2)*v(3) + 2*C(3)*Cp(3)*v(1)^2 + 2*C(3)*Cp(3)*v(2)^2 - Cp(1)^2*v(2)^2 - Cp(1)^2*v(3)^2 + 2*Cp(1)*Cp(2)*v(1)*v(2) + 2*Cp(1)*Cp(3)*v(1)*v(3) - Cp(2)^2*v(1)^2 - Cp(2)^2*v(3)^2 + 2*Cp(2)*Cp(3)*v(2)*v(3) - Cp(3)^2*v(1)^2 - Cp(3)^2*v(2)^2 + rad^2*v(1)^2 + rad^2*v(2)^2 + rad^2*v(3)^2)^(1/2))/(v(1)^2 + v(2)^2 + v(3)^2);

d2 = -(C(1)*v(1) + C(2)*v(2) + C(3)*v(3) - Cp(1)*v(1) - Cp(2)*v(2) - Cp(3)*v(3) + (2*C(1)*C(2)*v(1)*v(2) - C(1)^2*v(3)^2 - C(1)^2*v(2)^2 + 2*C(1)*C(3)*v(1)*v(3) + 2*C(1)*Cp(1)*v(2)^2 + 2*C(1)*Cp(1)*v(3)^2 - 2*C(1)*Cp(2)*v(1)*v(2) - 2*C(1)*Cp(3)*v(1)*v(3) - C(2)^2*v(1)^2 - C(2)^2*v(3)^2 + 2*C(2)*C(3)*v(2)*v(3) - 2*C(2)*Cp(1)*v(1)*v(2) + 2*C(2)*Cp(2)*v(1)^2 + 2*C(2)*Cp(2)*v(3)^2 - 2*C(2)*Cp(3)*v(2)*v(3) - C(3)^2*v(1)^2 - C(3)^2*v(2)^2 - 2*C(3)*Cp(1)*v(1)*v(3) - 2*C(3)*Cp(2)*v(2)*v(3) + 2*C(3)*Cp(3)*v(1)^2 + 2*C(3)*Cp(3)*v(2)^2 - Cp(1)^2*v(2)^2 - Cp(1)^2*v(3)^2 + 2*Cp(1)*Cp(2)*v(1)*v(2) + 2*Cp(1)*Cp(3)*v(1)*v(3) - Cp(2)^2*v(1)^2 - Cp(2)^2*v(3)^2 + 2*Cp(2)*Cp(3)*v(2)*v(3) - Cp(3)^2*v(1)^2 - Cp(3)^2*v(2)^2 + rad^2*v(1)^2 + rad^2*v(2)^2 + rad^2*v(3)^2)^(1/2))/(v(1)^2 + v(2)^2 + v(3)^2);

% $$$ if isreal(d1) && (d1>=0)
% $$$   d = d1;
% $$$ elseif isreal(d2) && (d2>=0)
% $$$   d = d2;
% $$$ else
% $$$   keyboard;
% $$$   error('Problem with line/sphere intersection.');
% $$$ end

if ~isreal(d1) || ~isreal(d2)
  d = [];
  return;
end

if abs(d1-depth) < abs(d2-depth)
  d = [d1 d2];
else
  d = [d2 d1];
end
  
% $$$ if d1 > d2
% $$$   d = d1;
% $$$ else
% $$$   d = d2;
% $$$ end

% Intersect image corners onto sphere for pano:
% (X-Cp(1))^2+(Y-Cp(2))^2+(Z-Cp(3))^2 = R^2

% K*R*[I -C]([C; 1] + d[v; 0]) = 
% d*K*R*v = x
% => v = R'*(K\x);

% Solve for d >= 0:
% (C(1)+d*v(1)-Cp(1))^2 + (C(2)+d*v(2)-Cp(2))^2 + (C(3)+d*v(3)-Cp(3))^2 = R^2

% $$$ syms C1 C2 C3 Cp1 Cp2 Cp3 v1 v2 v3 rad d;
% $$$ 
% $$$ f = (C1+d*v1-Cp1)^2 + (C2+d*v2-Cp2)^2 + (C3+d*v3-Cp3)^2 - rad^2;
% $$$ x = solve(f,'d');

