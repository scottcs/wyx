local Class = require 'lib.hump.class'
local EntityDB = getClass 'pud.entity.EntityDB'
local property = require 'pud.component.property'

-- HeroEntityDB
--
local HeroEntityDB = Class{name='HeroEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'hero')
	end
}

-- destructor
function HeroEntityDB:destroy()
	EntityDB.destroy(self)
end

-- calculate the elevel of this entity based on relevant properties.
function HeroEntityDB:_calculateELevel(info) return nil end

-- the class
return HeroEntityDB
