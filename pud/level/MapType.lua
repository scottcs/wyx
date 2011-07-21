local Class = require 'lib.hump.class'

-- table of all map types
local _allMapTypes = {
	empty = true,
	wall = true,
	torch = true,
	floor = true,
	doorClosed = true,
	doorOpen = true,
	stairUp = true,
	stairDown = true,
	trap = true,
	point = true,
}

-- private class function to validate a given map type
local _validateMapType = function(mapType)
	assert(mapType
		and ((type(mapType) == 'string' and nil ~= _allMapTypes[mapType])
		or (type(mapType) == 'table' and mapType.is_a and mapType.is_a(MapType))),
		'invalid map type: %s', tostring(mapType))
end

-- MapType
--   mapType - the actual type of this node
--   variation - can be anything the user needs
local MapType = Class{name='MapType',
	function(self, mapType, variation)
		mapType = mapType or 'empty'
		self:set(mapType, variation)
	end
}

-- destructor
function MapType:destroy()
	self._mapType = nil
	self._variation = nil
end

-- set the type and variation of this MapType.
-- mapType can be a string or a MapType object (if an object, the passed in
-- variation is ignored).
function MapType:set(mapType, variation)
	_validateMapType(mapType)

	if type(mapType) == 'string' then
		self._type = mapType
		self._variation = variation
	else
		self._type, self._variation = mapType:get()
	end
end

-- get the type and variation
function MapType:get() return self._type, self._variation end

-- return true if this type is a mapType or if this variation is the specified
-- variation (if any).
-- mapType can be a string or a MapType object (if an object, the passed in
-- variation is ignored).
function MapType:isType(mapType, variation)
	_validateMapType(mapType)

	if type(mapType) == 'table' then
		mapType, variation = mapType:get()
	end

	local isType = self._type == mapType
	if variation then isType = isType and self._variation == variation end

	return isType
end

-- the class
return MapType
