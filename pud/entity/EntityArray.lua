local Class = require 'lib.hump.class'
local property = require 'pud.component.property'

local table_sort = table.sort

-- EntityArray
--
local EntityArray = Class{name='EntityArray',
	function(self, ...)
		self._entities = {}
		self._count = 0
		if select('#', ...) > 0 then self:add(...) end
	end
}

-- destructor
function EntityArray:destroy()
	self:clear()
	self._entities = nil
	self._count = nil
end

-- add entities to the array
function EntityArray:add(id)
	verify('number', id)

	local success = false

	if not self._entities[id] then
		self._entities[id] = true
		self._count = self._count + 1
		success = true
	end

	return success
end

-- remove entities from the array
function EntityArray:remove(id)
	local success = false

	if self._entities[id] then
		self._entities[id] = nil
		self._count = self._count - 1
		success = true
	end

	return success
end

-- return the entity table as an unsorted array of IDs.
-- if property is supplied, only entities with that property (non-nil) are
-- returned.
function EntityArray:getArray(prop)
	local propStr = prop and property(prop) or nil
	local array = {}
	local count = 0
	for k in pairs(self._entities) do
		local ent = EntityRegistry:get(k)
		local p = not nil
		if propStr then p = ent:query(propStr) end
		if nil ~= p then
			count = count + 1
			array[count] = k
		end
	end
	return count > 0 and array or nil
end

-- get an array of all the entities, sorted by property
function EntityArray:byProperty(prop)
	local propStr = property(prop)
	local array = self:getArray(propStr)

	-- comparison function for sorting by a property
	local _byProperty = function(a, b)
		if not a then return true end
		if not b then return false end
		local aEnt, bEnt = EntityRegistry:get(a), EntityRegistry:get(b)
		local aVal, bVal = aEnt:query(propStr), bEnt:query(propStr)
		if aVal == nil then return true end
		if bVal == nil then return false end
		return aVal < bVal
	end

	table_sort(array, _byProperty)
	return array
end

-- return the size of the array
function EntityArray:size() return self._count end

-- iterate through the array
function EntityArray:iterate()
	local array = self:getArray()
	if not array then return function() end end
	local i = 0
	return function() i = i + 1; return array[i] end
end

-- clear the array
function EntityArray:clear()
	for k in pairs(self._entities) do self:remove(k) end
	self._count = 0
end

-- the class
return EntityArray
