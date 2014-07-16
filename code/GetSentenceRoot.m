function node = GetSentenceRoot(node)

if isempty(node.parent)
  return;
end

node = GetSentenceRoot(node.parent);

return;
