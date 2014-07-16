function [F] = costFunctionPanoResectioning(params,X,x,imageSize)
% $$$ function [F,J] = costFunctionPanoResectioning(params,X,x,imageSize)
% Cost function for camera resectioning using geometric error.

if size(X,1) < 4
  X = [X; ones(1,size(X,2))];
end

wx = params(1); wy = params(2); wz = params(3);
tx = params(4); ty = params(5); tz = params(6);
b = params(7);
W = params(8);

% Rotation matrix:
tt = sqrt(wx^2+wy^2+wz^2)+eps;
nx = wx/tt;
ny = wy/tt;
nz = wz/tt;
N = [0 -nz ny; nz 0 -nx; -ny nx 0];
R = eye(3) + sin(tt)*N + (1-cos(tt))*N*N;

% Translation:
t = [tx; ty; tz];

% Project 3D points to 2D:
xx = R*X(1:3,:)+repmat(t,1,size(X,2));
xx = xx./repmat(sqrt(sum(xx.^2,1)),3,1);
ang_t = atan2(xx(1,:),xx(3,:));
ang_p = asin(xx(2,:));
sigma = W/2/pi;
% $$$ sigma = imageSize(2)/2/pi;
yy = -sigma*(ang_p+b)+0.5*imageSize(1);
xx = -sigma*ang_t+0.5*W;
% $$$ xx = -sigma*ang_t+0.5*imageSize(2);

% Compute cost:
F = [xx-x(1,:) yy-x(2,:)]';

% $$$ if nargout >= 2
% $$$   % Compute derivative information:
% $$$   [Jx,Jy] = GetDerivs(imageSize(2),X(1,:),X(2,:),X(3,:),tx,ty,tz,wx,wy,wz);
% $$$ 
% $$$   % Compute Jacobian matrix:
% $$$   J = [Jx Jy]';
% $$$   
% $$$   % TO DO: Add regularization...
% $$$ 
% $$$ end

return;


% $$$ syms wx wy wz tx ty tz b EPS;
% $$$ syms X Y Z;
% $$$ syms MM NN sgn;
% $$$ 
% $$$ % Rotation matrix:
% $$$ tt = sqrt(wx^2+wy^2+wz^2)+eps;
% $$$ nx = wx/tt;
% $$$ ny = wy/tt;
% $$$ nz = wz/tt;
% $$$ N = [0 -nz ny; nz 0 -nx; -ny nx 0];
% $$$ R = eye(3) + sin(tt)*N + (1-cos(tt))*N*N;
% $$$ 
% $$$ % Translation:
% $$$ t = [tx; ty; tz];
% $$$ 
% $$$ % Project 3D points to 2D:
% $$$ xx = R*[X; Y; Z]+t;
% $$$ xx = xx/sqrt(sum(xx.^2));
% $$$ ss1 = xx(1); ss3 = xx(3);
% $$$ ang_t = sgn*atan(xx(1)/xx(3));
% $$$ ang_p = asin(xx(2));
% $$$ sigma = NN/2/pi;
% $$$ y = -sigma*(ang_p+b)+0.5*MM;
% $$$ x = -sigma*ang_t+0.5*NN;
% $$$ 
% $$$ dxdwx = diff(x,'wx');
% $$$ dxdwy = diff(x,'wy');
% $$$ dxdwz = diff(x,'wz');
% $$$ dxdtx = diff(x,'tx');
% $$$ dxdty = diff(x,'ty');
% $$$ dxdtz = diff(x,'tz');
% $$$ dxdb = diff(x,'b');
% $$$ 
% $$$ dydwx = diff(y,'wx');
% $$$ dydwy = diff(y,'wy');
% $$$ dydwz = diff(y,'wz');
% $$$ dydtx = diff(y,'tx');
% $$$ dydty = diff(y,'ty');
% $$$ dydtz = diff(y,'tz');
% $$$ dydb = diff(y,'b');
% $$$ 
% $$$ Jx = [dxdwx; dxdwy; dxdwz; dxdtx; dxdty; dxdtz; dxdb];
% $$$ Jy = [dydwx; dydwy; dydwz; dydtx; dydty; dydtz; dydb];
% $$$ 
% $$$ matlabFunction(Jx,Jy,ss1,ss3,'file','~/Desktop/out_derive.m');


function [Jx,Jy] = GetDerivs(ncols,X,Y,Z,tx,ty,tz,wx,wy,wz)
%OUT_DERIVE
%    [JX,JY,SS1,SS3] = OUT_DERIVE(NN,X,Y,Z,SGN,TX,TY,TZ,WX,WY,WZ)

%    This function was generated by the Symbolic Math Toolbox version 5.2.
%    18-Oct-2012 14:01:57

