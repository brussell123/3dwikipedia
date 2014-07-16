function WriteVars(vars,CACHE_DIR)

% Make backup of existing vars.txt:
ff = dir(fullfile(CACHE_DIR,'vars*.txt'));
if ~isempty(ff)
  system(sprintf('mv %s %s',fullfile(CACHE_DIR,'vars.txt'),fullfile(CACHE_DIR,sprintf('vars.%04d.txt',length(ff)-1))));
end

% Create output directory if it does not exist:
if ~exist(CACHE_DIR,'dir')
  display(sprintf('Creating directory %s',CACHE_DIR));
  mkdir(CACHE_DIR);
end

% Write variables:
ff = fieldnames(vars);
fp = fopen(fullfile(CACHE_DIR,'vars.txt'),'w');
for i = 1:length(ff)
  if iscell(getfield(vars,ff{i}))
    cc = getfield(vars,ff{i});
    fprintf(fp,'%s={''%s''',ff{i},cc{1});
    for j = 2:length(getfield(vars,ff{i}))
      fprintf(fp,',''%s''',cc{j});
    end
    fprintf(fp,'};\n');
  else
    fprintf(fp,'%s=''%s'';\n',ff{i},getfield(vars,ff{i}));
  end
end
fclose(fp);

return;

