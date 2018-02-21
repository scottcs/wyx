local Class = require 'lib.hump.class'

-- map classes
local Map = getClass 'wyx.map.Map'
local MapDirector = getClass 'wyx.map.MapDirector'
local FileMapBuilder = getClass 'wyx.map.FileMapBuilder'
local SimpleGridMapBuilder = getClass 'wyx.map.SimpleGridMapBuilder'
local MapNode = getClass 'wyx.map.MapNode'
local DoorMapType = getClass 'wyx.map.DoorMapType'
local FloorMapType = getClass 'wyx.map.FloorMapType'

-- events
local MapUpdateFinishedEvent = getClass 'wyx.event.MapUpdateFinishedEvent'
local MapNodeUpdateEvent = getClass 'wyx.event.MapNodeUpdateEvent'
local ZoneTriggerEvent = getClass 'wyx.event.ZoneTriggerEvent'
local DisplayPopupMessageEvent = getClass 'wyx.event.DisplayPopupMessageEvent'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local TimeSystemCycleEvent = getClass 'wyx.event.TimeSystemCycleEvent'
local TurnCountEvent = getClass 'wyx.event.TurnCountEvent'
local EntityPositionEvent = getClass 'wyx.event.EntityPositionEvent'
local EntityDeathEvent = getClass 'wyx.event.EntityDeathEvent'
local LightingStatusRequest = getClass 'wyx.event.LightingStatusRequest'
local LightingUpdateRequest = getClass 'wyx.event.LightingUpdateRequest'

-- entities
local EnemyEntityFactory = getClass 'wyx.entity.EnemyEntityFactory'
local ItemEntityFactory = getClass 'wyx.entity.ItemEntityFactory'
local EntityArray = getClass 'wyx.entity.EntityArray'
local message = getClass 'wyx.component.message'
local property = require 'wyx.component.property'

local math_floor = math.floor
local math_ceil = math.ceil
local math_round = function(x) return math_floor(x+0.5) end
local math_random = love.math.random
local match = string.match
local format = string.format
local enumerate = love.filesystem.getDirectoryItems
local GameEvents = GameEvents

-- Level
--
local Level = Class{name='Level',
	function(self)
		self._enemyFactory = EnemyEntityFactory()
		self._itemFactory = ItemEntityFactory()

		-- lighting color value table
		self._lightColor = {
			black = colors.BLACK,
			dim = colors.GREY40,
			lit = colors.WHITE,
		}
		self._lightmap = {}
		self._entities = EntityArray()
		self._turns = 1

		GameEvents:register(self, {
			EntityPositionEvent,
			EntityDeathEvent,
			LightingStatusRequest,
			LightingUpdateRequest,
			MapNodeUpdateEvent,
			TimeSystemCycleEvent,
		})
	end
}

-- destructor
function Level:destroy()
	GameEvents:unregisterAll(self)
	self._map:destroy()
	self._map = nil

	self._enemyFactory:destroy()
	self._enemyFactory = nil
	self._itemFactory:destroy()
	self._itemFactory = nil

	self._entities:destroy()
	self._entities = nil

	for k in pairs(self._lightColor) do self._lightColor[k] = nil end
	self._lightColor = nil
	for k in pairs(self._lightmap) do self._lightmap[k] = nil end
	self._lightmap = nil

	self._turns = nil

	self._loadstate = nil
	self._generator = nil
	self._generatorArgs = nil
end

local vec2_equal = vec2.equal

function Level:_triggerZones(entity, posX, posY, oldposX, oldposY)
	if not vec2_equal(posX, posY, oldposX, oldposY) then
		local zonesFrom = self._map:getZonesFromPoint(oldposX, oldposY)
		local zonesTo = self._map:getZonesFromPoint(posX, posY)

		if zonesFrom then
			for zone in pairs(zonesFrom) do
				if zonesTo and zonesTo[zone] then
					zonesTo[zone] = nil
				else
					GameEvents:push(ZoneTriggerEvent(entity, zone, true))
				end
			end
		end

		if zonesTo then
			for zone in pairs(zonesTo) do
				GameEvents:push(ZoneTriggerEvent(entity, zone, false))
			end
		end
	end
end

function Level:needViewUpdate() return self._needViewUpdate == true end
function Level:postViewUpdate() self._needViewUpdate = false end

