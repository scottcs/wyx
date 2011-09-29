local Class = require 'lib.hump.class'
local Dungeon = getClass 'wyx.map.Dungeon'
local EntityRegistry = getClass 'wyx.entity.EntityRegistry'
local HeroEntityFactory = getClass 'wyx.entity.HeroEntityFactory'
local PrimeEntityChangedEvent = getClass 'wyx.event.PrimeEntityChangedEvent'
local message = getClass 'wyx.component.message'
local property = require 'wyx.component.property'

-- World
--
local World = Class{name='World',
	function(self)
		-- places can be dungeons, outdoor areas, towns, etc
		self._places = {}
		self._heroFactory = HeroEntityFactory()
		self._eregistry = EntityRegistry()
	end
}

-- destructor
function World:destroy()
	self._heroFactory:destroy()
	self._heroFactory = nil

	for k in pairs(self._places) do
		self._places[k]:destroy()
		self._places[k] = nil
	end

	self._primeEntity = nil
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

		self:_loadHero()

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
	else
		local dungeon = Dungeon('Lonely Dungeon')
		dungeon:generateLevel(1)
		self:addPlace(dungeon)
	end

	local place = self:getCurrentPlace()
	local level = place:getCurrentLevel()

	if self._primeEntity then
		level:addEntity(self._primeEntity)
		local entity = self._eregistry:get(self._primeEntity)

		local x, y
		if self._loadstate then
			local pos = entity:query(property('Position'))
			x, y = pos[1], pos[2]
		else
			x, y = level:getRandomPortalPosition()
		end

		entity:send(message('SET_POSITION'), x, y, x, y)
	end

	level:notifyEntitiesLoaded()
	self._loadstate = nil
end

function World:_loadHero()
	if self._loadstate then
		local id = self._loadstate.primeEntity
		info = self._eregistry:getEntityLoadState(id)
		local newID = self._heroFactory:createEntity(info)

		self._heroFactory:registerEntity(newID)
		self._eregistry:setDuplicateID(id, newID)

		self:setPrimeEntity(newID)
	end
end

function World:createHero(info)
	local id = self._heroFactory:createEntity(info)
	self._heroFactory:registerEntity(id)
	self:setPrimeEntity(id)
end

function World:getPrimeEntity() return self._primeEntity end

function World:setPrimeEntity(id)
	local old = self._primeEntity
	self._primeEntity = id

	local PIC = getClass 'wyx.component.PlayerInputComponent'
	local input = PIC()
	self._heroFactory:setInputComponent(self._primeEntity, input)

	local entity = self._eregistry:get(self._primeEntity)

	local TimeComponent = getClass 'wyx.component.TimeComponent'
	local timeComps = entity:getComponentsByClass(TimeComponent)
	if timeComps and #timeComps > 0 then
		TimeSystem:setFirst(timeComps[1])
		entity:send(message('TIME_AUTO'), false)
	end

	entity:send(message('CONTAINER_RESIZE'), 10)

	GameEvents:push(PrimeEntityChangedEvent(self._primeEntity))
	return old
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
	local state = {}
	state.places = {}

	state.curPlace = self._curPlace
	state.lastPlace = self._lastPlace
	state.primeEntity = self._primeEntity
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
