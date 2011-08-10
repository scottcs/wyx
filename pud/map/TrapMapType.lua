local Class = require 'lib.hump.class'
local MapType = getClass('pud.map.MapType')


-- TrapMapType
-- represents a floor MapType
local TrapMapType = Class{name='TrapMapType',
	inherits=MapType,
	function(self, ...)
		-- variants must be set before parent constructor is called
		self._variants = {
			default = 'normal',
			normal = 'normal',
		}
		MapType.construct(self, ...)

		self._defaultTransparent = true
		self._defaultAccessible = true
		self._defaultLit = true
	end
}

-- destructor
function TrapMapType:destroy()
	MapType.destroy(self)
end


-- the class
return TrapMapType
