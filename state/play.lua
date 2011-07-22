
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local math_floor, math_max, math_min = math.floor, math.max, math.min

-- Camera
local Camera = require 'lib.hump.camera'
local vector = require 'lib.hump.vector'

-- Time Manager
local TimeManager = require 'pud.time.TimeManager'
local TimedObject = require 'pud.time.TimedObject'

-- map builder
local LevelDirector = require 'pud.level.LevelDirector'

-- level view
local TileLevelView = require 'pud.level.TileLevelView'

-- events
local OpenDoorEvent = require 'pud.event.OpenDoorEvent'
local GameStartEvent = require 'pud.event.GameStartEvent'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'

-- some defaults
local TILESIZE = 32
local MAPW, MAPH = 100, 100
local FBW, FBH = MAPW * TILESIZE, MAPH * TILESIZE

function st:init()
end

function st:enter()
	self._timeManager = TimeManager()
	self._view = TileLevelView(MAPW, MAPH)
	self._view:registerEvents()

	self._startVector = vector(math_floor(FBW/2), math_floor(FBH/2))
	self._cam = Camera(self._startVector, 1)

	local player = TimedObject()
	local dragon = TimedObject()
	local ifrit = TimedObject()

	player.name = 'Player'
	dragon.name = 'Dragon'
	ifrit.name = 'Ifrit'

	local test = false

	function player:OpenDoorEvent(e)
		if test then
			print('player')
			print(tostring(e))
		end
	end

	function dragon:onEvent(e)
		if test then
			print('dragon')
			print(tostring(e))
		end
	end

	function ifrit:onEvent(e)
		if test then
			print('ifrit')
			print(tostring(e))
		end
	end

	function player:getSpeed(ap) return 1 end
	function player:doAction(ap)
		GameEvent:notify(GameStartEvent(), 234, ap)
		return 2
	end

	function dragon:getSpeed(ap) return 1.03 end
	function dragon:doAction(ap)
		return 5
	end

	function ifrit:getSpeed(ap) return 1.27 end
	function ifrit:doAction(ap)
		GameEvent:push(OpenDoorEvent(self.name))
		return 2
	end

	local function ifritOpenDoorCB(e)
		ifrit:onEvent(e)
	end

	GameEvent:register(player, OpenDoorEvent)
	GameEvent:register(ifritOpenDoorCB, OpenDoorEvent)
	GameEvent:register(dragon, GameStartEvent)

	self._timeManager:register(player, 3)
	self._timeManager:register(dragon, 3)
	self._timeManager:register(ifrit, 3)

	self:_generateMap()
end

function st:_generateMap()
	if self._map then self._map:destroy() end

	---[[--
	local SimpleGridMapBuilder = require 'pud.level.SimpleGridMapBuilder'
	local builder = SimpleGridMapBuilder()
	self._map = LevelDirector:generateStandard(builder, 100,100, 10,10, 20,35)
	--]]--
	--[[--
	local FileMapBuilder = require 'pud.level.FileMapBuilder'
	local builder = FileMapBuilder()
	self._map = LevelDirector:generateStandard(builder, 'test')
	--]]--

	builder:destroy()
	print(self._map)
end

local _accum = 0
local _count = 0
local TICK = 0.01

function st:update(dt)
	_accum = _accum + dt
	if _accum > TICK then
		_count = _count + 1
		_accum = _accum - TICK
		self._timeManager:tick()
		if _count % 100 == 0 and self._map then
			GameEvent:push(MapUpdateFinishedEvent(self._map))
		end
	end
end

function st:draw()
	self._cam:predraw()
	self._view:draw()
	self._cam:postdraw()
end

function st:leave()
	self._timeManager:destroy()
	self._timeManager = nil
	self._view:destroy()
	self._view = nil
end

-- correct the camera values after moving
function st:_correctCam()
	local wmin = math_floor((WIDTH/2)/self._cam.zoom + 0.5)
	local wmax = FBW - wmin
	if self._cam.pos.x < wmin then self._cam.pos.x = wmin end
	if self._cam.pos.x > wmax then self._cam.pos.x = wmax end

	local hmin = math_floor((HEIGHT/2)/self._cam.zoom + 0.5)
	local hmax = FBH - hmin
	if self._cam.pos.y < hmin then self._cam.pos.y = hmin end
	if self._cam.pos.y > hmax then self._cam.pos.y = hmax end
end

function st:keypressed(key, unicode)
	switch(key) {
		escape = function() love.event.push('q') end,
		m = function() self:_generateMap() end,

		-- camera
		left = function()
			local amt = vector(-TILESIZE/self._cam.zoom, 0)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		right = function()
			local amt = vector(TILESIZE/self._cam.zoom, 0)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		up = function()
			local amt = vector(0, -TILESIZE/self._cam.zoom)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		down = function()
			local amt = vector(0, TILESIZE/self._cam.zoom)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		pageup = function()
			self._cam.zoom = math_max(0.25, self._cam.zoom * (1/2))
			self:_correctCam()
		end,
		pagedown = function() 
			self._cam.zoom = math_min(1, self._cam.zoom * 2)
			self:_correctCam()
		end,
		home = function()
			self._cam.zoom = 1
			self._cam.pos = self._startVector
			self:_correctCam()
		end,
	}
end

return st
