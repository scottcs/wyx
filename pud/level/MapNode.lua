-- MapNode
-- represents a single map position
local MapNode = Class{name='MapNode',
	function(self, e, w, n, s)
		self.isAccessible = true
		self.isLit = true
		self.isTransparent = true
		self.wasSeen = false

		self.e = e
		self.w = w
		self.n = n
		self.s = s
	end
}

-- destructor
function MapNode:destroy()
	self.isAccessible = nil
	self.isLit = nil
	self.isTransparent = nil
	self.wasSeen = nil
	self.e = nil
	self.w = nil
	self.n = nil
	self.s = nil
end

-- the class
return MapNode
