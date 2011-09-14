local Class = require 'lib.hump.class'
local EntityDB = getClass 'wyx.entity.EntityDB'
local HeroEntityFactory = getClass 'wyx.entity.HeroEntityFactory'
local property = require 'wyx.component.property'

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

-- calculate the elevel of this entity based on relevant properties.
function HeroEntityDB:_calculateELevel(info) return nil end

-- the class
return HeroEntityDB
