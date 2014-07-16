function [str,id,t] = PrintTree(s)
% Get string corresponding to struct

if isempty(s.child)
  str = s.word;
  id = s.id;
  t = s; % Leaf node
  return;
end

[str,id,t] = PrintTree(s.child(1));
for i = 2:length(s.child)
  [si,idi,ti] = PrintTree(s.child(i));
  str = [str ' ' si];
  id = [id idi];
  t = [t ti]; % Collect leaf nodes
end

return;
