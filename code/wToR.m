function R = wToR(w)

if isstruct(w) && isfield(w,'wx') && isfield(w,'wy') && isfield(w,'wz')
  w = [w.wx w.wy w.wz]';
else
  w = w(:);
end

ang = sqrt(w'*w);
vv = w/(ang+eps);
N = [0 -vv(3) vv(2); vv(3) 0 -vv(1); -vv(2) vv(1) 0];
R = eye(3) + sin(ang)*N + (1-cos(ang))*N*N;
