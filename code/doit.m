function varargout = doit(CACHE_DIR,stepToRun,varargin)

if nargin < 2
  stepToRun = 'detect_objects';
end

% Read in vars:
vars = ReadVars(CACHE_DIR);
doWriteVars = true;

% Run different steps:
switch stepToRun
 case 'parse_text'
  vars.PARSE_TREES_MAT = fullfile(CACHE_DIR,'ParseTrees.mat');
  vars.PARSE_TREES_RAW = fullfile(CACHE_DIR,'ParseTrees.txt');
  doParsing(vars);
 case 'noun_phrases'
  vars.OBJECT_CANDIDATES_MAT = fullfile(CACHE_DIR,'ObjectCandidates.mat');
  vars.OBJECT_CANDIDATES_RAW = fullfile(CACHE_DIR,'ObjectCandidates.txt');
  doGetObjectCandidates(vars);
 case 'download_query_expansion'
  if length(varargin)>=1
    PrintExec = varargin{1};
  else
    PrintExec = false;
  end
  vars.DOWNLOAD_QUERY_EXPANSION_MAT = fullfile(CACHE_DIR,'DownloadQueryExpansion.mat');
  vars.DOWNLOAD_QUERY_EXPANSION_DIR = fullfile(CACHE_DIR,'image_search');
  doDownloadQueryExpansion(vars,PrintExec);
 case 'match_query_expansion'
  BUNDLE_MAT = varargin{1};
  if length(varargin)>=2
    NdxRange = varargin{2};
  else
    NdxRange = [];
  end
  vars.ALIGNMENTS_DIR = fullfile(CACHE_DIR,'alignments');
  doImageAlignment(vars.DOWNLOAD_QUERY_EXPANSION_MAT,vars.ALIGNMENTS_DIR,BUNDLE_MAT,vars.DOWNLOAD_QUERY_EXPANSION_DIR,NdxRange);
 case 'register_detection_windows'
  fname_sceneview = varargin{1};
  out = load(fname_sceneview);
  vars.CANDIDATE_WINDOWS = fullfile(CACHE_DIR,'CandidateWindows.mat');
  load(vars.DOWNLOAD_QUERY_EXPANSION_MAT);
  DET = GetDetectionWindows_v02(obj_np,vars.ALIGNMENTS_DIR,out.sceneview);
  save(vars.CANDIDATE_WINDOWS,'DET','ParseTrees','obj_np');
 case 'train_model'
  model = LearnModel_v02(vars,varargin{:});
  varargout{1} = model;
  doWriteVars = false;
 case 'detect_objects'
  model = varargin{1};
  load(vars.CANDIDATE_WINDOWS);
  DET = InferDetections(DET,model,obj_np,ParseTrees);
  varargout{1} = DET;
  doWriteVars = false;
 case 'diagnostic_recall' % Match ground truth with object list and display
  fname_xml = varargin{1}; % Ground truth
  fname_sceneview = varargin{2};
  vars.DIAGNOSTIC_RECALL_DIR = fullfile(CACHE_DIR,'DiagnosticRecall');

  % Match ground truth objects with object list:
  NdxMatch = MatchGroundTruthObjects(vars,fname_xml);

  % Create HTML page:
  RunDiagnostic(vars,fname_xml,fname_sceneview,NdxMatch,varargin{3:end});
 case 'output_3d_viewer'
  DET = varargin{1};
  vars.VIEWER_3D = fullfile(CACHE_DIR,'viewer3d');
  Create3dViewerFiles(DET,vars.DOWNLOAD_QUERY_EXPANSION_DIR,vars.ALIGNMENTS_DIR,vars.CANDIDATE_WINDOWS,vars.VIEWER_3D);
 
 case 'output_2d_viewer'
  DET = varargin{1};
  SCENE_VIEW = varargin{2};
  fname_wiki_in = varargin{3};
  vars.VIEWER_2D = fullfile(CACHE_DIR,'viewer2d');
  GenerateHtmlTextViewer(DET,vars.CANDIDATE_WINDOWS,SCENE_VIEW,fname_wiki_in,vars.VIEWER_2D);
 
 otherwise
  error('Invalid stepToRun');
end

if doWriteVars
  % Write vars:
  WriteVars(vars,CACHE_DIR);
end

return;

% Main steps

% 1. echo -e "TEXT_FILE='./data/pantheon/Pantheon_001_text.txt';\nSITE_NAME='pantheon';" > ./cache/pantheon/vars.txt
% 2. doit('./cache/pantheon');


% $$$ echo -e "TEXT_FILE='/Users/brussell/work/Language/label3d/data/pantheon/Pantheon_001_text.txt';\nSITE_NAME='pantheon';\nPARSE_TREES_MAT='/Users/brussell/work/Language/label3d/cache/pantheon/ParseTrees.mat';\nPARSE_TREES_RAW='/Users/brussell/work/Language/label3d/cache/pantheon/ParseTrees.txt';" > ./cache/pantheon/vars.txt
% $$$ 
% $$$ echo -e "TEXT_FILE='/Users/brussell/work/Language/label3d/data/loggia/loggia_dei_lanzi_001_text.txt';\nSITE_NAME='loggia dei lanzi';\nPARSE_TREES_MAT='/Users/brussell/work/Language/label3d/cache/loggia/ParseTrees.mat';\nPARSE_TREES_RAW='/Users/brussell/work/Language/label3d/cache/loggia/ParseTrees.txt';" > ./cache/loggia/vars.txt
% $$$ 
% $$$ echo -e "TEXT_FILE='/Users/brussell/work/Language/label3d/data/rotunda/us_capitol_rotunda_001_text.txt';\nSITE_NAME='us capitol rotunda';\nPARSE_TREES_MAT='/Users/brussell/work/Language/label3d/cache/rotunda/ParseTrees.mat';\nPARSE_TREES_RAW='/Users/brussell/work/Language/label3d/cache/rotunda/ParseTrees.txt';" > ./cache/rotunda/vars.txt
% $$$ 
% $$$ echo -e "TEXT_FILE='/Users/brussell/work/Language/label3d/data/sistine/sistine_chapel_001_text.txt';\nSITE_NAME='sistine chapel';\nPARSE_TREES_MAT='/Users/brussell/work/Language/label3d/cache/sistine/ParseTrees.mat';\nPARSE_TREES_RAW='/Users/brussell/work/Language/label3d/cache/sistine/ParseTrees.txt';" > ./cache/sistine/vars.txt
% $$$ 
% $$$ echo -e "TEXT_FILE={'/Users/brussell/work/Language/label3d/data/trevi/Trevi_Fountain_001_text.txt','/Users/brussell/work/Language/label3d/data/trevi/Trevi_Fountain_002_text.txt','/Users/brussell/work/Language/label3d/data/trevi/Trevi_Fountain_003_text.txt'};\nSITE_NAME='trevi fountain';\nPARSE_TREES_MAT='/Users/brussell/work/Language/label3d/cache/trevi/ParseTrees.mat';\nPARSE_TREES_RAW='/Users/brussell/work/Language/label3d/cache/trevi/ParseTrees.txt';" > ./cache/trevi/vars.txt
% $$$ 
% $$$ doit([pwd './cache/pantheon']);

% $$$ doit(fullfile(pwd,'cache','pantheon'),'noun_phrases');
