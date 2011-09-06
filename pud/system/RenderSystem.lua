local Class = require 'lib.hump.class'
local ListenerBag = getClass 'pud.kit.ListenerBag'

local table_sort = table.sort

-- RenderSystem
--
local RenderSystem = Class{name='RenderSystem',
	function(self)
		self._registered = {}
		self._depths = {}
		self._defaultDepth = 1
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
	local numDepths = #self._depths
	for i=numDepths, 1, -1 do
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
		local numDepths = #self._depths

		for i=1,numDepths do
			local l = self._depths[i]
			unique[l] = true
			self._depths[i] = nil
		end

		local count = #self._depths
		for l in pairs(unique) do
			count = count + 1
			self._depths[count] = l
		end
		table_sort(self._depths)
	end
end

-- register an object
function RenderSystem:register(obj, depth)
	if nil == depth then
		if obj
			and type(obj) == 'table'
			and obj.getDepth
			and type(obj.getDepth) == 'function'
		then
			depth = obj:getDepth()
		else
			depth = self._defaultDepth
		end
	end

	verify('number', depth)
	self:_touchDepth(depth)
	self._registered[depth]:push(obj)
end

-- unregister an object
function RenderSystem:unregister(obj)
	if obj
		and type(obj) == 'table'
		and obj.getDepth
		and type(obj.getDepth) == 'function'
	then
		local depth = obj:getDepth()
		self._registered[depth]:pop(obj)
	else
		local numDepths = #self._depths
		for i=1,numDepths do
			local l = self._depths[i]
			if self._registered[l] then
				self._registered[l]:pop(obj)
			end
		end
	end
end


-- the class
return RenderSystem
