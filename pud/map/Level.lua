local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

-- map classes
local Map = getClass 'pud.map.Map'
local MapDirector = getClass 'pud.map.MapDirector'
local FileMapBuilder = getClass 'pud.map.FileMapBuilder'
local SimpleGridMapBuilder = getClass 'pud.map.SimpleGridMapBuilder'
local MapUpdateFinishedEvent = getClass 'pud.event.MapUpdateFinishedEvent'
local ZoneTriggerEvent = getClass 'pud.event.ZoneTriggerEvent'
local MapNode = getClass 'pud.map.MapNode'
local DoorMapType = getClass 'pud.map.DoorMapType'

-- events
local CommandEvent = getClass 'pud.event.CommandEvent'
local OpenDoorCommand = getClass 'pud.command.OpenDoorCommand'

-- entities
local HeroFactory = getClass 'pud.entity.HeroFactory'
local EnemyFactory = getClass 'pud.entity.EnemyFactory'
local ItemFactory = getClass 'pud.entity.ItemFactory'
local message = getClass 'pud.component.message'

-- time manager
local TimeManager = getClass 'pud.time.TimeManager'
local TICK = 0.01

local math_floor = math.floor
local math_round = function(x) return math_floor(x+0.5) end

-- Level
--
local Level = Class{name='Level',
	function(self)
		self._timeManager = TimeManager()
		self._doTick = false
		self._accum = 0

		self._heroFactory = HeroFactory()
		self._enemyFactory = EnemyFactory()
		self._itemFactory = ItemFactory()

		-- lighting color value table
		self._lightColor = {
			black = {0,0,0},
			dim = {0.4, 0.4, 0.4},
			lit = {1,1,1},
		}
		self._lightmap = {}
		self._entities = {}

		CommandEvents:register(self, CommandEvent)
	end
}

-- destructor
function Level:destroy()
	CommandEvents:unregisterAll(self)
	self._map:destroy()
	self._map = nil
	self._doTick = nil
	self._timeManager:destroy()
	self._timeManager = nil
	self._heroFactory:destroy()
	self._heroFactory = nil
	self._enemyFactory:destroy()
	self._enemyFactory = nil
	self._itemFactory:destroy()
	self._itemFactory = nil
	for k in pairs(self._entities) do
		self._entities[k]:destroy()
		self._entities[k] = nil
	end
	self._entities = nil
	for k in pairs(self._lightColor) do self._lightColor[k] = nil end
	self._lightColor = nil
	for k in pairs(self._lightmap) do self._lightmap[k] = nil end
	self._lightmap = nil
end

function Level:update(dt)
	if self._doTick then
		self._accum = self._accum + dt
		if self._accum > TICK then
			self._accum = self._accum - TICK
			--[[
			local nextActor = self._timeManager:tick()
			local numHeroCommands = self._hero:getPendingCommandCount()
			self._doTick = nextActor ~= self._hero or numHeroCommands > 0
			]]--
		end
	end
end

function Level:_attemptMove(entity)
	local moved = false

	if entity:wantsToMove() then
		local to = entity:getMovePosition()
		local node = self._map:getLocation(to.x, to.y)

		local oldEntityPos = entity:getPositionVector()
		entity:move(to, node)
		local entityPos = entity:getPositionVector()

		if entityPos ~= oldEntityPos then
			moved = true
			local zonesFrom = self._map:getZonesFromPoint(oldEntityPos)
			local zonesTo = self._map:getZonesFromPoint(entityPos)

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

		if node:getMapType():isType(DoorMapType('shut')) then
			local command = OpenDoorCommand(entity, to, self._map)
			CommandEvents:push(CommandEvent(command))
		end
	end

	return moved
end

function Level:_moveEntities()
	local heroMoved = self:_attemptMove(self._hero)
	if heroMoved then
		self._needViewUpdate = true
		self:_bakeLights()
	end
end

function Level:needViewUpdate() return self._needViewUpdate == true end
function Level:postViewUpdate() self._needViewUpdate = false end

