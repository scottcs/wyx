local Class = require 'lib.hump.class'
local EntityDB = getClass 'wyx.entity.EntityDB'
local ItemEntityFactory = getClass 'wyx.entity.ItemEntityFactory'

-- ItemEntityDB
--
local ItemEntityDB = Class{name='ItemEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'item')
		self._factory = ItemEntityFactory()
	end
}

-- destructor
function ItemEntityDB:destroy()
	self._factory:destroy()
	self._factory = nil
	EntityDB.destroy(self)
end


-- the class
return ItemEntityDB
