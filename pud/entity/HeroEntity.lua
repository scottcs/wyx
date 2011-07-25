local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'

-- HeroEntity
--
local HeroEntity = Class{name='HeroEntity',
	inherits=Entity,
	function(self)
		Entity.construct(self)
	end
}

-- destructor
function HeroEntity:destroy()
	Entity.destroy(self)
end


-- the class
return HeroEntity
