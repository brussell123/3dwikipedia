function out = ReadNVMFile(fname,opt,model_num)
% Inputs:
% fname - Path to NVM file
% opt.ReadSiftKeys - [true] Read SIFT key files.
% opt.Read3dPoints - [true] Read 3D points.
%
% Output:
% out.cam_names - File names of images corresponding to the cameras
% out.f - 1xN set of focal lengths
% out.quaternion - 4xN set of unit quaternions
% out.t - 3xN set of camera centers
% out.k - Radial distortion parameters
% out.X - 3D points
% out.Xcolor - RGB color for 3D points
% out.x - 2D points
% out.xCameraNdx - Camera indices for the 2D points (i.e. which camera the
%                  2D point appears in)
% out.xSiftNdx - SIFT index for the 2D points
% out.x3dNdx - Which 3D point the 2D point corresponds to
% out.validCameras - Indices of cameras that are valid
%
% Here is how to project inlier 3D points to their respective SIFT keypoints:
%
% i = 1; % Camera index
% nn = find(out.xCameraNdx==i);
% x = out.x(:,nn);               % 2D points
% X = out.X(:,out.x3dNdx(nn));   % 3D points
% xp = quatrotate(out.quaternion(:,i)',eye(3))*bsxfun(@plus,X,-out.t(:,i));
% xp = out.f(i)*bsxfun(@rdivide,xp(1:2,:),xp(3,:));
% xu = bsxfun(@times,x,1+out.k(i)/out.f(i)^2*sum(x.^2,1));
% plot(xu(1,:),xu(2,:),'r+'); hold on;
% plot(xp(1,:),xp(2,:),'go');
% plot([xu(1,:); xp(1,:)],[xu(2,:); xp(2,:)],'b');
% title(sum(sqrt(sum((xu-xp).^2,1))));

if nargin < 2
  opt.ReadSiftKeys = true;
  opt.Read3dPoints = true;
end

if ~isfield(opt,'ReadSiftKeys')
  opt.ReadSiftKeys = true;
end
if ~isfield(opt,'Read3dPoints')
  opt.Read3dPoints = true;
end
if ~opt.Read3dPoints
  opt.ReadSiftKeys = false;
end
if isfield(opt,'ROOT_FOLDER')
  ROOT_FOLDER = opt.ROOT_FOLDER;
else
  ROOT_FOLDER = fileparts(fname);
end

% Read file:
fp = fopen(fname);

% Get header:
tline = fgetl(fp);

flag = true; i = 0;
while flag
  i = i+1;
  [oo,flag] = ReadNVMFile_helper(fp,ROOT_FOLDER,opt);
  if flag
    out(i) = oo;
  end
end

% Close file:
fclose(fp);

return;


function [out,flag] = ReadNVMFile_helper(fp,ROOT_FOLDER,opt)


% Skip empty lines:
tline = fgetl(fp);
while isempty(tline)
  tline = fgetl(fp);
end

out = [];
flag = true;

% Get number of cameras:
Ncameras = str2num(tline);

if Ncameras==0
  flag = false;
  return;
end

% Get cameras:
out.cam_names = cell(1,Ncameras);
out.f = zeros(1,Ncameras);
out.quaternion = zeros(4,Ncameras);
out.t = zeros(3,Ncameras);
out.k = zeros(1,Ncameras);
for i = 1:Ncameras
  tline = regexp(fgetl(fp),'\s','split');
  out.cam_names{i} = tline{1};
  out.f(i) = str2num(tline{2});
  out.quaternion(:,i) = [str2num(tline{3}) str2num(tline{4}) str2num(tline{5}) str2num(tline{6})];
  out.t(:,i) = [str2num(tline{7}) str2num(tline{8}) str2num(tline{9})];
  out.k(i) = str2num(tline{10});
end

% Skip empty lines:
tline = fgetl(fp);
while isempty(tline)
  tline = fgetl(fp);
end

% Get number of 3D points:
Npoints = str2num(tline);
out.N3D = Npoints;

if Npoints==0
  % Reached end of file:
  flag = false;
end

% Get 3D points:
if opt.Read3dPoints
  out.X = zeros(3,Npoints);
  out.Xcolor = zeros(3,Npoints);
  out.x = zeros(2,Npoints);
  out.xCameraNdx = zeros(1,Npoints);
  out.xSiftNdx = zeros(1,Npoints);
  out.x3dNdx = zeros(1,Npoints);
  k = 0;
end
for i = 1:Npoints
  tline = fgetl(fp);
  
  if opt.Read3dPoints
    tline = regexp(tline,'\s','split');
    out.X(:,i) = [str2num(tline{1}) str2num(tline{2}) str2num(tline{3})];
    out.Xcolor(:,i) = [str2num(tline{4}) str2num(tline{5}) str2num(tline{6})];
    
    Npts2D = str2num(tline{7});
    
    % Reallocate memory (for speed):
    if (k+Npts2D) > length(out.xCameraNdx)
      display('Reallocating memory...');
      
      L = length(out.xCameraNdx);
      
      tmp = zeros(2,2*L);
      tmp(:,1:L) = out.x;
      out.x = tmp;
      
      tmp = zeros(1,2*L);
      tmp(1:L) = out.xCameraNdx;
      out.xCameraNdx = tmp;
      
      tmp = zeros(1,2*L);
      tmp(1:L) = out.xSiftNdx;
      out.xSiftNdx = tmp;
      
      tmp = zeros(1,2*L);
      tmp(1:L) = out.x3dNdx;
      out.x3dNdx = tmp;
      
      clear tmp L;
    end
    
    out.x(:,k+1:k+Npts2D) = [cellfun(@str2num,tline(10:4:end)); cellfun(@str2num,tline(11:4:end))];
    out.xCameraNdx(k+1:k+Npts2D) = cellfun(@str2num,tline(8:4:7+4*Npts2D))+1;
    out.xSiftNdx(k+1:k+Npts2D) = cellfun(@str2num,tline(9:4:end))+1;
    out.x3dNdx(k+1:k+Npts2D) = i;
    
    k = k+Npts2D;
  end
end

if opt.Read3dPoints
  % Clean up 2D points:
  out.x = out.x(:,1:k);
  out.xCameraNdx = out.xCameraNdx(1:k);
  out.xSiftNdx = out.xSiftNdx(1:k);
  out.x3dNdx = out.x3dNdx(1:k);
  
  % Get valid cameras:
  out.validCameras = unique(out.xCameraNdx);
end

if opt.ReadSiftKeys
  % Get SIFT keypoints:
  out.locs = zeros(4,size(out.x,2),'uint8');
  out.keys = zeros(128,size(out.x,2),'uint8');
  for i = 1:length(out.cam_names)
    display(sprintf('%d out of %d',i,length(out.cam_names)));
    n = find(out.xCameraNdx==i);
    if ~isempty(n)
      % Get SIFT key points and descriptors:
      [aa,bb] = fileparts(out.cam_names{i});

      siftName = fullfile(ROOT_FOLDER,aa,[bb '.sift']);
      if ~strcmp(siftName(1:4),'http')
        if ~exist(siftName,'file')
          siftName = fullfile(aa,[bb '.sift']);
        end
        
        % Replace "\" with "/":
        siftName = strrep(siftName,'\','/');
      end
      
      % Get SIFT keypoints:
      [locs,keys] = ReadSiftGPU(siftName);
      
      % Add to bundle struct:
      out.locs(:,n) = locs(:,out.xSiftNdx(n));
      out.keys(:,n) = keys(:,out.xSiftNdx(n));
    end
  end
end

return;

% $$$ VisualSFM saves SfM workspaces into NVM files, which contain input image paths and multiple 3D models. Below is the format description
% $$$ 
% $$$ NVM_V3 [optional calibration]                        # file version header
% $$$ <Model1> <Model2> ...                                # multiple reconstructed models
% $$$ <Empty Model containing the unregistered Images>     # number of camera > 0, but number of points = 0
% $$$ <0>                                                  # 0 camera to indicate the end of model section
% $$$ <Some comments describing the PLY section>
% $$$ <Number of PLY files> <List of indices of models that have associated PLY>
% $$$ 
% $$$ The [optional calibration] exists only if you use "Set Fixed Calibration" Function
% $$$ FixedK fx cx fy cy
% $$$ 
% $$$ Each reconstructed <model> contains the following
% $$$ <Number of cameras>   <List of cameras>
% $$$ <Number of 3D points> <List of points>
% $$$ 
% $$$ The cameras and 3D points are saved in the following format 
% $$$ <Camera> = <File name> <focal length> <quaternion rotation> <camera center> <radial distortion> 0
% $$$ <Point>  = <XYZ> <RGB> <number of measurements> <List of Measurements>
% $$$ <Measurement> = <Image index> <Feature Index> <xy>
% $$$ 
% $$$ Check the LoadNVM function in util.h of Multicore bundle adjustment code for more details.  The LoadNVM function reads only the first model, and you should repeat to get all. Since V0.5.7, the white spaces in <file name> are replaced by '\"'. 
% $$$ Dan Costin provides an efficient code for undistorting the images under this model.

addpath ./code;

fname = '~/Desktop/chair.nvm';

out = ReadNVMFile(fname);
