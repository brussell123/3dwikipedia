function str = ForeignChars(str)

foreign_chars = [char(231) char(255) char(232) char(233) char(183) char(236) char(194) char(160) char(226) char(249)];
swap_chars = 'c-ee ia au';
% $$$ foreign_chars = [char(231) char(255) char(232) char(233) char(183) char(236) char(194) char(160) char(226) char(128) char(148) char(153)];
% $$$ swap_chars = 'c-ee ia a a ';

for i = 1:length(foreign_chars)
  str(ismember(str,foreign_chars(i))) = swap_chars(i);
end

allchar = ['ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.(),:;-'' "%/[]$!?&' char(10)];

if ~isempty(str(~ismember(str,allchar)))
  display(sprintf('Need to handle the following chars: %s',str(~ismember(str,allchar))));
  keyboard;
  foo = str(~ismember(str,allchar))
  sprintf('%d ',foo)
end

