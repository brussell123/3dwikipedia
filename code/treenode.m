classdef treenode < handle
	properties
		parent% - node
		child% - node(s)
		tag% - string
		word% - string
		id% - number
		document_id=1;% - number
	end

	methods
		function obj = treenode(tag)
			obj.tag = tag;
		end
	end
end
