local Class = require 'lib.hump.class'
local ListenerBag = getClass 'pud.kit.ListenerBag'

local table_sort = table.sort

-- RenderSystem
--
local RenderSystem = Class{name='RenderSystem',
	function(self)
		self._registered = {}
		self._levels = {}
	end
}

-- destructor
function RenderSystem:destroy()
	for k,bag in pairs(self._registered) do
		bag:destroy()
		self._registered[k] = nil
	end
	self._registered = nil
	self._levels = nil
end

-- draw
function RenderSystem:draw()
	for i=#self._levels,1,-1 do
		local level = self._levels[i]
		for obj in self._registered[level]:listeners() do obj:draw() end
	end
end

-- make sure the given level exists
function RenderSystem:_touchLevel(level)
	if not self._registered[level] then
		self._registered[level] = ListenerBag()

		-- create sorted, unique array
		local unique = {}
		unique[level] = true

		for i,l in pairs(self._levels) do
			unique[l] = true
			self._levels[i] = nil
		end

		for l in pairs(unique) do self._levels[#self._levels+1] = l end
		table_sort(self._levels)
	end
end

-- register an object
function RenderSystem:register(obj, level)
	level = level or 1
	verify('number', level)
	self:_touchLevel(level)
	self._registered[level]:push(obj)
end

-- unregister an object
function RenderSystem:unregister(obj)
	for _,l in pairs(self._levels) do
		if self._registered[l] then self._registered[l]:pop(obj) end
	end
end


-- the class
return RenderSystem
