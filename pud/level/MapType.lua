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
--   variant - can be anything the user needs
local MapType = Class{name='MapType',
	function(self, mapType, variant)
		mapType = mapType or 'empty'
		self:set(mapType, variant)
	end
}

-- destructor
function MapType:destroy()
	self._mapType = nil
	self._variant = nil
end

-- set the type and variant of this MapType.
-- mapType can be a string or a MapType object (if an object, the passed in
-- variant is ignored).
function MapType:set(mapType, variant)
	_validateMapType(mapType)

	if type(mapType) == 'string' then
		self._type = mapType
		self._variant = variant
	else
		self._type, self._variant = mapType:get()
	end
end

-- get the type and variant
function MapType:get() return self._type, self._variant end

-- return true if this type is a mapType or if this variant is the specified
-- variant (if any).
-- mapType can be a string or a MapType object (if an object, the passed in
-- variant is ignored).
function MapType:isType(mapType, variant)
	_validateMapType(mapType)

	if type(mapType) == 'table' then
		mapType, variant = mapType:get()
	end

	local isType = self._type == mapType
	if variant then isType = isType and self._variant == variant end

	return isType
end

-- tostring
function MapType:__tostring()
	local str = self._type
	if self._variant then str = str..' ('..tostring(self._variant)..')' end
	return str
end

-- the class
return MapType
