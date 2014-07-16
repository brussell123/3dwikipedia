function obj_np = DownloadQueryExpansion_v02(obj_np,SITE_NAME,OUT_DIR,PERL_DIR,PrintExec)
% Inputs:
% vars
% PERL_DIR

if nargin < 5
  PrintExec = false;
end

if (nargin < 4) || isempty(PERL_DIR)
  % Get perl folder:
  PERL_DIR = fullfile(fileparts(mfilename('fullpath')),'LIBS','google_image_search');
end

currdir = pwd;

try
  % Get temporary file name:
  fname_tmp = [tempname '.txt'];

  % Create search queries:
  fp = fopen(fname_tmp,'w');
  for i = 1:length(obj_np)
    % Store image search term and image search folder:
    obj_np(i).image_search_term = sprintf('%s %s',SITE_NAME,obj_np(i).NP);
    obj_np(i).image_search_dir = sprintf('%04d',i-1);

    % Write list of image search terms:
    fprintf(fp,'%s\n',obj_np(i).image_search_term);
  end
  fclose(fp);

  % Create output folder:
  if ~exist(OUT_DIR,'dir')
    mkdir(OUT_DIR);
  end
  
  if PrintExec
    display('Execute the following lines:');
    display(sprintf('cd %s',PERL_DIR));
    display(sprintf('./full_pipeline.sh %s %s',fname_tmp,fullfile(currdir,OUT_DIR)));
  else
    % Run download script:
    cd(PERL_DIR);
    system(sprintf('./full_pipeline.sh %s %s',fname_tmp,fullfile(currdir,OUT_DIR)));
    
    % Clean up:
    delete(fname_tmp);
    cd(currdir);
  end
catch
  cd(currdir);
end

return;
