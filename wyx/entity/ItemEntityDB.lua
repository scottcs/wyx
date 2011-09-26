local Class = require 'lib.hump.class'
local EntityDB = getClass 'wyx.entity.EntityDB'
local ItemEntityFactory = getClass 'wyx.entity.ItemEntityFactory'

local format = string.format

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

function ItemEntityDB:_processEntityInfo(info)
	local name = info.name

	if not name then
		if info.family and info.kind then
			if info.family == 'Ring' then
				name = format('%s of %s', info.family, info.kind)
			elseif info.family == 'Armor' then
				name = format('%s %s', info.kind, info.family)
			end
		end
	end

	info.name = name or info.kind or 'UNKNOWN'

	local ret = EntityDB._processEntityInfo(self, info)
	return ret
end

-- the class
return ItemEntityDB
