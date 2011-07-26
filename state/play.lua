
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local math_floor, math_max, math_min = math.floor, math.max, math.min

-- Camera
local GameCam = require 'pud.view.GameCam'
local vector = require 'lib.hump.vector'

-- map builder
local MapDirector = require 'pud.map.MapDirector'

-- level view
local TileMapView = require 'pud.view.TileMapView'

-- events
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'


function st:enter()
	self._keyDelay, self._keyInterval = love.keyboard.getKeyRepeat()
	love.keyboard.setKeyRepeat(200, 25)

	--self:_generateMapFromFile()
	self:_generateMapRandomly()
	self:_createView()
	self:_createCamera()
	self:_createHUD()
	self:_drawHUDfb()
end

function st:_generateMapFromFile()
	local FileMapBuilder = require 'pud.map.FileMapBuilder'
	local mapfiles = {'test'}
	local mapfile = mapfiles[math.random(1,#mapfiles)]
	local builder = FileMapBuilder(mapfile)

	self:_generateMap(builder)
end

function st:_generateMapRandomly()
	local SimpleGridMapBuilder = require 'pud.map.SimpleGridMapBuilder'
	local builder = SimpleGridMapBuilder(100,100, 10,10, 20,35)

	self:_generateMap(builder)
end

function st:_generateMap(builder)
	if self._map then self._map:destroy() end
	self._map = MapDirector:generateStandard(builder)
	builder:destroy()
	GameEvent:push(MapUpdateFinishedEvent(self._map))
end

function st:_createView(viewClass)
	if self._view then self._view:destroy() end
	self._view = TileMapView(self._map)

	self._view:registerEvents()
end

function st:_createCamera()
	local mapW, mapH = self._map:getSize()
	local tileW, tileH = self._view:getTileSize()
	local mapTileW, mapTileH = mapW * tileW, mapH * tileH
	local startX = math_floor(mapW/2+0.5) * tileW - math_floor(tileW/2)
	local startY = math_floor(mapH/2+0.5) * tileH - math_floor(tileH/2)
	local zoom = 1

	if self._cam then
		zoom = self._cam:getZoom()
		self._cam:destroy()
	end

	self._cam = GameCam(vector(startX, startY), zoom)

	local min = vector(math_floor(tileW/2), math_floor(tileH/2))
	local max = vector(mapTileW - min.x, mapTileH - min.y)
	self._cam:setLimits(min, max)
	self._view:setViewport(self._cam:getViewport())
end

function st:_createHUD()
	if not self._HUDfb then
		local w, h = nearestPO2(WIDTH), nearestPO2(HEIGHT)
		self._HUDfb = love.graphics.newFramebuffer(w, h)
	end
end

local _accum = 0
local TICK = 0.001

function st:update(dt)
	_accum = _accum + dt
	if _accum > TICK then
		_accum = _accum - TICK
	end
	self:_drawHUDfb()
end

function st:_drawHUD()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self._HUDfb)
end

function st:_drawHUDfb()
	love.graphics.setRenderTarget(self._HUDfb)

	-- temporary center square
	local tileW = self._view:getTileSize()
	local _,zoomAmt = self._cam:getZoom()
	local size = zoomAmt * tileW
	local x = math_floor(WIDTH/2)-math_floor(size/2)
	local y = math_floor(HEIGHT/2)-math_floor(size/2)
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle('line', x, y, size, size)

	if debug then
		love.graphics.setFont(GameFont.small)
		local fps = love.timer.getFPS()
		local color = {1, 1, 1}
		if fps < 20 then
			color = {1, 0, 0}
		elseif fps < 60 then
			color = {1, .9, 0}
		end
		love.graphics.setColor(color)
		love.graphics.print('fps: '..tostring(fps), 8, 8)
	end

	love.graphics.setRenderTarget()
end

function st:draw()
	self._cam:predraw()
	self._view:draw()
	self._cam:postdraw()
	self:_drawHUD()
end

function st:leave()
	love.keyboard.setKeyRepeat(self._keyDelay, self._keyInterval)
	self._view:destroy()
	self._view = nil
end

function st:_translateCam(x, y)
	if not self._cam:isAnimating() then
		self._view:setAnimate(false)
		local translate = vector(x, y)
		self._view:setViewport(self._cam:getViewport(translate))
		self._cam:translate(vector(x, y),
			self._view.setAnimate, self._view, true)
	end
end

function st:_postZoomIn(vp)
	self._view:setViewport(vp)
	self._view:setAnimate(true)
end

function st:keypressed(key, unicode)
	local tileW, tileH = self._view:getTileSize()
	local _,zoomAmt = self._cam:getZoom()

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
		left = function() self:_translateCam(-tileW/zoomAmt, 0) end,
		right = function() self:_translateCam(tileW/zoomAmt, 0) end,
		up = function() self:_translateCam(0, -tileH/zoomAmt) end,
		down = function() self:_translateCam(0, tileH/zoomAmt) end,
		pageup = function()
			if not self._cam:isAnimating() then
				self._view:setAnimate(false)
				self._view:setViewport(self._cam:getViewport(nil, 1))
				self._cam:zoomOut(self._view.setAnimate, self._view, true)
			end
		end,
		pagedown = function()
			if not self._cam:isAnimating() then
				local vp = self._cam:getViewport(nil, -1)
				self._cam:zoomIn(self._postZoomIn, self, vp)
			end
		end,
		home = function()
			if not self._cam:isAnimating() then
				self._view:setViewport(self._cam:getViewport())
				self._cam:home()
			end
		end,
	}
end

return st
