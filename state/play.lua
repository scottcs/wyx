
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local DebugHUD = debug and require 'pud.debug.DebugHUD'

local math_floor, math_max, math_min = math.floor, math.max, math.min
local random = Random

-- level
local Level = require 'pud.map.Level'

-- Camera
local GameCam = require 'pud.view.GameCam'
local vector = require 'lib.hump.vector'

-- events
local CommandEvent = require 'pud.event.CommandEvent'
local MoveCommand = require 'pud.command.MoveCommand'

-- views
local TileMapView = require 'pud.view.TileMapView'
local HeroView = require 'pud.view.HeroView'

-- controllers
local HeroPlayerController = require 'pud.controller.HeroPlayerController'

function st:enter()
	self._level = Level()
	self._level:createEntities()
	self._level:generateSimpleGridMap()
	self:_createEntityControllers()
	self:_createMapView()
	self:_createEntityViews()
	self:_createCamera()
	if debug then
		self:_createDebugHUD()
		self._debug = true
	end
	CommandEvents:register(self, CommandEvent)
end

function st:_createEntityViews()
	local tileW, tileH = self._view:getTileSize()
	local heroX, heroY = Random(16), Random(2)
	local quad = love.graphics.newQuad(
		(heroX-1)*tileW, (heroY-1)*tileH,
		tileW, tileH,
		Image.char:getWidth(), Image.char:getHeight())

	if self._heroView then self._heroView:destroy() end
	self._heroView = HeroView(self._level:getHero(), tileW, tileH)
	self._heroView:set(Image.char, quad)
end

function st:CommandEvent(e)
	local command = e:getCommand()
	if not command:is_a(MoveCommand) then return end
	if command:getTarget() ~= self._level:getHero() then return end
	self._view:setViewport(self._cam:getViewport())
end

function st:_createEntityControllers()
	self._heroController = HeroPlayerController(self._level:getHero())
end

function st:_createMapView(viewClass)
	if self._view then self._view:destroy() end
	self._view = TileMapView(self._level)
	self._view:registerEvents()
end

function st:_createCamera()
	local mapW, mapH = self._level:getMapSize()
	local tileW, tileH = self._view:getTileSize()
	local mapTileW, mapTileH = mapW * tileW, mapH * tileH
	local startX = math_floor(mapW/2+0.5) * tileW - math_floor(tileW/2)
	local startY = math_floor(mapH/2+0.5) * tileH - math_floor(tileH/2)

	if not self._cam then
		self._cam = GameCam(vector(startX, startY), zoom)
	else
		self._cam:setHome(vector(startX, startY))
	end

	local min = vector(math_floor(tileW/2), math_floor(tileH/2))
	local max = vector(mapTileW - min.x, mapTileH - min.y)
	self._cam:setLimits(min, max)
	self._cam:home()
	self._cam:followTarget(self._level:getHero())
	self._view:setViewport(self._cam:getViewport())
end

function st:_createDebugHUD()
	self._debugHUD = DebugHUD()
end

function st:update(dt)
	if self._level then self._level:update(dt) end
	if self._view then self._view:update(dt) end
	if self._debug then self._debugHUD:update(dt) end
end


function st:draw()
	self._cam:predraw()
	self._view:draw()
	self._heroView:draw()
	self._cam:postdraw()
	if self._debug then self._debugHUD:draw() end
end

function st:leave()
	CommandEvents:unregisterAll(self)
	self._view:destroy()
	self._view = nil
	self._cam:destroy()
	self._cam = nil
	self._heroView:destroy()
	self._heroView = nil
	self._heroController:destroy()
	self._heroController = nil
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
			self._view:setAnimate(false)
			self._level:generateSimpleGridMap()
			self:_createMapView()
			self:_createEntityViews()
			self:_createCamera()
		end,
		f = function()
			self._view:setAnimate(false)
			self._level:generateFileMap()
			self:_createMapView()
			self:_createEntityViews()
			self:_createCamera()
		end,

		-- camera
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
		z = function()
			self._cam:unfollowTarget()
			self._view:setViewport(self._cam:getViewport())
		end,
		x = function()
			self._cam:followTarget(self._level:getHero())
			self._view:setViewport(self._cam:getViewport())
		end,
		f3 = function() if debug then self._debug = not self._debug end end,
		f7 = function()
			if self._debug then self._debugHUD:clearExtremes() end
		end,
		f9 = function() if self._debug then collectgarbage('collect') end end,
	}
end

return st
