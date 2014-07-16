function vars = ReadVars(CACHE_DIR)

if isstr(CACHE_DIR)
  CACHE_DIR = {CACHE_DIR};
end

vars = repmat(struct,1,length(CACHE_DIR));
for i = 1:length(CACHE_DIR)
  if ~exist(CACHE_DIR{i},'dir')
    mkdir(CACHE_DIR{i});
  end
  if ~exist(fullfile(CACHE_DIR{i},'vars.txt'),'file')
    system(sprintf('touch %s',fullfile(CACHE_DIR{i},'vars.txt')));
  end
  
  txt = textread(fullfile(CACHE_DIR{i},'vars.txt'),'%s','delimiter','\n');

  for j = 1:length(txt)
    eval(['vars(i).' txt{j}]);
  end
end

return;

