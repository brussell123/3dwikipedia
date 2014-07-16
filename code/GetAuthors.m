function obj_np = GetAuthors(obj_np,ParseTrees)

% Create empty "ndx_author" field:
for i = 1:length(obj_np)
  obj_np(i).ndx_author = [];
end

for i = 1:length(ParseTrees)
  for j = 1:length(ParseTrees(i).dependencies)
    if strcmp(ParseTrees(i).dependencies(j).tag,'prep_by')
      % Get IDs of "prep_by" dependents:
      id1 = ParseTrees(i).dependencies(j).child(1).id;
      id2 = ParseTrees(i).dependencies(j).child(2).id;
      
      % Get noun phrases that overlap with "prep_by" dependents:
      n1 = []; n2 = [];
      for ii = 1:length(obj_np)
        for jj = 1:length(obj_np(ii).obj)
          ids = [obj_np(ii).obj{jj}(:).id];
          if ismember(id1,ids)
            n1(end+1) = ii;
          end
          if ismember(id2,ids)
            n2(end+1) = ii;
          end
        end
      end
      
      % Create all possible (n1,n2) pairs:
      nn = [];
      for ii = 1:length(n1)
        for jj = 1:length(n2)
          nn{end+1} = [n1(ii) n2(jj)];
        end
      end
      
      % Discard overlapping pairs:
      ndxRem = [];
      for ii = 1:length(nn)
        id1 = [];
        for jj = 1:length(obj_np(nn{ii}(1)).obj)
          id1 = [id1 [obj_np(nn{ii}(1)).obj{jj}(:).id]];
        end
        id2 = [];
        for jj = 1:length(obj_np(nn{ii}(2)).obj)
          id2 = [id2 [obj_np(nn{ii}(2)).obj{jj}(:).id]];
        end
        if ~isempty(intersect(id1,id2))
          ndxRem(end+1) = ii;
        end
      end
      nn(ndxRem) = [];

      % Record author indicies:
      for k = 1:length(nn)
        obj_np(nn{k}(1)).ndx_author(end+1) = nn{k}(2);
      end
      
    end
  end
end

