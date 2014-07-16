function str = RemoveStopWords(str)
% Inputs:
% str - String
%
% Outputs:
% str - Lowercase string with stop words removed.

if iscell(str)
  for i = 1:length(str)
    str{i} = RemoveStopWordsHelper(str{i});
  end
else
  str = RemoveStopWordsHelper(str);
end

return;

function str = RemoveStopWordsHelper(str)

% $$$ stop_list = {'','a','able','about','across','after','all','almost','also','am','among','an','and','any','are','as','at','be','because','been','but','by','can','cannot','could','dear','did','do','does','either','else','ever','every','for','from','get','got','had','has','have','he','her','hers','him','his','how','however','i','if','in','into','is','it','its','just','least','let','like','likely','may','me','might','most','must','my','neither','no','nor','not','of','off','often','on','only','or','other','our','own','rather','said','say','says','she','should','since','so','some','than','that','the','their','them','then','there','these','they','this','tis','to','too','twas','us','wants','was','we','were','what','when','where','which','while','who','whom','why','will','with','would','yet','you','your'};

stop_list = {'','a','able','about','across','after','all','almost','also','am','among','an','and','any','are','as','at','be','because','been','but','by','can','cannot','could','dear','did','do','does','either','else','ever','every','for','from','get','got','had','has','have','he','her','hers','him','his','how','however','i','if','in','into','is','it','its','just','least','let','like','likely','may','me','might','most','must','my','neither','no','nor','not','of','off','often','on','only','or','other','our','own','rather','said','say','says','she','should','since','so','some','than','that','the','their','them','then','there','these','they','this','tis','to','too','twas','us','wants','was','we','were','what','when','where','which','while','who','whom','why','will','with','would','yet','you','your','st','di','da','de','del'};

str = regexp(str,',','split');
if length(str)==1
  str = str{1};
  str = lower(str);
  str = regexprep(str,'(?<=[a-z])\.',''); % remove periods after a
                                          % letter, "mr. t" => "mr t"
  str = regexp(str,'\s','split');
  str = str(~ismember(str,stop_list));
  str = sprintf('%s ',str{:});
  str = str(1:end-1);
else
  for i = 1:length(str)
    str{i} = RemoveStopWordsHelper(str{i});
  end
  str = sprintf('%s,',str{:});
  str = str(1:end-1);
end
