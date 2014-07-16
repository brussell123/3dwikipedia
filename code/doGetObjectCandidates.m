function doGetObjectCandidates(vars)

load(vars.PARSE_TREES_MAT);

% Extract objects:
obj_np = GetCandidateObjects_v02(ParseTrees);

% Get authors using "prep_by" dependencies:
obj_np = GetAuthors(obj_np,ParseTrees);

% Save output:
save(vars.OBJECT_CANDIDATES_MAT,'obj_np','ParseTrees');

%%% Print object candidates:

% Convert to word format:
obj_names = {obj_np(:).NP};
for i = 1:length(obj_np)
  for j = 1:length(obj_np(i).ndx_author)
    obj_names{i} = sprintf('%s [%s]',obj_names{i},obj_np(obj_np(i).ndx_author(j)).NP);
  end
end
obj_names = sort(obj_names);

%%%

% $$$ % Convert to word format:
% $$$ obj_names = {obj_np(:).NP};
% $$$ obj_names = sort(obj_names);

fp = fopen(vars.OBJECT_CANDIDATES_RAW,'w');
for i = 1:length(obj_names)
  fprintf(fp,'%s\n',obj_names{i});
end
fclose(fp);
