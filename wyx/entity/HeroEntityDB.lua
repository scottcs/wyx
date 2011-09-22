local Class = require 'lib.hump.class'
local EntityDB = getClass 'wyx.entity.EntityDB'
local HeroEntityFactory = getClass 'wyx.entity.HeroEntityFactory'

-- HeroEntityDB
--
local HeroEntityDB = Class{name='HeroEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'hero')
		self._factory = HeroEntityFactory()
	end
}

-- destructor
function HeroEntityDB:destroy()
	self._factory:destroy()
	self._factory = nil
	EntityDB.destroy(self)
end


-- the class
return HeroEntityDB
