function doDownloadQueryExpansion(vars,PrintExec)

if nargin < 2
  PrintExec = false;
end

% Read in noun phrases:
load(vars.OBJECT_CANDIDATES_MAT);

% Download images:
obj_np = DownloadQueryExpansion_v02(obj_np,vars.SITE_NAME,vars.DOWNLOAD_QUERY_EXPANSION_DIR,[],PrintExec);

% Save structures with download folder paths:
save(vars.DOWNLOAD_QUERY_EXPANSION_MAT,'obj_np','ParseTrees');

