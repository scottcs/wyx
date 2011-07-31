
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local math_floor, math_max, math_min = math.floor, math.max, math.min
local random = Random

-- events
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'
local CommandEvent = require 'pud.event.CommandEvent'
local MoveCommand = require 'pud.command.MoveCommand'

-- time manager
local TimeManager = require 'pud.time.TimeManager'
local TICK = 0.01

-- Camera
local GameCam = require 'pud.view.GameCam'
local vector = require 'lib.hump.vector'

-- map director
local MapDirector = require 'pud.map.MapDirector'

-- views
local TileMapView = require 'pud.view.TileMapView'
local HeroView = require 'pud.view.HeroView'

-- entities
local HeroEntity = require 'pud.entity.HeroEntity'

-- controllers
local HeroPlayerController = require 'pud.controller.HeroPlayerController'

-- target time between frames for 60Hz and 30Hz
local TARGET_FRAME_TIME_60 = 0.016666666667
local TARGET_FRAME_TIME_30 = 0.033333333333

-- point at which target frame time minus actual frame time is too low
local UNACCEPTABLE_BALANCE = TARGET_FRAME_TIME_60 * 0.2

-- warning and extreme values for memory usage
local MEMORY_WARN = 20000
local MEMORY_EXTREME = 25000


function st:enter()
	self._keyDelay, self._keyInterval = love.keyboard.getKeyRepeat()
	love.keyboard.setKeyRepeat(200, 25)

	if debug then
		self._debug_hudinfo = {
			h = GameFont.debug:getHeight(),
			x = 8,
			y = 8,
			x2 = 248,
		}
		self._debug_hudinfo.y2 = self._debug_hudinfo.y + self._debug_hudinfo.h
		self._debug_hudinfo.y3 = self._debug_hudinfo.y + self._debug_hudinfo.h*2
	end

	self._timeManager = TimeManager()
	self._doTick = false

	--self:_generateMapFromFile()
	self:_generateMapRandomly()
	self:_createMapView()
	self:_createEntities()
	self:_createEntityViews()
	self:_createEntityControllers()
	self:_createCamera()
	self:_createHUD()
	self:_drawHUDfb()
end

function st:_createEntityViews()
	local tileW, tileH = self._view:getTileSize()
	local heroX, heroY = Random(16), Random(2)
	local quad = love.graphics.newQuad(
		(heroX-1)*tileW, (heroY-1)*tileH,
		tileW, tileH,
		Image.char:getWidth(), Image.char:getHeight())

	if self._heroView then self._heroView:destroy() end
	self._heroView = HeroView(self._hero, tileW, tileH)
	self._heroView:set(Image.char, quad)
end

function st:_createEntities()
	local mapW, mapH = self._map:getSize()
	local tileW, tileH = self._view:getTileSize()
	local startX = math_floor(mapW/2+0.5)
	local startY = math_floor(mapH/2+0.5)

	self._hero = HeroEntity()
	self._hero:setPosition(vector(startX, startY))
	self._hero:setSize(vector(tileW, tileH))

	self._timeManager:register(self._hero, 0)

	-- listen for hero commands
	CommandEvents:register(self, CommandEvent)
end

function st:CommandEvent(e)
	local command = e:getCommand()
	if command:getTarget() ~= self._hero then return end
	self._doTick = true
	if command:is_a(MoveCommand) then
		self._view:setViewport(self._cam:getViewport())
	end
end

function st:_createEntityControllers()
	self._heroController = HeroPlayerController(self._hero)
end

