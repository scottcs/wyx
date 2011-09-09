local Class = require 'lib.hump.class'
local ListenerBag = getClass 'wyx.kit.ListenerBag'

local table_sort = table.sort

-- RenderSystem
--
local RenderSystem = Class{name='RenderSystem',
	function(self)
		self._registered = {}
		self._depths = {}
	end
}

-- destructor
function RenderSystem:destroy()
	for k,bag in pairs(self._registered) do
		bag:destroy()
		self._registered[k] = nil
	end
	self._registered = nil
	self._depths = nil
end

-- draw
function RenderSystem:draw()
	for i=#self._depths,1,-1 do
		local depth = self._depths[i]
		for obj in self._registered[depth]:listeners() do obj:draw() end
	end
end

-- make sure the given depth exists
function RenderSystem:_touchDepth(depth)
	if not self._registered[depth] then
		self._registered[depth] = ListenerBag()

		-- create sorted, unique array
		local unique = {}
		unique[depth] = true

		for i,l in pairs(self._depths) do
			unique[l] = true
			self._depths[i] = nil
		end

		for l in pairs(unique) do self._depths[#self._depths+1] = l end
		table_sort(self._depths)
	end
end

-- register an object
function RenderSystem:register(obj, depth)
	depth = depth or 1
	verify('number', depth)
	self:_touchDepth(depth)
	self._registered[depth]:push(obj)
end

-- unregister an object
function RenderSystem:unregister(obj)
	for _,l in pairs(self._depths) do
		if self._registered[l] then self._registered[l]:pop(obj) end
	end
end


-- the class
return RenderSystem
