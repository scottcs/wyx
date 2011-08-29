local Class = require 'lib.hump.class'
local Dungeon = getClass 'pud.map.Dungeon'
local EntityRegistry = getClass('pud.entity.EntityRegistry')

-- World
--
local World = Class{name='World',
	function(self)
		-- places can be dungeons, outdoor areas, towns, etc
		self._places = {}
		self._eregistry = EntityRegistry()
	end
}

-- destructor
function World:destroy()
	for k in pairs(self._places) do
		self._places[k]:destroy()
		self._places[k] = nil
	end
	self._eregistry:destroy()
	self._eregistry = nil
	self._places = nil
	self._curPlace = nil
	self._lastPlace = nil
end

-- generate the world
function World:generate()
	-- XXX nothing to do for now
end

function World:addPlace(place)
	local name = place:getName()
	self._places[name] = place
	self._curPlace = self._curPlace or name
end

-- return the current place
function World:getCurrentPlace() return self._places[self._curPlace] end

-- return the given place
function World:getPlace(name) return self._places[name] end

-- switch to the given place
function World:setPlace(name)
	verify('string', name)
	assert(self._places[name], 'No such place: %s', place)
	self._lastPlace = self._curPlace
	self._curPlace = name
end

-- return the entity registry
function World:getEntityRegistry() return self._eregistry end


-- the class
return World
