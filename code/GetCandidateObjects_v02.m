function group = GetCandidateObjects_v02(ParseTrees)
% Inputs:
% ParseTrees - Parse tree structure.
%
% Outputs:
% obj_names - Cell array of candidate objects
% obj_ids - Cell array of word positions in original text for each candidate object

obj = [];
for i = 1:length(ParseTrees)
  % Extract noun phrases:
  oo = ExtractNP(ParseTrees(i).tree);

  % Merge adjacent noun phrases:
  obj = [obj MergeNPs(oo)];
end

% Clean NPs:
obj = CleanObj(obj);

% Group noun phrases:
group = GroupNPs(obj);

return;


function group = GroupNPs(obj)

% Get noun phrases:
obj_names = [];
for j = 1:length(obj)
  if length(obj{j})>1
    obj_names{end+1} = lower([sprintf('%s ',obj{j}(1:end-1).word) obj{j}(end).word]);
  elseif length(obj{j})==1
    obj_names{end+1} = lower(obj{j}(1).word);
  end
end

% Get unique noun phrases:
[obj_names,junk,n] = unique(obj_names);

for i = 1:length(obj_names)
  group(i).NP = obj_names{i};
  group(i).obj = obj(n==i);
end

% Clean expressed noun phrase:
for i = 1:length(group)
  group(i).NP = strrep(group(i).NP,'\/','');
  group(i).NP = strrep(group(i).NP,' ''',''''); % Handle contractions
  group(i).NP = strrep(group(i).NP,' %','%');
end

  
return;


function obj = CleanObj(obj)

ndxEmptyObj = [];
for i = 1:length(obj)
  % Remove any trailing periods:
  if strcmp(obj{i}(end).word,'.')
    obj{i}(end) = [];
  end
  
  % Remove definite articles at the beginning:
  if ismember(lower(obj{i}(1).word),{'the','a','an'})
    obj{i}(1) = [];
  end

  ndxRem = [];
  for j = 1:length(obj{i})
    % Remove special characters:
    if ismember(obj{i}(j).word,{'-LRB-','-RRB-',',',';',':','$','`','-','\','/','\/','``','''''','"'})
      ndxRem(end+1) = j;
    end

% $$$     % Remove 4-digit years or 4-digit year range:
% $$$     if ~isempty(regexp(obj{i}(j).word,'^\d\d\d\d$|^\d\d\d\d-\d\d\d\d$|^\d\d\d\d \d\d\d\d$','match'))
% $$$       ndxRem(end+1) = j;
% $$$     end
  end
  obj{i}(ndxRem) = [];
  
  % Remove objects consisting only of digits, 4-digit year range, a
  % single stop word:
  if (length(obj{i})==1) && (~isempty(regexp(obj{i}(1).word,'^[\d:s\\\/,]*$|^\d\d\d\d-\d\d\d\d$|^\d\d\d\d \d\d\d\d$','match')) || isempty(RemoveStopWords(lower(obj{i}(1).word))) || ~isempty(regexp(lower(obj{i}(1).word),'^(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)$','match')))
    ndxEmptyObj(end+1) = i;
  end
  
  if (length(obj{i})==2) && (~isempty(regexp(obj{i}(1).word,'^[\d\.:,th]*$','match')) && ~isempty(regexp(lower(obj{i}(2).word),'^(m|meters|metres|mpa|kpsi|bc|tons|year|years|century|degree|feet|cm|inches|am|pm|kg|minutes|january|february|march|april|may|june|july|august|september|october|november|december)$','match')))
    ndxEmptyObj(end+1) = i;
  end
  
  if isempty(obj{i})
    ndxEmptyObj(end+1) = i;
  end
end
obj(ndxEmptyObj) = [];

% Get unique NPs:
for i = 1:length(obj)
  str_ids{i} = num2str([obj{i}(:).id]);
end
[junk,n] = unique(str_ids);
obj = obj(n);

return;


function n = OverlappingIDs(id,all_ids)

n = [];
for i = 1:length(all_ids)
  ii = all_ids{i};
  
  % Compute distance between phrase:
  if min(ii) < min(id)
    d = max(0,min(id)-max(ii));
  else
    d = max(0,min(ii)-max(id));
  end
  
  if d==1
    n(end+1) = i;
  elseif d==0
    % Make sure that one phrase is not contained in the other:
    int = intersect(id,ii);
    if (length(int)~=length(id))&&(length(int)~=length(ii))
      n(end+1) = i;
    end
  end
end

return;


function obj = ExtractNP(s)

obj = [];
if isempty(s)
  return;
end
if ismember(s.tag,{'NP','NNP'})
  [oo,ii,tt] = PrintTree(s);
  obj{1} = tt;
end

for i = 1:length(s.child)
  obj = [obj ExtractNP(s.child(i))];
  
  % Extract the following pattern:
  % (NP string1)       - s.child(i)
  % (PP                - s.child(i+1)
  %   (IN string2)     - s.child(i+1).child(1)
  %   (NP              - s.child(i+1).child(2)
  %     (NP string 3)  - s.child(i+1).child(2).child(1)
  %     -- more stuff -- ))
  %
  % Output: "string1 string2 string3"
  
  if (i<length(s.child)) && ~isempty(s.child(i)) && ~isempty(s.child(i+1)) && strcmp(s.child(i).tag,'NP') && strcmp(s.child(i+1).tag,'PP') && (length(s.child(i+1).child)>=2) && ~isempty(s.child(i+1).child(1)) && ~isempty(s.child(i+1).child(2)) && (length(s.child(i+1).child(2).child)>=1) && ~isempty(s.child(i+1).child(2).child(1)) && strcmp(s.child(i+1).child(2).tag,'NP') && strcmp(s.child(i+1).child(2).child(1).tag,'NP')
    [oo1,ii1,tt1] = PrintTree(s.child(i));
    [oo2,ii2,tt2] = PrintTree(s.child(i+1).child(1));
    [oo3,ii3,tt3] = PrintTree(s.child(i+1).child(2).child(1));
    obj{end+1} = [tt1 tt2 tt3];
  end
end

return;


function obj = MergeNPs(obj)

if length(obj) > 1
  oo = obj{1};
  ii = [obj{1}(:).id];
  
  obj = MergeNPs(obj(2:end));

  obj_ids = [];
  for j = 1:length(obj)
    obj_ids{j} = [obj{j}(:).id];
  end
  
  % Find overlapping NPs:
  n = OverlappingIDs(ii,obj_ids);

  if ~isempty(n)
    % Do merge:
    merge_names = [];
    for j = 1:length(n)
      % Get merged string and ids:
      strs = [oo obj{n(j)}];
      ndx = [ii obj_ids{n(j)}];
      [ndx,udx] = unique(ndx);
      merge_names{j} = strs(udx);
    end
    obj = [merge_names obj];
  end
  obj = [{oo} obj];
end

return;


function [obj_names,obj_ids] = CleanObj_orig(obj)

for i = 1:length(obj)
  % Remove any trailing periods:
  if strcmp(obj{i}(end).word,'.')
    obj{i}(end) = [];
  end
  
  % Remove definite articles at the beginning:
  if ismember(lower(obj{i}(1).word),{'the','a','an'})
    obj{i}(1) = [];
  end

  ndxRem = [];
  for j = 1:length(obj{i})
    % Remove special characters:
    if ismember(obj{i}(j).word,{'-LRB-','-RRB-',',',';',':','$','`','-','\','/','\/','``','''''','"'})
      ndxRem(end+1) = j;
    end

    % Remove 4-digit years or 4-digit year range:
    if ~isempty(regexp(obj{i}(j).word,'^\d\d\d\d$|^\d\d\d\d-\d\d\d\d$|^\d\d\d\d \d\d\d\d$','match'))
      ndxRem(end+1) = j;
    end
  end
  obj{i}(ndxRem) = [];
  
end

% Convert to word format:
obj_ids = []; obj_names = [];
for j = 1:length(obj)
  if length(obj{j})>0
    obj_ids{end+1} = [obj{j}(:).id];
  end
  if length(obj{j})>1
    obj_names{end+1} = [sprintf('%s ',obj{j}(1:end-1).word) obj{j}(end).word];
  elseif length(obj{j})==1
    obj_names{end+1} = obj{j}(1).word;
  end
end


ndxRem = [];
for i = 1:length(obj_names)
  obj_names{i} = lower(obj_names{i});

  % Fix symbols:
  obj_names{i} = strrep(obj_names{i},'-',' ');
  obj_names{i} = strrep(obj_names{i},'\/',' ');
  obj_names{i} = strrep(obj_names{i},' ''',''); % Handle contractions
  obj_names{i} = strrep(obj_names{i},'''','');
  obj_names{i} = strrep(obj_names{i},',','');
  obj_names{i} = strrep(obj_names{i},'%',' percent ');
  obj_names{i} = regexprep(obj_names{i},'(?<=[a-z])\.',''); % Remove period
                                                            % after letter
  % Remove measurements:
  obj_names{i} = regexprep(obj_names{i},'(?<=(^|\s+))(\d+|\d+\.\d+)\s*(feet|foot|m|cm|pound|kg|kpsi|psi|minutes|inches|years|mpa|tons|meters|ad|roman feet|bc|degree|ft|metres|cubic feet|cubic meter)(?=(\s+|$))',' ');

  % Remove time:
  obj_names{i} = regexprep(obj_names{i},'(^|\s+)(\d{1,2}:\d\d)\s+am(\s+|$)',' ');
% $$$   obj_names{i} = regexprep(obj_names{i},'(^|\s+)(\d{1,2}\s\d\d)\s+am(\s+|$)',' ');

  % Remove dates:
  obj_names{i} = regexprep(obj_names{i},'(^|\s+)(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}(\s+|$)',' ');
  obj_names{i} = regexprep(obj_names{i},'^(january|february|march|april|may|june|july|august|september|october|november|december)$','');
  obj_names{i} = regexprep(obj_names{i},'(^|\s+)\d{1,2}\s+(january|february|march|april|may|june|july|august|september|october|november|december)(\s+|$)',' ');
  
  % Remove extra spaces:
  obj_names{i} = regexprep(obj_names{i},'(?<=\s)\s*|^\s*|\s*$','');
  
  % Remove (1) stop words, (2) strings containing only numbers, (3)
  % single letter
  if isempty(RemoveStopWords(obj_names{i})) || ~isempty(regexp(RemoveStopWords(obj_names{i}),'^[\d\s]*$','match')) || ~isempty(regexp(obj_names{i},'^[a-z]$'))
    ndxRem(end+1) = i;
  end
end
obj_ids(ndxRem) = [];
obj_names(ndxRem) = [];


if ~isempty(obj_names)
  % Get unique NPs:
  for i = 1:length(obj_ids)
    str_ids{i} = num2str(obj_ids{i});
  end
  [junk,i] = unique(str_ids);
  obj_names = obj_names(i);
  obj_ids = obj_ids(i);

% $$$ obj_names = unique(obj_names);
end

return;


