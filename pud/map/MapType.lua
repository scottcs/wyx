local Class = require 'lib.hump.class'

-- MapType
-- represents a type and variant of a map node
local MapType = Class{name='MapType',
	function(self, variant, style)
		self._variants = self._variants or {
			default = 'empty',
			empty = 'empty',
		}
		self._defaultTransparent = false
		self._defaultAccessible = false
		self._defaultLit = false
		self:setVariant(variant or 'default')
		if style then self:setStyle(style) end
	end
}

-- destructor
function MapType:destroy()
	self._variant = nil
	self._style = nil
	self._defaultTransparent = nil
	self._defaultAccessible = nil
	self._defaultLit = nil
end

-- getter and setter for variant.
-- variant must be defined in self._variants.
function MapType:getVariant() return self._variant end
function MapType:setVariant(variant)
	assert(variant and self._variants[variant],
		'unknown variant for %s: %s', tostring(self.__class), tostring(variant))

	self._variant = self._variants[variant]
	self:_setKey()
end

-- getter and setter for style.
-- style can be anything the user needs.
function MapType:getStyle() return self._style end
function MapType:setStyle(style)
	self._style = style
	self:_setKey()
end

-- return a table of the default attributes for a MapNode with this MapType
function MapType:getDefaultAttributes()
	return {
		transparent = self._defaultTransparent,
		accessible = self._defaultAccessible,
		lit = self._defaultLit,
	}
end

-- set the unique key for this MapType
function MapType:_setKey()
	self._key = tostring(self.__class)..'-'..tostring(self._variant)
	if self._style then self._key = self._key..'-'..tostring(self._style) end
end

-- return a key that uniquely identifies this MapType's class, variant and
-- style.
function MapType:getKey()
	if not self._key then self:_setKey() end
	return self._key
end

-- return true if any of the given MapTypes have the same class and variant
-- (but disregarding style) as this one.
function MapType:isType(...)
	for i=1,select('#', ...) do
		local mapType = select(i, ...)
		assert(type(mapType) == 'table'
			and mapType.is_a and mapType:is_a(MapType),
			'MapType:isType() expects a MapType (was %s, %s)',
			tostring(mapType), type(mapType))

		if mapType:is_a(self.__class)
			and mapType:getVariant() == self:getVariant()
		then
			return true
		end
	end
	return false
end

-- represent this MapType as a string
function MapType:__tostring()
	local str = tostring(self.__class)..' ('..tostring(self._variant)
	if self._style then str = str..', '..tostring(self._style) end
	str = str..')'
	return str
end

-- the class
return MapType
