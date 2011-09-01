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
	self._loadstate = nil
	self._eregistry:destroy()
	self._eregistry = nil
	self._places = nil
	self._curPlace = nil
	self._lastPlace = nil
end

-- generate the world
function World:generate()
	if self._loadstate then
		self._eregistry:setState(self._loadstate.eregistry)

		for name,place in pairs(self._loadstate.places) do
			if place.class == 'Dungeon' then
				local dungeon = Dungeon(name)
				dungeon:setState(place)
				dungeon:regenerate()
				self:addPlace(dungeon)
			end
		end

		self._curPlace = self._loadstate.curPlace
		self._lastPlace = self._loadstate.lastPlace

		self._loadstate = nil
	else
		local dungeon = Dungeon('Lonely Dungeon')
		dungeon:generateLevel(1)
		self:addPlace(dungeon)
	end
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

-- save the world (forget the cheerleader)
function World:getState()
	local mt = {__mode = 'kv'}
	local state = setmetatable({}, mt)
	state.places = setmetatable({}, mt)

	state.curPlace = self._curPlace
	state.lastPlace = self._lastPlace
	state.eregistry = self._eregistry:getState()

	for name, place in pairs(self._places) do
		state.places[name] = place:getState()
	end

	return state
end

-- load the world
function World:setState(state) self._loadstate = state end


-- the class
return World