NN = ncols;
N = length(X);

t2 = wy.^2;
t3 = wx.^2;
t4 = wz.^2;
t5 = t2 + t3 + t4;
t6 = t5.^(1./2);
t7 = t6 + eps;
t8 = cos(t7);
t9 = t8 - 1;
t10 = 1./t7.^2;
t11 = sin(t7);
t12 = 1./t7;
t14 = t10.*t2.*t9;
t15 = t11.*t12.*wy;
t16 = t10.*t9.*wx.*wz;
t32 = t10.*t4.*t9;
t33 = t14 + t32 + 1;
t34 = X.*t33;
t35 = t11.*t12.*wz;
t36 = t10.*t9.*wx.*wy;
t37 = t35 + t36;
t38 = Y.*t37;
t39 = t15 - t16;
t40 = Z.*t39;
t13 = t34 - t38 + t40 + tx;
t17 = 1./t5.^(1./2);
t18 = 1./t7.^3;
t19 = t10.*t3.*t9;
t20 = t14 + t19 + 1;
t21 = Z.*t20;
t22 = t15 + t16;
t23 = t11.*t12.*wx;
t42 = t10.*t9.*wy.*wz;
t24 = t23 - t42;
t25 = Y.*t24;
t41 = X.*t22;
t26 = t21 + t25 - t41 + tz;
t27 = t10.*t11.*t17.*t3.*wz;
t28 = 2.*t17.*t18.*t3.*t9.*wz;
t29 = t12.*t17.*t8.*wx.*wy;
t30 = t10.*t11.*t17.*t2.*wx;
t31 = 2.*t17.*t18.*t2.*t9.*wx;
t43 = 1./t26.^2;
t44 = 1./pi;
t45 = t11.*t12;
t46 = t10.*t11.*t17.*wx.*wy.*wz;
t47 = 2.*t17.*t18.*t9.*wx.*wy.*wz;
t48 = 1./t26;
t49 = t10.*t11.*t17.*wx.*wy;
t50 = t10.*t11.*t17.*t2.*wy;
t51 = 2.*t17.*t18.*t2.*t9.*wy;
t52 = t10.*t11.*t17.*t3.*wy;
t53 = 2.*t17.*t18.*t3.*t9.*wy;
t54 = t12.*t17.*t2.*t8;
t55 = t13.^2;
t56 = t43.*t55;
t57 = t56 + 1;
t58 = 1./t57;
t59 = t10.*t11.*t17.*t4.*wx;
t60 = 2.*t17.*t18.*t4.*t9.*wx;
t61 = t10.*t11.*t17.*wy.*wz;
t62 = t10.*t11.*t17.*t2.*wz;
t63 = 2.*t17.*t18.*t2.*t9.*wz;
t64 = t12.*t17.*t8.*wy.*wz;
t65 = t10.*t11.*t17.*t4.*wy;
t66 = 2.*t17.*t18.*t4.*t9.*wy;
t67 = t10.*t11.*t17.*wx.*wz;
t83 = t19 + t32 + 1;
t84 = Y.*t83;
t85 = t35 - t36;
t86 = X.*t85;
t87 = t23 + t42;
t88 = Z.*t87;
t68 = t84 + t86 - t88 + ty;
t69 = t12.*t17.*t8.*wx.*wz;
t70 = t10.*t11.*t17.*t3.*wx;
t71 = 2.*t17.*t18.*t3.*t9.*wx;
t72 = t12.*t17.*t3.*t8;
t73 = t30 + t31 + t59 + t60;
t93 = t10.*t9.*wz;
t74 = t27 + t28 - t29 + t49 - t93;
t75 = X.*t74;
t80 = 2.*t10.*t9.*wx;
t76 = t30 + t31 + t70 + t71 - t80;
t77 = t10.*t11.*t17.*t3;
t92 = t10.*t9.*wy;
t78 = t52 + t53 - t67 + t69 - t92;
t79 = X.*t78;
t81 = t46 - t45 + t47 - t72 + t77;
t82 = Z.*t81;
t89 = t68.^2;
t90 = t26.^2;
t91 = t55 + t89 + t90;
t94 = t59 + t60 + t70 + t71 - t80;
t95 = t79 + t82 - Y.*t94;
t96 = 1./t91;
t125 = t89.*t96;
t97 = 1 - t125;
t98 = 1./t97.^(1./2);
t99 = 1./t91.^(1./2);
t110 = t10.*t9.*wx;
t100 = t30 - t110 + t31 - t61 + t64;
t101 = X.*t100;
t102 = t49 - t29 + t62 + t63 - t93;
t103 = Z.*t102;
t104 = t52 + t53 + t65 + t66;
t105 = t101 + t103 - Y.*t104;
t111 = 2.*t10.*t9.*wy;
t106 = t50 - t111 + t51 + t52 + t53;
t107 = t10.*t11.*t17.*t2;
t108 = t107 - t45 + t46 + t47 - t54;
t109 = X.*t108;
t112 = 1./t91.^(3./2);
t113 = t10.*t11.*t17.*t4.*wz;
t114 = 2.*t17.*t18.*t4.*t9.*wz;
t115 = t10.*t11.*t17.*t4;
t116 = t27 + t28 + t62 + t63;
t117 = t65 + t66 + t67 - t69 - t92;
t118 = Z.*t117;
t124 = 2.*t10.*t9.*wz;
t119 = t113 + t114 - t124 + t27 + t28;
t120 = t12.*t17.*t4.*t8;
t121 = t120 - t115 + t45 + t46 + t47;
t122 = X.*t121;
t123 = t118 + t122 - Y.*t119;

