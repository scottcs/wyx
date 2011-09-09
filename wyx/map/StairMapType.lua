local Class = require 'lib.hump.class'
local MapType = getClass 'wyx.map.MapType'


-- StairMapType
-- represents a floor MapType
local StairMapType = Class{name='StairMapType',
	inherits=MapType,
	function(self, ...)
		-- variants must be set before parent constructor is called
		self._variants = {
			default = 'up',
			up = 'up',
			down = 'down',
		}
		MapType.construct(self, ...)

		self._defaultLit = true
		self._defaultAccessible = true
	end
}

-- destructor
function StairMapType:destroy()
	MapType.destroy(self)
end

-- override MapType:setVariant() to change attributes when variant changes.
function StairMapType:setVariant(variant)
	MapType.setVariant(self, variant)
	self._defaultTransparent = variant == 'down'
end


-- the class
return StairMapType