function Level:generateFileMap(file)
	local maps = enumerate('map')
	file = file or maps[math_random(#maps)]
	local builder = FileMapBuilder('map/'..file)
	self._generator = 'File'
	self._generatorArgs = file
	self:_generateMap(builder)
	self:_populateMap()
end

function Level:generateSimpleGridMap(seed)
	local builder = SimpleGridMapBuilder(80,80, 10,10, 8,16, seed)
	seed = builder:getSeed()
	self._generator = 'SimpleGrid'
	self._generatorArgs = seed
	self:_generateMap(builder)
	self:_populateMap()
end

function Level:_generateMap(builder)
	if self._map then self._map:destroy() end
	self._map = MapDirector:generateStandard(builder)
	builder:destroy()
end

function Level:_populateMap()
	self:removeAllEntities()
	self:createEntities()

	local setPosition = message('SET_POSITION')
	local position = property('Position')
	local remove = {}

	for entityID in self._entities:iterate() do
		if self._loadstate then
			local entity = EntityRegistry:get(entityID)
			local pos = entity:query(position)
			entity:send(setPosition, pos[1], pos[2], pos[1], pos[2])
		else
			if entityID == World:getPrimeEntity() then
				local x, y = self:getRandomPortalPosition()
				local entity = EntityRegistry:get(entityID)
				entity:send(setPosition, x, y, x, y)
			else
				local mapW, mapH = self._map:getWidth(), self._map:getHeight()
				local x, y
				local clear = false
				local tries = mapW*mapH
				repeat
					x = math_random(mapW)
					y = math_random(mapH)
					local mt = self._map:getLocation(x, y):getMapType()
					clear = mt:is_a(FloorMapType) and not self:getEntitiesAtLocation(x, y)
					tries = tries - 1
				until clear or tries == 0
				if clear and tries > 0 then
					local entity = EntityRegistry:get(entityID)
					entity:send(setPosition, x, y, x, y)
				else
					remove[#remove+1] = entityID
				end
			end
		end
	end

	for i=1,#remove do
		self:removeEntity(remove[i])
	end

	self:_resetLights(true)
	GameEvents:push(MapUpdateFinishedEvent(self._map))
end

function Level:getRandomPortalPosition()
	local ups = {}
	for _,name in ipairs(self._map:getPortalNames()) do
		if match(name, "^up%d") then ups[#ups+1] = name end
	end
	local x, y = self._map:getPortal(ups[math_random(#ups)])
	return x, y
end

-- regenerate the level from a saved state
function Level:regenerate()
	if self._loadstate then
		self._map = Map()
		self._map:setState(self._loadstate.map)
		self:_populateMap()

		self._lightColor = self._loadstate.lightColor
		self._lightmap = self._loadstate.lightmap
		self:_bakeLights()

		self._turns = self._loadstate.turns

		self._loadstate = nil
	end
end

-- get the size of the map
function Level:getMapSize() return self._map:getSize() end

-- get the MapNode at the given location on the map
function Level:getMapNode(...) return self._map:getLocation(...) end

-- get the Map Name
function Level:getMapName() return self._map:getName() end

-- get the Map Author
function Level:getMapAuthor() return self._map:getAuthor() end

-- return true if the given map is our map
function Level:isMap(map) return map == self._map end

-- return true if the given point exists on the map
function Level:isPointInMap(...) return self._map:containsPoint(...) end

-- return the entities at the given location
function Level:getEntitiesAtLocation(x, y, visibleOnly)
	local ents = {}
	local positionProp = property('Position')
	local entCount = 0

	for entityID in self._entities:iterate() do
		local entity = EntityRegistry:get(entityID)
		local ePos = entity:query(positionProp)
		if ePos[1] == x and ePos[2] == y then
			local ok = true

			if visibleOnly then
				local status = self._lightmap
					and self._lightmap[x] and self._lightmap[x][y]
				ok = status == 'lit'
			end

			if ok then
				entCount = entCount + 1
				ents[entCount] = entityID
			end
		end
	end

	return entCount > 0 and ents or nil
end

function Level:createEntities()
	if self._loadstate then
		if self._loadstate.entities then
			local num = #self._loadstate.entities

			for i=1,num do
				local id = self._loadstate.entities[i]
				local info = EntityRegistry:getEntityLoadState(id)

				if info then
					switch(info.etype) {
						hero = function() end,
						enemy = function()
							local newID = self._enemyFactory:createEntity(info)
							self._enemyFactory:registerEntity(newID)
							self._entities:add(newID)
							EntityRegistry:setDuplicateID(id, newID)
						end,
						item = function()
							local newID = self._itemFactory:createEntity(info)
							self._itemFactory:registerEntity(newID)
							self._entities:add(newID)
							EntityRegistry:setDuplicateID(id, newID)
						end,
						default = function()
							warning('Invalid entity type on load: %q', tostring(info.etype))
						end,
					}
				end -- if info then
			end -- for i=1,num do
		end -- if self._loadstate.entities
	else
		-- TODO: get entities algorithmically
		local enemyEntities = EnemyDB:getByELevel(1,1000)
		if enemyEntities then
			local numEnemies = 20
			local maxFamily = math_ceil(numEnemies/8)
			local families = {}
			local unique = {}
			local count = 0
			local numEnemyEntities = #enemyEntities

			while count < numEnemies do
				local which = enemyEntities[math_random(numEnemyEntities)]
				local entityID = self._enemyFactory:createEntity(which)
				local entity = EntityRegistry:get(entityID)
				local regkey = entity:getRegKey()
				local fam = entity:getFamily()
				local uniq = entity:isUnique()
				local added = false

				if uniq then
					if not unique[regkey] then
						unique[regkey] = true
						self._enemyFactory:registerEntity(entityID)
						self._entities:add(entityID)
						count = count + 1
						added = true
					end
				else
					if not families[fam] or families[fam] < maxFamily then
						families[fam] = families[fam] and families[fam] + 1 or 1
						self._enemyFactory:registerEntity(entityID)
						self._entities:add(entityID)
						count = count + 1
						added = true
					end
				end

				if not added then
					EntityRegistry:unregister(entityID)
					entity:destroy()
				end
			end
		end

		local itemEntities = ItemDB:getByELevel(1,1000)
		if itemEntities then
			local numItems = 30
			local maxFamily = math_ceil(numItems/3)
			local families = {}
			local unique = {}
			local count = 0
			local numItemEntities = #itemEntities

			while count < numItems do
				local which = itemEntities[math_random(numItemEntities)]
				local entityID = self._itemFactory:createEntity(which)
				local entity = EntityRegistry:get(entityID)
				local regkey = entity:getRegKey()
				local fam = entity:getFamily()
				local uniq = entity:isUnique()
				local added = false

				if uniq then
					if not unique[regkey] then
						unique[regkey] = true
						self._itemFactory:registerEntity(entityID)
						self._entities:add(entityID)
						count = count + 1
						added = true
					end
				else
					if not families[fam] or families[fam] < maxFamily then
						families[fam] = families[fam] and families[fam] + 1 or 1
						self._itemFactory:registerEntity(entityID)
						self._entities:add(entityID)
						count = count + 1
						added = true
					end
				end

				if not added then
					EntityRegistry:unregister(entityID)
					entity:destroy()
				end
			end
		end
	end
end

-- iterate through the entities again and send a message that all
-- entities are loaded.
function Level:notifyEntitiesLoaded()
	local message = message('ENTITIES_LOADED')
	for id in self._entities:iterate() do
		local entity = EntityRegistry:get(id)
		entity:send(message)
	end
end

function Level:removeAllEntities()
	if self._entities:size() > 0 then
		local entities = self._entities:getArray()
		self._entities:clear()
		local num = #entities

		for i=1,num do
			local entity = EntityRegistry:unregister(entities[i])
			entity:destroy()
		end
	end
end

function Level:removeEntity(entityID)
	if self._entities:remove(entityID) then
		local entity = EntityRegistry:unregister(entityID)
		entity:destroy()
	end
end

function Level:addEntity(entityID) self._entities:add(entityID) end

function Level:EntityPositionEvent(e)
	local entityID = e:getEntity()
	local dX, dY = e:getDestination()
	local oX, oY = e:getOrigin()
	self:_triggerZones(entityID, dX, dY, oX, oY)

	if entityID == World:getPrimeEntity() then
		self:_bakeLights()
		self._needViewUpdate = true
	else
		self:_notifyScreenStatus(entityID)
	end
end

function Level:LightingStatusRequest(e)
	local entityID = e:getEntity()
	local x, y = e:getPosition()
	self:_notifyScreenStatus(entityID, x, y)
end

function Level:EntityDeathEvent(e)
	local entityID = e:getEntity()
	local reason = e:getReason() or "some unknown reason"

	local entity = EntityRegistry:get(entityID)
	local name = entity and entity:getName() or "unknown entity"
	GameEvents:push(ConsoleEvent('Death: {%08s} %s [%s]',
		entityID, name, reason))

	if entityID == World:getPrimeEntity() then
		GameEvents:push(DisplayPopupMessageEvent(format(
			'GAME OVER (Killed by %s)', reason)))
	else
		self:removeEntity(entityID)
	end
end

function Level:TimeSystemCycleEvent(e)
	self._turns = self._turns + 1
	GameEvents:push(TurnCountEvent(self._turns))
end

function Level:_updateLighting()
	self:_bakeLights()
	self._needViewUpdate = true
end

function Level:MapNodeUpdateEvent(e) self:_updateLighting() end
function Level:LightingUpdateRequest(e) self:_updateLighting() end

function Level:getTurns() return self._turns end

-- bake the lighting for the current prime entity position
local _mult = {
	{ 1,  0,  0, -1, -1,  0,  0,  1},
	{ 0,  1, -1,  0,  0, -1,  1,  0},
	{ 0,  1,  1,  0,  0, -1, -1,  0},
	{ 1,  0,  0,  1, -1,  0,  0, -1},
}

-- recursive light casting function
function Level:_castLight(c, row, first, last, radius, x1, y1, x2, y2)
	if first < last then return end
	local radiusSq = radius*radius
	local new_first

	for j=row,radius do
		local dx, dy = -j-1, -j
		local blocked = false

		while dx <= 0 do
			dx = dx + 1

			-- translate the dx, dy coordinates into map coordinates
			local mpX, mpY = c[1] + dx * x1 + dy * y1,  c[2] + dx * x2 + dy * y2

			if mpX > 0 and mpY > 0 then
				-- lSlope and rSlope store the slopes of the left and right
				-- extremeties of the square we're considering
				local lSlope, rSlope = (dx-0.5)/(dy+0.5), (dx+0.5)/(dy-0.5)

				if last > lSlope then break end
				if not (first < rSlope) then
					-- our light beam is touching this square; light it
					if dx*dx + dy*dy < radiusSq then
						self._lightmap[mpX][mpY] = 'lit'
					end

					local node = self._map:getLocation(mpX, mpY)
					if blocked then
						-- we're scanning a row of blocked squares
						if not (self:isPointInMap(mpX, mpY) and node:isTransparent()) then
							new_first = rSlope
							-- Note: this would be a continue statement... make sure nothing
							-- else is calculated after this
						else
							blocked = false
							first = new_first
						end
					else
						if not (self:isPointInMap(mpX, mpY) and node:isTransparent())
							and j < radius
						then
							-- this is a blocking square, start a child scan
							blocked = true
							self:_castLight(c, j+1, first, lSlope, radius, x1, y1, x2, y2)
							new_first = rSlope
						end
					end
				end
			end
		end

		if blocked then break end
	end
end

function Level:_resetLights(blackout)
	-- make old lit positions dim
	local w, h = self._map:getWidth(), self._map:getHeight()
	for x=1,w do
		self._lightmap[x] = self._lightmap[x] or {}
		local mapx = self._lightmap[x]
		for y=1,h do
			if blackout then
				mapx[y] = 'black'
			else
				mapx[y] = mapx[y] == 'lit' and 'dim' or (mapx[y] or 'black')
			end
		end
	end
end

-- bake the lighting for quick lookup at a later time
function Level:_bakeLights(blackout)
	local primeID = World:getPrimeEntity()
	local primeEntity = EntityRegistry:get(primeID)
	local radius = primeEntity:query('Visibility')
	radius = radius + primeEntity:query('VisibilityBonus')
	local primePos = primeEntity:query('Position')

	self:_resetLights(blackout)

	for oct=1,8 do
		self:_castLight(primePos, 1, 1, 0, radius,
			_mult[1][oct], _mult[2][oct],
			_mult[3][oct], _mult[4][oct])
	end

	-- make sure prime entity is always lit
	self._lightmap[primePos[1]][primePos[2]] = 'lit'

	-- tell entities what their lights are
	for id in self._entities:iterate() do self:_notifyScreenStatus(id) end
end

local positionProp = property('Position')
local screenStatusMsg = message('SCREEN_STATUS')
function Level:_notifyScreenStatus(entityID, x, y)
	local entity = EntityRegistry:get(entityID)
	local pos = entity:query(positionProp)
	x = x or pos[1]
	y = y or pos[2]
	local status = 'black'

	if    self._lightmap
		and self._lightmap[x]
		and self._lightmap[x][y]
	then
		status = self._lightmap[x][y]
	end

	entity:send(screenStatusMsg, status, x, y)
end

-- get a color table of the lighting for the specified point
function Level:getLightingColor(x, y)
	local color = self._lightmap[x] and self._lightmap[x][y] or 'black'
	return self._lightColor[color]
end

-- get the state of this level
function Level:getState()
	local state = {}

	state.lightColor = self._lightColor
	state.lightmap = self._lightmap
	state.turns = self._turns
	state.generator = self._generator
	state.generatorArgs = self._generatorArgs
	state.entities = self._entities:getArray()
	state.map = self._map:getState()

	return state
end

-- set the state of this level
function Level:setState(state) self._loadstate = state end


-- the class
return Level
