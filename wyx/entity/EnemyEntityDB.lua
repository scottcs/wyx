local Class = require 'lib.hump.class'
local EntityDB = getClass 'wyx.entity.EntityDB'
local EnemyEntityFactory = getClass 'wyx.entity.EnemyEntityFactory'

-- EnemyEntityDB
--
local EnemyEntityDB = Class{name='EnemyEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'enemy')
		self._factory = EnemyEntityFactory()
	end
}

-- destructor
function EnemyEntityDB:destroy()
	self._factory:destroy()
	self._factory = nil
	EntityDB.destroy(self)
end


-- the class
return EnemyEntityDB
