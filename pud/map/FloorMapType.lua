local Class = require 'lib.hump.class'
local MapType = getClass 'pud.map.MapType'


-- FloorMapType
-- represents a floor MapType
local FloorMapType = Class{name='FloorMapType',
	inherits=MapType,
	function(self, ...)
		-- variants must be set before parent constructor is called
		self._variants = {
			default = 'normal',
			normal = 'normal',
			worn = 'worn',
			interior = 'interior',
			rug = 'rug',
		}
		MapType.construct(self, ...)

		self._defaultTransparent = true
		self._defaultAccessible = true
		self._defaultLit = true
	end
}

-- destructor
function FloorMapType:destroy()
	MapType.destroy(self)
end


-- the class
return FloorMapType
