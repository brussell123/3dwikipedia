function parsed_str = RunParser(BIN_STANFORD,fname)
% Inputs:
% BIN_STANFORD - Path to Stanford parser binary
% fname - Filename for text to parse.
%
% Outputs:
% parsed_str - Raw string containing parse tree and dependency structures.
%
% Download Stanford parser here:
%
% http://nlp.stanford.edu/software/lex-parser.shtml
%
% If needed, set maximum memory inside
% "./code/LIBS/stanford-parser-2012-07-09/lexparser.sh"

% Get temporary file names:
ff = tempname;
infile = [ff '_in.txt'];
outfile = [ff '_out.txt'];

% Read input text:
fp = fopen(fname);
str = fread(fp,inf,'uint8=>char')';
fclose(fp);

% Remove foreign characters from input text:
str = ForeignChars(str);

% Write text:
fp = fopen(infile,'w');
fprintf(fp,'%s',str);
fclose(fp);

% Run parser:
system(sprintf('%s %s > %s',BIN_STANFORD,infile,outfile));

% Read output:
fp = fopen(outfile,'r');
parsed_str = [];
while 1
  tline = fgets(fp);
  if ~ischar(tline), break, end
  parsed_str = [parsed_str tline];
end  
fclose(fp);

% Clean up:
delete(infile);
delete(outfile);

return;