function st:_generateMapFromFile()
	local FileMapBuilder = require 'pud.map.FileMapBuilder'
	local mapfiles = {'test'}
	local mapfile = mapfiles[random(1,#mapfiles)]
	local builder = FileMapBuilder(mapfile)

	self:_generateMap(builder)
end

function st:_generateMapRandomly()
	local SimpleGridMapBuilder = require 'pud.map.SimpleGridMapBuilder'
	local builder = SimpleGridMapBuilder(80,80, 10,10, 8,16)

	self:_generateMap(builder)
end

function st:_generateMap(builder)
	if self._map then self._map:destroy() end
	self._map = MapDirector:generateStandard(builder)
	builder:destroy()
	GameEvents:push(MapUpdateFinishedEvent(self._map))
end

function st:_createMapView(viewClass)
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

	if not self._cam then
		self._cam = GameCam(vector(startX, startY), zoom)
	else
		self._cam:setHome(vector(startX, startY))
	end

	local min = vector(math_floor(tileW/2), math_floor(tileH/2))
	local max = vector(mapTileW - min.x, mapTileH - min.y)
	self._cam:setLimits(min, max)
	self._cam:home()
	self._cam:followTarget(self._hero)
	self._view:setViewport(self._cam:getViewport())
end

function st:_createHUD()
	if not self._HUDfb then
		local w, h = nearestPO2(WIDTH), nearestPO2(HEIGHT)
		self._HUDfb = love.graphics.newFramebuffer(w, h)
	end
end

local _accum = 0
local _debug_accum = 0
function st:update(dt)
	if self._view then self._view:update(dt) end
	self:_drawHUDfb()

	if self._doTick then
		_accum = _accum + dt
		if _accum > TICK then
			_accum = _accum - TICK
			self._doTick = self._timeManager:tick() ~= self._hero
		end
	end

	if debug and self._debug then
		self._debug_memory = math_floor(collectgarbage('count'))
		local balance = TARGET_FRAME_TIME_60 - dt
		local time = love.timer.getMicroTime()

		if self._debug_memory then
			if self._debug_memory > MEMORY_EXTREME then
				self._debug_memory_clr = {1, 0, 0}
			elseif self._debug_memory > MEMORY_WARN then
				self._debug_memory_clr = {1, .9, 0}
			else
				self._debug_memory_clr = {1, 1, 1}
			end
		end

		if self._debug_clearTime and time > self._debug_clearTime then
			self._debug_lastBadDT = nil
			self._debug_lastBadBalance = nil
			self._debug_clearTime = nil
		end

		local resetTime = false
		if dt > TARGET_FRAME_TIME_60
			and (not self._debug_lastBadDT or dt > self._debug_lastBadDT)
		then
			self._debug_lastBadDT = dt

			if self._debug_lastBadDT > TARGET_FRAME_TIME_30 then
				self._debug_lastBadDT_clr = {1, 0, 0}
			else
				self._debug_lastBadDT_clr = {1, .9, 0}
			end

			resetTime = true
		end

		if balance < UNACCEPTABLE_BALANCE
			and (not self._debug_lastBadBalance
				or balance < self._debug_lastBadBalance)
		then
			self._debug_lastBadBalance = balance

			if self._debug_lastBadBalance < 0 then
				self._debug_lastBadBalance_clr = {1, 0, 0}
			else
				self._debug_lastBadBalance_clr = {1, .9, 0}
			end
			resetTime = true
		end

		if resetTime then self._debug_clearTime = time + 3 end

		_debug_accum = _debug_accum + dt
		if _debug_accum > 0.1 then
			_debug_accum = 0
			self._debug_lastDT = dt
			self._debug_lastBalance = balance

			if self._debug_lastDT > TARGET_FRAME_TIME_30 then
				self._debug_lastDT_clr = {1, 0, 0}
			elseif self._debug_lastDT > TARGET_FRAME_TIME_60 then
				self._debug_lastDT_clr = {1, .9, 0}
			else
				self._debug_lastDT_clr = {1, 1, 1}
			end

			if self._debug_lastBalance < 0 then
				self._debug_lastBalance_clr = {1, 0, 0}
			elseif self._debug_lastBalance < UNACCEPTABLE_BALANCE then
				self._debug_lastBalance_clr = {1, .9, 0}
			else
				self._debug_lastBalance_clr = {1, 1, 1}
			end
		end
	end
end

function st:_drawHUD()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self._HUDfb)
end

function st:_drawHUDfb()
	love.graphics.setRenderTarget(self._HUDfb)


	if debug and self._debug then
		local inf = self._debug_hudinfo
		love.graphics.setFont(GameFont.debug)

		if self._debug_memory then
			love.graphics.setColor(self._debug_memory_clr)
			love.graphics.print('mem: '..tostring(self._debug_memory),
				inf.x, inf.y)
		end

		if self._debug_lastDT then
			love.graphics.setColor(self._debug_lastDT_clr)
			love.graphics.print('dt: '..tostring(self._debug_lastDT),
				inf.x, inf.y2)
		end

		if self._debug_lastBadDT then
			love.graphics.setColor(self._debug_lastBadDT_clr)
			love.graphics.print(tostring(self._debug_lastBadDT),
				inf.x2, inf.y2)
		end

		if self._debug_lastBalance then
			love.graphics.setColor(self._debug_lastBalance_clr)
			love.graphics.print('bal: '..tostring(self._debug_lastBalance),
				inf.x, inf.y3)
		end

		if self._debug_lastBadBalance then
			love.graphics.setColor(self._debug_lastBadBalance_clr)
			love.graphics.print(tostring(self._debug_lastBadBalance),
				inf.x2, inf.y3)
		end
	end

	love.graphics.setRenderTarget()
end

function st:draw()
	self._cam:predraw()
	self._view:draw()
	self._heroView:draw()
	self._cam:postdraw()
	self:_drawHUD()
end

function st:leave()
	CommandEvents:unregisterAll(self)
	love.keyboard.setKeyRepeat(self._keyDelay, self._keyInterval)
	self._view:destroy()
	self._view = nil
	self._cam:destroy()
	self._cam = nil
	self._heroView:destroy()
	self._heroView = nil
	self._heroController:destroy()
	self._heroController = nil
	self._hero:destroy()
	self._hero = nil
	self._timeManager:destroy()
	self._timeManager = nil
	self._doTick = nil
end

--[[
function st:_translateCam(x, y)
	if not self._cam:isAnimating() then
		self._view:setAnimate(false)
		local translate = vector(x, y)
		self._view:setViewport(self._cam:getViewport(translate))
		self._cam:translate(vector(x, y),
			self._view.setAnimate, self._view, true)
	end
end
]]--

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
			self:_generateMapRandomly()
			self:_createMapView()
			self:_createEntityViews()
			self:_createCamera()
		end,
		f = function()
			self._view:setAnimate(false)
			self:_generateMapFromFile()
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
			self._cam:followTarget(self._hero)
			self._view:setViewport(self._cam:getViewport())
		end,

		-- debug
		f3 = function() self._debug = not self._debug end,
	}
end

return st
