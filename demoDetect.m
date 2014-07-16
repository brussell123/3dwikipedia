% This script demonstrates the 3D Wikipedia labeling algorithm.
%
% Note that your results may differ from the original results since
% Google Image Search may return a different set of images during the
% query expansion step.

% compile % <- Run this the first time to compile needed binaries

% Add libraries to the Matlab path:
addpath ./code/LIBS/vlfeat-0.9.16/toolbox;
addpath ./code;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Step 1: Set inputs.

% Input text:
vars.TEXT_FILE = './data/pantheon/Pantheon_001_text.txt';

% Bundler data structure:
vars.BUNDLE_MAT = './data/pantheon/pantheon_bundle_full.mat';

% Reference image (e.g. panorama) to project results onto:
refviews.images = {'./data/pantheon/pantheon_001.jpg'};
refviews.projections = {'spherical'};
refviews.bbgt = {[1 5993 200 930]}; % Specify valid area on reference image 
                                    % [width_min width_max height_min height_max]

% Site name (used in query to Google Image Search during query expansion step):
vars.SITE_NAME = 'pantheon';

% Set cache folder (where intermediate results will be written):
CACHE_DIR = './cache/pantheon';

% Write variables to cache folder:
vars.SCENE_VIEW = fullfile(CACHE_DIR,'sceneview.mat');
WriteVars(vars,CACHE_DIR);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 2: Align reference image to 3D model:

sceneview = AlignSceneView(vars.BUNDLE_MAT,refviews.images,refviews.projections,refviews.bbgt);
save(vars.SCENE_VIEW,'sceneview');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3: Parse text:
doit(CACHE_DIR,'parse_text');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 4: Get noun phrases from parsed text:
doit(CACHE_DIR,'noun_phrases');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 5: Download query expansion images:
doit(CACHE_DIR,'download_query_expansion',true);
return;

% The above script will output a couple of lines to execute in a Bash
% shell.  Run those lines before continuing.  Note that this step may
% take a while to run.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 6: Align query expansion images to 3D model.  
doit(CACHE_DIR,'match_query_expansion',vars.BUNDLE_MAT);

% Note that the above script may take a while to run.  You can
% parallelize this by setting the range of query expansion terms to
% align.  For example, you can align query expansion terms 5-10 as
% follows:
%
% doit(CACHE_DIR,'match_query_expansion',vars.BUNDLE_MAT,5:10);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 7: Get a list of candidate detection windows and project onto
% reference image/panorama:
doit(CACHE_DIR,'register_detection_windows',vars.SCENE_VIEW);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 8: Detect objects using pre-trained model:
load ./model.mat;
DET = doit(CACHE_DIR,'detect_objects',model);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 8: Visualize object detections:
VisualizeDetections(DET,vars.SCENE_VIEW);
