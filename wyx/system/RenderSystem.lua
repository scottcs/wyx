local Class = require 'lib.hump.class'
local ListenerBag = getClass 'wyx.kit.ListenerBag'
local property = require 'wyx.component.property'
local pRenderDepth = property('RenderDepth')
local depths = require 'wyx.system.renderDepths'

local table_sort = table.sort

-- RenderSystem
--
local RenderSystem = Class{name='RenderSystem',
	function(self)
		self._registered = {}
		self._depths = {}
		self._defaultDepth = depths.default
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
	depth = depth or self:_getObjectDepth(obj)
	verify('number', depth)

	self:_touchDepth(depth)
	self._registered[depth]:push(obj)
end

-- unregister an object
function RenderSystem:unregister(obj)
	local depth = self:_getObjectDepth(obj)

	if depth then
		if self._registered[depth] then
			self._registered[depth]:pop(obj)
		end
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

function RenderSystem:_getObjectDepth(obj)
	local depth

	if type(obj) == 'string' then obj = EntityRegistry:get(obj) end

	if type(obj) == 'table' then
		if obj.getDepth and type(obj.getDepth) == 'function' then
			depth = obj:getDepth()
		elseif obj.query and type(obj.query) == 'function' then
			depth = obj:query(pRenderDepth)
		elseif obj.getProperty and type(obj.getProperty) == 'function' then
			depth = obj:getProperty(pRenderDepth)
		end
	else
		depth = self._defaultDepth
	end

	return depth
end


-- the class
return RenderSystem