function Level:generateFileMap(file)
	local maps = love.filesystem.enumerate('map')
	file = file or maps[Random(#maps)]
	local builder = FileMapBuilder('map/'..file)
	self:_generateMap(builder)
end

function Level:generateSimpleGridMap()
	local builder = SimpleGridMapBuilder(80,80, 10,10, 8,16)
	self:_generateMap(builder)
end

function Level:_generateMap(builder)
	if self._map then self._map:destroy() end
	self._map = MapDirector:generateStandard(builder)
	if self._hero then
		local ups = {}
		for _,name in ipairs(self._map:getPortalNames()) do
			if string.match(name, "^up%d") then ups[#ups+1] = name end
		end
		self._startPosition = self._map:getPortal(ups[Random(#ups)])
		self._hero:send(message('SET_POSITION'), self._startPosition)
		self:_bakeLights(true)
	end
	builder:destroy()
	GameEvents:push(MapUpdateFinishedEvent(self._map))
end

-- get the start vector
function Level:getStartVector() return self._startPosition:clone() end

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
function Level:getEntitiesAtLocation(pos)
	local ents = {}
	for _,entity in pairs(self._entities) do
		if entity:query(property('Position')) == pos then
			ents[#ents+1] = entity
		end
	end
	return #ents > 0 and ents or nil
end

function Level:sendToAllEntities(msg, ...)
	for _,entity in pairs(self._entities) do
		entity:send(message(msg), ...)
	end
end

function Level:createEntities()
	-- TODO: choose hero rather than hardcode Warrior
	self._hero = self._heroFactory:createEntity('Warrior')
end

function Level:CommandEvent(e)
	local command = e:getCommand()
	if command:getTarget() ~= self._hero then return end
	if isClass(OpenDoorCommand, command) then
		command:setOnComplete(self._bakeLights, self)
	end
	self._doTick = true
	self._needViewUpdate = true
end

function Level:getHero() return self._hero end

-- bake the lighting for the current hero position
local _mult = {
	{ 1,  0,  0, -1, -1,  0,  0,  1},
	{ 0,  1, -1,  0,  0, -1,  1,  0},
	{ 0,  1,  1,  0,  0, -1, -1,  0},
	{ 1,  0,  0,  1, -1,  0,  0, -1},
}

-- recursive light casting function
function Level:_castLight(c, row, first, last, radius, x, y)
	if first < last then return end
	local radiusSq = radius*radius
	local new_first

	for j=row,radius do
		local dx, dy = -j-1, -j
		local blocked = false

		while dx <= 0 do
			dx = dx + 1

			-- translate the dx, dy coordinates into map coordinates
			local mp = vector(c.x + dx * x.x + dy * x.y, c.y + dx * y.x + dy * y.y)
			-- lSlope and rSlope store the slopes of the left and right
			-- extremeties of the square we're considering
			local lSlope, rSlope = (dx-0.5)/(dy+0.5), (dx+0.5)/(dy-0.5)

			if last > lSlope then break end
			if not (first < rSlope) then
				-- our light beam is touching this square; light it
				if dx*dx + dy*dy < radiusSq then
					self._lightmap[mp.x][mp.y] = 'lit'
				end

				local node = self._map:getLocation(mp.x, mp.y)
				if blocked then
					-- we're scanning a row of blocked squares
					if not (self:isPointInMap(mp) and node:isTransparent()) then
						new_first = rSlope
						-- Note: this would be a continue statement... make sure nothing
						-- else is calculated after this
					else
						blocked = false
						first = new_first
					end
				else
					if not (self:isPointInMap(mp) and node:isTransparent())
						and j < radius
					then
						-- this is a blocking square, start a child scan
						blocked = true
						self:_castLight(c, j+1, first, lSlope, radius, x, y)
						new_first = rSlope
					end
				end
			end
		end

		if blocked then break end
	end
end

function Level:_resetLights(blackout)
	-- make old lit positions dim
	for x=1,self._map:getWidth() do
		self._lightmap[x] = self._lightmap[x] or {}
		for y=1,self._map:getHeight() do
			if blackout then
				self._lightmap[x][y] = 'black'
			else
				self._lightmap[x][y] = self._lightmap[x][y] or 'black'
				if self._lightmap[x][y] == 'lit' then self._lightmap[x][y] = 'dim' end
			end
		end
	end
end

-- bake the lighting for quick lookup at a later time
function Level:_bakeLights(blackout)
	local radius = self._hero:query('Visibility')
	local heroPos = self._hero:query('Position')

	self:_resetLights(blackout)

	for oct=1,8 do
		self:_castLight(heroPos, 1, 1, 0, radius,
			vector(_mult[1][oct], _mult[2][oct]),
			vector(_mult[3][oct], _mult[4][oct]))
	end
end

-- get a color table of the lighting for the specified point
function Level:getLightingColor(p)
	local color = self._lightmap[p.x][p.y] or 'black'
	return self._lightColor[color]
end

-- the class
return Level
