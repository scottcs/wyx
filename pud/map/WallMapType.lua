local Class = require 'lib.hump.class'
local MapType = getClass('pud.map.MapType')


-- WallMapType
-- represents a floor MapType
local WallMapType = Class{name='WallMapType',
	inherits=MapType,
	function(self, ...)
		-- variants must be set before parent constructor is called
		self._variants = {
			default = 'normal',
			normal = 'normal',
			worn = 'worn',
			vertical = 'vertical',
			torch = 'torch',
		}
		MapType.construct(self, ...)

		self._defaultLit = true
	end
}

-- destructor
function WallMapType:destroy()
	MapType.destroy(self)
end


-- the class
return WallMapType
