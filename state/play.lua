
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

-- map builder
local LevelDirector = require 'pud.level.LevelDirector'

-- level view
local TileLevelView = require 'pud.view.TileLevelView'

-- events
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'


function st:enter()
	self._keyDelay, self._keyInterval = love.keyboard.getKeyRepeat()
	love.keyboard.setKeyRepeat(200, 25)

	self:_generateMapFromFile()
	self:_createView()
	self:_createCamera()
	GameEvent:push(MapUpdateFinishedEvent(self._map))
end

function st:_generateMapFromFile()
	local FileMapBuilder = require 'pud.level.FileMapBuilder'
	local mapfiles = {'test'}
	local mapfile = mapfiles[math.random(1,#mapfiles)]
	local builder = FileMapBuilder(mapfile)

	self:_generateMap(builder)
end

function st:_generateMapRandomly()
	local SimpleGridMapBuilder = require 'pud.level.SimpleGridMapBuilder'
	local builder = SimpleGridMapBuilder(100,100, 10,10, 20,35)

	self:_generateMap(builder)
end

function st:_generateMap(builder)
	if self._map then self._map:destroy() end
	self._map = LevelDirector:generateStandard(builder)
	builder:destroy()
	GameEvent:push(MapUpdateFinishedEvent(self._map))
end

function st:_createView(viewClass)
	local w, h = self._map:getSize()

	if self._view then self._view:destroy() end
	self._view = TileLevelView(self._map)

	local tileW, tileH = self._view:getTileSize()
	self._mapTileW, self._mapTileH = w*tileW, h*tileH
	self._view:registerEvents()
end

function st:_createCamera()
	local w, h = self._map:getSize()
	local tileW, tileH = self._view:getTileSize()
	local startX = math_floor(w/2+0.5)*tileW - math_floor(tileW/2)
	local startY = math_floor(h/2+0.5)*tileH - math_floor(tileH/2)
	self._startVector = vector(startX, startY)
	if not self._cam then
		self._cam = Camera(self._startVector, 1)
	end
	self._cam.pos = self._startVector
	self:_correctCam()
end

local _accum = 0
local TICK = 0.01

function st:update(dt)
	_accum = _accum + dt
	if _accum > TICK then
		_accum = _accum - TICK
	end
end

function st:draw()
	self._cam:predraw()
	self._view:draw()
	self._cam:postdraw()

	-- temporary center square
	local tileW = self._view:getTileSize()
	local size = self._cam.zoom * tileW
	local x = math_floor(WIDTH/2)-math_floor(size/2)
	local y = math_floor(HEIGHT/2)-math_floor(size/2)
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle('line', x, y, size, size)
end

function st:leave()
	love.keyboard.setKeyRepeat(self._keyDelay, self._keyInterval)
	self._view:destroy()
	self._view = nil
end

-- correct the camera values after moving
function st:_correctCam()
	local tileW, tileH = self._view:getTileSize()
	local wmin = math_floor(tileW/2)
	local wmax = self._mapTileW - wmin
	if self._cam.pos.x > wmax then self._cam.pos.x = wmax end
	if self._cam.pos.x < wmin then self._cam.pos.x = wmin end

	local hmin = math_floor(tileH/2)
	local hmax = self._mapTileH - hmin
	if self._cam.pos.y > hmax then self._cam.pos.y = hmax end
	if self._cam.pos.y < hmin then self._cam.pos.y = hmin end
end

function st:keypressed(key, unicode)
	local tileW, tileH = self._view:getTileSize()

	switch(key) {
		escape = function() love.event.push('q') end,
		m = function()
			self:_generateMapRandomly()
			self:_createView()
			self:_createCamera()
		end,
		f = function()
			self:_generateMapFromFile()
			self:_createView()
			self:_createCamera()
		end,

		-- camera
		left = function()
			if not self._cam then return end
			local amt = vector(-tileW/self._cam.zoom, 0)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		right = function()
			if not self._cam then return end
			local amt = vector(tileW/self._cam.zoom, 0)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		up = function()
			if not self._cam then return end
			local amt = vector(0, -tileH/self._cam.zoom)
			self._cam:translate(amt)
			self:_correctCam()
		end,
		down = function()
			if not self._cam then return end
			local amt = vector(0, tileH/self._cam.zoom)
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
