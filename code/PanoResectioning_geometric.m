function paramsPano = PanoResectioning_geometric(paramsPano,X,x)

R = paramsPano.R';
t = paramsPano.t;
phi0 = paramsPano.phi_offset;

% Get rotation parameters:
w = RTow(R);

% Set parameters to be optimized:
params = double([w' t' phi0 paramsPano.imageSize(2)]);

% Get initial cost:
Finitial = costFunctionPanoResectioning(params,double(X),double(x),paramsPano.imageSize);

% Set up options:
options = optimset;
if isfield(options,'Algorithm')
  options = optimset('NonlEqnAlgorithm','lm','Display','off','Algorithm','levenberg-marquardt');
% $$$   options = optimset('NonlEqnAlgorithm','lm','Jacobian','on','Display','off','Algorithm','levenberg-marquardt');
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
paramsPano.imageSize(2) = paramsOpt(8);