ss1 = t13.*t99;
ss3 = t26.*t99;

sgn = sign(ss1).*sign(ss3);

Jx = [-(NN.*sgn.*t44.*t58.*(t48.*(Y.*(t52 + t53 + t67 - t10.*t9.*wy - t12.*t17.*t8.*wx.*wz) - X.*t73 + Z.*(t27 + t28 + t29 - t10.*t9.*wz - t10.*t11.*t17.*wx.*wy)) - t13.*t43.*(t75 + Y.*(t45 + t46 + t47 + t72 - t10.*t11.*t17.*t3) - Z.*t76)))./2;-(NN.*sgn.*t44.*t58.*(t48.*(Z.*(t45 + t46 + t47 + t54 - t10.*t11.*t17.*t2) - X.*(t50 + t51 + t65 + t66 - 2.*t10.*t9.*wy) + Y.*(t30 + t31 + t61 - t10.*t9.*wx - t12.*t17.*t8.*wy.*wz)) - t13.*t43.*(t109 + Y.*(t29 - t49 + t62 + t63 - t10.*t9.*wz) - Z.*t106)))./2;-(NN.*sgn.*t44.*t58.*(t48.*(Z.*(t59 + t60 - t61 + t64 - t10.*t9.*wx) + Y.*(t115 - t45 + t46 + t47 - t12.*t17.*t4.*t8) - X.*(t113 + t114 + t62 + t63 - 2.*t10.*t9.*wz)) - t13.*t43.*(X.*(t59 + t60 + t61 - t64 - t10.*t9.*wx) + Y.*(t65 + t66 - t67 + t69 - t10.*t9.*wy) - Z.*t116)))./2;-(NN.*sgn.*t44.*t48.*t58)./2;zeros(1,N);(NN.*sgn.*t13.*t43.*t44.*t58)./2;zeros(1,N)];

Jy = [-(NN.*t44.*t98.*(t95.*t99 - t112.*t68.*(t68.*t95 + t26.*(t75 - Z.*t76 + Y.*(t45 + t46 + t47 + t72 - t77)) + t13.*(Y.*(t52 + t53 + t67 - t69 - t92) + Z.*(t27 + t28 + t29 - t49 - t93) - X.*t73))))./2;-(NN.*t44.*t98.*(t105.*t99 - t112.*t68.*(t105.*t68 + t13.*(Y.*(t30 - t110 + t31 + t61 - t64) - X.*(t50 - t111 + t51 + t65 + t66) + Z.*(t45 - t107 + t46 + t47 + t54)) + t26.*(t109 + Y.*(t29 - t49 + t62 + t63 - t93) - Z.*t106))))./2;-(NN.*t44.*t98.*(t123.*t99 - t112.*t68.*(t13.*(Y.*(t115 - t120 - t45 + t46 + t47) + Z.*(t59 - t110 + t60 - t61 + t64) - X.*(t113 + t114 - t124 + t62 + t63)) + t123.*t68 + t26.*(X.*(t59 - t110 + t60 + t61 - t64) + Y.*(t65 + t66 - t67 + t69 - t92) - Z.*t116))))./2;(NN.*t112.*t44.*t68.*t98.*(2.*tx + 2.*X.*t33 - 2.*Y.*t37 + 2.*Z.*t39))./4;-(NN.*t44.*t98.*(t99 - (t112.*t68.*(2.*ty + 2.*X.*t85 + 2.*Y.*t83 - 2.*Z.*t87))./2))./2;(NN.*t112.*t44.*t68.*t98.*(2.*tz - 2.*X.*t22 + 2.*Y.*t24 + 2.*Z.*t20))./4;repmat(-(NN.*t44)./2,1,N)];


return;
