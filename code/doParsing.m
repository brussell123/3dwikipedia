function doParsing(vars)
% If needed, set maximum memory inside
% "./stanford-parser-2012-07-09/lexparser.sh"

BIN_STANFORD = fullfile(fileparts(mfilename('fullpath')),'LIBS/stanford-parser-2012-07-09/lexparser.sh');

% $$$ if exist('fname_wiki','var')
% $$$   % Pull article from Wikipedia:
% $$$   ReadWikipedia(ArticleName,fname_wiki);
% $$$   
% $$$   % Get raw text from Wikipedia source:
% $$$   Wiki2Text(fname_wiki,fname_text);
% $$$ end

fname_text = vars.TEXT_FILE;
if ~iscell(fname_text)
  fname_text = {fname_text};
end

% Extract objects:
ParseTrees = []; raw_parsed_text = [];
id = 1;
for i = 1:length(fname_text)
  out_raw_parsed_text = RunParser(BIN_STANFORD,fname_text{i});
  [out_ParseTrees,id] = BuildParseTreeStruct(out_raw_parsed_text,id,i);

  ParseTrees = [ParseTrees out_ParseTrees];
  raw_parsed_text = [raw_parsed_text out_raw_parsed_text];
end

save(vars.PARSE_TREES_MAT,'ParseTrees');

fp = fopen(vars.PARSE_TREES_RAW,'w');
fprintf(fp,'%s',raw_parsed_text);
fclose(fp);

return;
