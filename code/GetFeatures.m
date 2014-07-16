function X = GetFeatures(D,DET,obj_np,ParseTrees,options)
% Inputs:
% D - 1xN Candidate windows to compute features for.
% DET - All possible candidate windows.
%
% Outputs:
% X - KxN set of K-dimension features.

if ~exist('options','var')
  options.feature_type = 'all';
end

if isstr(options.feature_type)
  switch options.feature_type
   case 'all'
    which_features = {'best_rank','num_matches','total_overlapping','nonspatial'};
   case 'visual'
    which_features = {'best_rank','num_matches','total_overlapping'};
   otherwise
    which_features = {options.feature_type};
  end    
else
  which_features = options.feature_type;
end

X = [];

if ismember('best_rank',which_features)
  X(end+1,:) = BestRankFeature(D);
end

if ismember('num_matches',which_features)
  X(end+1,:) = NumberAlignedImagesFeature(D);
end

if ismember('total_overlapping',which_features)
  X(end+1,:) = NumberOverlappingWindowsFeature(D,DET);
end

if ismember('nonspatial',which_features)
  X(end+1,:) = NonspatialPrepositionFeature(D,obj_np);
end

X(end+1,:) = HasAuthorFeature(D,obj_np);
X(end+1,:) = IsAuthorFeature(D,obj_np);


return;

function Xi = BestRankFeature(D)
% FEATURE: Best rank:
Xi = arrayfun(@(x) min(x.ranks),D);
return;

function Xi = NumberAlignedImagesFeature(D)
% FEATURE: Number of aligned images:
Xi = arrayfun(@(x) length(x.ranks),D);
return;

function Xi = NumberOverlappingWindowsFeature(D,DET)
% FEATURE: Number of total overlapping windows:
Xi = [];
bbi = reshape([D(:).bb],4,length(D));
bbj = reshape([DET(:).bb],4,length(DET));
for i = 1:length(D)
  k = 0;
  bbbi = bbi(:,i);
  for j = 1:length(DET)
    ov = bbOverlap(bbbi,bbj(:,j));
% $$$     ov = bbOverlap(D(i).bb,DET(j).bb);
    if ov >= 0.5
      k = k+1;
    end
  end
  Xi(i) = k;
end
Xi = Xi/length(DET);
return;

function Xi = NonspatialPrepositionFeature(D,obj_np)
% FEATURE: Determine whether a spatial preposition exists in sentence:
Xi = [];
for i = 1:length(D)
  isNonspatialPrep = false;
  for j = 1:length(obj_np(D(i).ndx_obj_np).obj)
    s = regexp(CleanString(PrintTree(GetSentenceRoot(obj_np(D(i).ndx_obj_np).obj{j}(1)))),' ','split');
    isNonspatialPrep = any(ismember(s,NonspatialPrepositions)) | isNonspatialPrep;
  end
  Xi(i) = isNonspatialPrep;
end
return;

function Xi = HasAuthorFeature(D,obj_np)
Xi = [];
for i = 1:length(D)
  n = D(i).ndx_obj_np;
  Xi(i) = ~isempty(obj_np(n).ndx_author);
end
return;

function Xi = IsAuthorFeature(D,obj_np)
% FEATURE: Is author:
ndxAuthor = [];
for i = 1:length(obj_np)
  if ~isempty(obj_np(i).ndx_author)
    ndxAuthor = [ndxAuthor obj_np(i).ndx_author];
  end
end
ndxAuthor = unique(ndxAuthor);
Xi = [];
for i = 1:length(D)
  Xi(i) = ismember(D(i).ndx_obj_np,ndxAuthor);
end
return;

% $$$ if ismember('noun_relations',which_features)
% $$$   % FEATURE: Determine whether a noun relationship exists in tag:
% $$$   Xi = [];
% $$$   for i = 1:length(D)
% $$$     Xi(i) = ismember('by',regexp(D(i).obj_name,' ','split'));
% $$$   end
% $$$   X(end+1,:) = Xi;
% $$$ end
% $$$ 
% $$$ % Get all strings in the text from the parse tree:
% $$$ allStr = [];
% $$$ for i = 1:length(ParseTrees)
% $$$   [str,id] = PrintTree(ParseTrees(i).tree);
% $$$   allStr{i} = CleanString(str);
% $$$ end
% $$$ 
% $$$ doDisplay = 0;
% $$$ if doDisplay
% $$$   fp = fopen('foo.txt','w');
% $$$   for ii = 1:length(allStr)
% $$$     fprintf(fp,'%d: %s\n',ii,allStr{ii});
% $$$   end
% $$$   fclose(fp);
% $$$ end
% $$$ 
% $$$ % $$$ Xnsp = logical(zeros(length(NonspatialPrepositions),length(D)));;
% $$$ for i = 1:length(D)
% $$$   % Find sentences that match:
% $$$   nMatch = [];
% $$$   for j = 1:length(allStr)
% $$$     nstart = FindNPinSentence(allStr{j},CleanString(D(i).obj_name));
% $$$     if ~isempty(nstart)
% $$$       nMatch(end+1) = j;
% $$$     end    
% $$$   end
% $$$ 
% $$$   if isempty(nMatch)
% $$$     display('Could not find match');
% $$$     keyboard;
% $$$   end
% $$$   
% $$$   % FEATURE: Determine if "by" exists to the right of NP:
% $$$   is_by_right = false;
% $$$   for j = 1:length(nMatch)
% $$$     s = allStr{nMatch(j)}; s2 = CleanString(D(i).obj_name);
% $$$     nstart = FindNPinSentence(s,s2);
% $$$     if isempty(nstart)
% $$$       display('Could not find a match for feature');
% $$$       keyboard;
% $$$     end
% $$$     for k = 1:length(nstart)
% $$$       ss = s(nstart(k)+length(s2)+1:end);
% $$$       ss = regexp(ss,' ','split');
% $$$       is_by_right = any(ismember(ss,'by')) | is_by_right;
% $$$     end
% $$$   end
% $$$   X(5,i) = is_by_right;
  
% $$$   % Determine whether a spatial preposition exists in sentence:
% $$$   isSpatialPrep = false;
% $$$   for j = 1:length(nMatch)
% $$$     s = regexp(allStr{nMatch(j)},' ','split');
% $$$     isSpatialPrep = any(ismember(s,SpatialPrepositions)) | isSpatialPrep;
% $$$   end
% $$$   X(5,i) = isSpatialPrep;

% $$$   % Determine whether a spatial preposition exists in sentence:
% $$$   for j = 1:length(nMatch)
% $$$     s = regexp(allStr{nMatch(j)},' ','split');
% $$$     Xnsp(:,i) = ismember(NonspatialPrepositions,s)' | Xnsp(:,i);
% $$$   end
% $$$ end


% $$$ Xnsp = 2*double(Xnsp)-1;
% $$$ X = [X; Xnsp];

% $$$ % FEATURE: Object tag length:
% $$$ for i = 1:length(D)
% $$$   X(5,i) = length(CleanString(D(i).obj_name));
% $$$ end

