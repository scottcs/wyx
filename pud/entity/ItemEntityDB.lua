local Class = require 'lib.hump.class'
local EntityDB = getClass 'pud.entity.EntityDB'
local property = require 'pud.component.property'

-- ItemEntityDB
--
local ItemEntityDB = Class{name='ItemEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'item')
	end
}

-- destructor
function ItemEntityDB:destroy()
	EntityDB.destroy(self)
end

-- calculate the elevel of this entity based on relevant properties.
function ItemEntityDB:_calculateELevel(info) return nil end

-- the class
return ItemEntityDB
