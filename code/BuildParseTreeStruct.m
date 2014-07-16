function [ParseTrees,id] = BuildParseTreeStruct(parsed_str,id,document_id)
% Build parse tree structure.
%
% Inputs:
% parsed_str - String containing raw parse outputs from Stanford parser.
%
% Outputs:
% ParseTrees(i).tree - Parse tree structure for "i"th sentence.
% ParseTrees(i).tree.tag - Parse tag (e.g. NP, DT).
% ParseTrees(i).tree.parent - Parent treenode (empty if root)
% ParseTrees(i).tree.child - Children treenodes (empty if terminal node).
% ParseTrees(i).tree.word - Word (empty if non-terminal node).
% ParseTrees(i).tree.id - Word ID (empty if non-terminal node).
%
% ParseTrees(i).dependencies(j) - "j"th dependency
% ParseTrees(i).dependencies(j).tag - Dependency tag
% ParseTrees(i).dependencies(j).child - Pointers to dependency arguments

if nargin < 3
  document_id = 1;
end

if nargin < 2
  id = 1;
end

% Extract all ROOTs:
[AllRoots,AllDep] = GetAllRoots(parsed_str);

% Convert parsed strings to structs:
ParseTrees = [];
for i = 1:length(AllRoots)
  % Extract parse tree structure:
  s = ConvertToStruct(AllRoots{i},[]);
  
  % Assign IDs to words:
  id = AssignID(s,id,document_id);
  
% $$$   display(PrintTree(s));

  % Get dependencies:
  d = GetDependencies(s,AllDep{i});
  
  ParseTrees(end+1).tree = s;
  ParseTrees(end).dependencies = d;
end

return;


function d = GetDependencies(tree,str)

% Get leaf nodes:
[junk1,junk2,leaf] = PrintTree(tree);

d = [];
strs = regexp(str,'\n','split');
for i = 1:length(strs)
  if ~isempty(strs{i})
    % Get tag:
    ss = regexp(strs{i},'^.*(?=\()','match');
    d(end+1).tag = ss{1};

    % Get 1st arg:
    ss = regexp(strs{i},'(?<=\().*(?=, )','match');
    n1 = regexp(ss{1},'-','split');
    n1 = str2num(n1{end});

    % Get 2nd arg:
    ss = regexp(strs{i},'(?<=, ).*(?=\))','match');
    n2 = regexp(ss{1},'-','split');
    n2 = str2num(n2{end});
    
    if n1~=0
      d(end).child(1) = leaf(n1);
    else
      d(end).child(1) = tree;
    end
    if n2~=0
      d(end).child(2) = leaf(n2);
    else
      d(end).child(2) = tree;
    end
  end
end

return;


function id = AssignID(s,id,document_id)

if ~isempty(s.word)
  s.id = id;
  s.document_id = document_id;
  id = id+1;
  return;
end

for i = 1:length(s.child)
  id = AssignID(s.child(i),id,document_id);
end
  
return;

function [AllRoots,AllDet] = GetAllRoots(str)

AllRoots = [];
count = 0;
do_count = false;
det_start = []; det_end = [];
for i = 1:length(str)
  switch str(i)
   case '('
    if ~do_count && strcmp(str(i+1:i+4),'ROOT') && ~strcmp(str(i+1:i+6),'ROOT-0')
      start_i = i;
      do_count = true;
      count = 1;
      if ~isempty(det_start)
        det_end(end+1) = i-1;
      end
    elseif do_count
      count = count+1;
    end
   case ')'
    if do_count
      count = count-1;
      if count==0
        AllRoots{end+1} = str(start_i:i);
        do_count = false;
        det_start(end+1) = i+1;
      end
    end
  end
end
det_end(end+1) = i;

for i = 1:length(det_start)
  AllDet{i} = str(det_start(i):det_end(i));
end

return;

function s = ConvertToStruct(str,parent)
% Convert ROOT to struct

% Remove leading/trailing whitespace:
str = strtrim(str);

if str(1)=='('
  s = [];
  phrases = SplitPhrases(str);
  for i = 1:length(phrases)
    % Find white space:
    n = find(ismember(phrases{i},' '));
    n = n(1);
    if isempty(s)
      s = treenode(strtrim(phrases{i}(2:n-1)));
    else
      s(end+1) = treenode(strtrim(phrases{i}(2:n-1)));
    end
    s(end).parent = parent;
    s(end).child = ConvertToStruct(phrases{i}(n+1:end-1),s(end));
  end
else
  parent.word = str;
  s = [];
end

return;

function phrases = SplitPhrases(str)

count = 0;
phrases = [];
for i = 1:length(str)
  switch str(i)
   case '('
    if count==0
      start_i = i;
    end
    count = count+1;
   case ')'
    count = count-1;
    if count==0
      phrases{end+1} = str(start_i:i);
    end
  end
end

return;


% Debug code:
addpath ./code;

fname_raw_parsed_text = './data/text_data/loggia_dei_lanzi_parse_tree.txt';
fname_ParseTrees = './data/text_data/loggia_dei_lanzi_ParseTrees.mat';

fname_ParseTrees = './data/text_data/Pantheon_ParseTrees.mat';
fname_raw_parsed_text = './data/text_data/Pantheon_parse_tree.txt';

fname_ParseTrees = './data/text_data/us_capitol_rotunda_ParseTrees.mat';
fname_raw_parsed_text = './data/text_data/us_capitol_rotunda_parse_tree.txt';

fname_ParseTrees = './data/text_data/sistine_chapel_ParseTrees.mat';
fname_raw_parsed_text = './data/text_data/sistine_chapel_parse_tree.txt';

fname_ParseTrees = './data/text_data/Trevi_Fountain_ParseTrees.mat';
fname_raw_parsed_text = './data/text_data/Trevi_Fountain_parse_tree.txt';

% Read raw parse output:
fp = fopen(fname_raw_parsed_text);
parsed_str = [];
while 1
  tline = fgets(fp);
  if ~ischar(tline), break, end
  parsed_str = [parsed_str tline];
end
fclose(fp);

% Build parse tree structure:
ParseTrees = BuildParseTreeStruct(parsed_str);

% Save output:
save(fname_ParseTrees,'ParseTrees');
