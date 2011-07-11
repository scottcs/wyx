-- Node
-- Nodes are useful for linked lists.
local Node = Class{name='Node',
	function(self, obj, left, right)
		self.obj = obj or nil
		self.left = left or nil
		self.right = right or nil
	end
}

-- destructor
function Node:destroy()
	self.obj = nil
	self.left = nil
	self.right = nil
end

return Node
