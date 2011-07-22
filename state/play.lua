
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
local _mapTileW, _mapTileH

function st:init()
end

function st:enter()
	self._keyDelay, self._keyInterval = love.keyboard.getKeyRepeat()
	love.keyboard.setKeyRepeat(200, 25)

	self._timeManager = TimeManager()

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

	self:_generateMap(true)
end

function st:_generateMap(fromFile)
	if self._map then self._map:destroy() end
	local builder

	if fromFile then
		local FileMapBuilder = require 'pud.level.FileMapBuilder'
		local mapfiles = {'test'}
		local mapfile = mapfiles[math.random(1,#mapfiles)]
		builder = FileMapBuilder(mapfile)
	else
		local SimpleGridMapBuilder = require 'pud.level.SimpleGridMapBuilder'
		builder = SimpleGridMapBuilder(MAPW,MAPH, 10,10, 20,35)
	end

	self._map = LevelDirector:generateStandard(builder)
	builder:destroy()
	print(self._map)

	local w, h = self._map:getSize()
	_mapTileW, _mapTileH = w*TILESIZE, h*TILESIZE
	if self._view then self._view:destroy() end
	self._view = TileLevelView(w, h)
	self._view:registerEvents()

	local startX = math_floor(w/2+0.5)*TILESIZE - math_floor(TILESIZE/2)
	local startY = math_floor(h/2+0.5)*TILESIZE - math_floor(TILESIZE/2)
	self._startVector = vector(startX, startY)
	if not self._cam then
		self._cam = Camera(self._startVector, 1)
	end
	self._cam.pos = self._startVector
	self:_correctCam()
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

	-- temporary center square
	local size = self._cam.zoom * TILESIZE
	local x = math_floor(WIDTH/2)-math_floor(size/2)
	local y = math_floor(HEIGHT/2)-math_floor(size/2)
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle('line', x, y, size, size)
end

function st:leave()
	love.keyboard.setKeyRepeat(self._keyDelay, self._keyInterval)
	self._timeManager:destroy()
	self._timeManager = nil
	self._view:destroy()
	self._view = nil
end

-- correct the camera values after moving
function st:_correctCam()
	local wmin = math_floor(TILESIZE/2)
	local wmax = _mapTileW - wmin
	if self._cam.pos.x > wmax then self._cam.pos.x = wmax end
	if self._cam.pos.x < wmin then self._cam.pos.x = wmin end

	local hmin = wmin
	local hmax = _mapTileH - hmin
	if self._cam.pos.y > hmax then self._cam.pos.y = hmax end
	if self._cam.pos.y < hmin then self._cam.pos.y = hmin end
end

function st:keypressed(key, unicode)
	switch(key) {
		escape = function() love.event.push('q') end,
		m = function() self:_generateMap() end,
		f = function() self:_generateMap(true) end,

		-- camera
		left = function()
			if not self._cam then return end
			local amt = vector(-TILESIZE/self._cam.zoom, 0)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		right = function()
			if not self._cam then return end
			local amt = vector(TILESIZE/self._cam.zoom, 0)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		up = function()
			if not self._cam then return end
			local amt = vector(0, -TILESIZE/self._cam.zoom)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		down = function()
			if not self._cam then return end
			local amt = vector(0, TILESIZE/self._cam.zoom)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		pageup = function()
			if not self._cam then return end
			self._cam.zoom = math_max(0.25, self._cam.zoom * (1/2))
			self:_correctCam()
		end,
		pagedown = function() 
			if not self._cam then return end
			self._cam.zoom = math_min(1, self._cam.zoom * 2)
			self:_correctCam()
		end,
		home = function()
			if not self._cam then return end
			self._cam.zoom = 1
			self._cam.pos = self._startVector
			self:_correctCam()
		end,
	}
end

return st
