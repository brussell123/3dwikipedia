function out = readBundleFile(BUNDLER_DIR,PATHFLAG)
% [P,f,K,X,Xcolor,x,xCameraNdx,xSiftNdx,x3dNdx,validCameras] = readBundleFile(fname)
%
% Get outputs from bundler.
%
% Inputs:
% bundler_dir - Bundler outputs filename
% PATHFLAG - Flag. If PATHFLAG is true, then treat bundler_dir as the ".out" file
%            otherwise treat it as the base directory (default).
%
% Outputs:
% P - Camera matrices (3D matrix)
% f - Focal lengths
% K - Radial distortion parameters
% X - 3D points
% Xcolor - RGB color for 3D points
% x - 2D points
% xCameraNdx - Camera indices for the 2D points (i.e. which camera the 2D
%              point appears in)
% xSiftNdx - SIFT index for the 2D points
% x3dNdx - Which 3D point the 2D point corresponds to
% validCameras - Indices of cameras that are valid

if nargin > 1 && PATHFLAG
    fname = BUNDLER_DIR;
else
    fname = fullfile(BUNDLER_DIR,'bundle','bundle.out');
end

% Read file:
fp = fopen(fname);

% Get header line:
headerLine = fgetl(fp);

% Get number of cameras and points:
tline = str2num(fgetl(fp));
Ncameras = tline(1);
Npoints = tline(2);

% Get camera parameters:
f = zeros(1,Ncameras);
K = zeros(2,Ncameras);
R = zeros(3,3,Ncameras);
t = zeros(3,Ncameras);
for i = 1:Ncameras
  tline1 = str2num(fgetl(fp));
  tline2 = str2num(fgetl(fp));
  tline3 = str2num(fgetl(fp));
  tline4 = str2num(fgetl(fp));
  tline5 = str2num(fgetl(fp));

  f(i) = tline1(1);
  K(:,i) = tline1(2:3);
  R(:,:,i) = [tline2; tline3; tline4];
  t(:,i) = tline5';
end

% Form camera matrices:
P = zeros(3,4,Ncameras);
for i = 1:Ncameras
  P(:,:,i) = diag([-1 -1 1])*[R(:,:,i) t(:,i)];
end

% $$$ if nargout <= 4
% $$$   % Set "X" to be "validCameras":
% $$$   X = find(squeeze(sum(sum(P,1),2))~=0)';
% $$$ 
% $$$   out.P = P;
% $$$   out.f = f;
% $$$   out.K = K;
% $$$   out.X = X;
% $$$   return;
% $$$ end

% Get points:
X = zeros(3,Npoints);
Xcolor = zeros(3,Npoints);
x = zeros(2,Npoints);
xCameraNdx = zeros(1,Npoints);
xSiftNdx = zeros(1,Npoints);
x3dNdx = zeros(1,Npoints);
ndxEmpty = [];
k = 0;
tic;
for i = 1:Npoints
  if mod(i,10000)==0
    toc
    display(sprintf('%d out of %d',i,Npoints)); tic;
  end
  
  tline1 = str2num(fgetl(fp));
  tline2 = str2num(fgetl(fp));
  tline3 = str2num(fgetl(fp));
  
  X(:,i) = tline1';
  Xcolor(:,i) = tline2';

  Npts2D = tline3(1);

  % Reallocate memory (for speed):
  if (k+Npts2D) > length(xCameraNdx)
    display('Reallocating memory...');

    L = length(xCameraNdx);
    
    tmp = zeros(2,2*L);
    tmp(:,1:L) = x;
    x = tmp;

    tmp = zeros(1,2*L);
    tmp(1:L) = xCameraNdx;
    xCameraNdx = tmp;

    tmp = zeros(1,2*L);
    tmp(1:L) = xSiftNdx;
    xSiftNdx = tmp;
    
    tmp = zeros(1,2*L);
    tmp(1:L) = x3dNdx;
    x3dNdx = tmp;
  
    clear tmp L;
  end
  
  x(:,k+1:k+Npts2D) = [tline3(4:4:end); tline3(5:4:end)];
  xCameraNdx(k+1:k+Npts2D) = tline3(2:4:end)+1;
  xSiftNdx(k+1:k+Npts2D) = tline3(3:4:end)+1;
  x3dNdx(k+1:k+Npts2D) = i;

  if Npts2D==0
    ndxEmpty(end+1) = i;
  end
  
  k = k+Npts2D;
end

fclose(fp);

% Clean up 2D points:
x = x(:,1:k);
xCameraNdx = xCameraNdx(1:k);
xSiftNdx = xSiftNdx(1:k);
x3dNdx = x3dNdx(1:k);

% Filter out 3D points with no corresponding 2D points:
if ~isempty(ndxEmpty)
  [v,x3dNdx] = ismember(x3dNdx,setdiff(1:Npoints,ndxEmpty));
  X(:,ndxEmpty) = [];
  Xcolor(:,ndxEmpty) = [];
end

validCameras = unique(xCameraNdx);

out.P = P;
out.f = f;
out.K = K;
out.X = X;
out.Xcolor = Xcolor;
out.x = x;
out.xCameraNdx = xCameraNdx;
out.xSiftNdx = xSiftNdx;
out.x3dNdx = x3dNdx;
out.validCameras = validCameras;


% Get list of key files for the images:
keyList = textread(fullfile(BUNDLER_DIR,'list_keys.txt'),'%s','delimiter','\n');

% Change path to key files to include "images":
for i = 1:length(keyList)
% $$$   switch model_type
% $$$    case 'pantheon'
% $$$     keyList{i} = fullfile(BUNDLER_DIR,strrep(keyList{i},'./','./images/'));
% $$$    otherwise
    keyList{i} = fullfile(BUNDLER_DIR,keyList{i});
% $$$   end
end

out.locs = zeros(4,size(out.x,2),'single')
out.keys = zeros(128,size(out.x,2),'uint8')
for i = 1:length(keyList)
  display(sprintf('%d out of %d',i,length(keyList)));
  n = find(out.xCameraNdx==i);
  if ~isempty(n)
    % Get SIFT key points and descriptors:
    [locs,keys] = mex_readSIFT(keyList{i});
    
    % Add to out struct:
    out.locs(:,n) = locs(:,out.xSiftNdx(n));
    out.keys(:,n) = keys(:,out.xSiftNdx(n));
  end
end
