local Class = require 'lib.hump.class'
local MapType = require 'pud.map.MapType'


-- DoorMapType
-- represents a floor MapType
local DoorMapType = Class{name='DoorMapType',
	inherits=MapType,
	function(self, ...)
		-- variants must be set before parent constructor is called
		self._variants = {
			default = 'shut',
			shut = 'shut',
			open = 'open',
		}
		MapType.construct(self, ...)

		self._defaultLit = true
	end
}

-- destructor
function DoorMapType:destroy()
	MapType.destroy(self)
end

-- override MapType:setVariant() to change attributes when variant changes.
function DoorMapType:setVariant(variant)
	MapType.setVariant(self, variant)
	self._defaultTransparent = self._variant == 'open'
	self._defaultAccessible = self._variant == 'open'
end


-- the class
return DoorMapType
