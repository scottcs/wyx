
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local DebugHUD = debug and getClass 'pud.debug.DebugHUD'
local MessageHUD = getClass 'pud.view.MessageHUD'

local math_floor, math_max, math_min = math.floor, math.max, math.min
local collectgarbage = collectgarbage
local getMicroTime = love.timer.getMicroTime

-- systems
local RenderSystemClass = getClass 'pud.system.RenderSystem'
local TimeSystemClass = getClass 'pud.system.TimeSystem'
local CollisionSystemClass = getClass 'pud.system.CollisionSystem'

-- level
local Level = getClass 'pud.map.Level'

-- Camera
local GameCam = getClass 'pud.view.GameCam'
local vector = require 'lib.hump.vector'

-- events
local CommandEvent = getClass 'pud.event.CommandEvent'
local ZoneTriggerEvent = getClass 'pud.event.ZoneTriggerEvent'
local MoveCommand = getClass 'pud.command.MoveCommand'

-- views
local TileMapView = getClass 'pud.view.TileMapView'

-- memory and framerate management constants
local TARGET_FRAME_TIME_60 = 1/60
local TARGET_FRAME_TIME_30 = 1/30
local IDLE_TIME = TARGET_FRAME_TIME_60 * 0.99
local COLLECT_THRESHOLD = 10000000/1024 -- 10 megs
local _lastCollect

function st:enter()
	self._keyDelay, self._keyInterval = love.keyboard.getKeyRepeat()
	love.keyboard.setKeyRepeat(100, 200)

	-- create level
	self._level = Level()

	-- create systems
	RenderSystem = RenderSystemClass()
	TimeSystem = TimeSystemClass()
	CollisionSystem = CollisionSystemClass(self._level)

	self._level:createEntities()
	self._level:setPlayerControlled()
	self._level:generateSimpleGridMap()
	self:_createMapView()
	self:_createCamera()
	if debug then
		self:_createDebugHUD()
		self._debug = true
	end
	CommandEvents:register(self, CommandEvent)
	GameEvents:register(self, ZoneTriggerEvent)

	-- turn off garbage collector... we'll collect manually when we have spare
	-- time (in update())
	_lastCollect = collectgarbage('count')
	collectgarbage('stop')
end

function st:CommandEvent(e)
	local command = e:getCommand()
	if command:getTarget() ~= self._level:getPrimeEntity() then return end
end

function st:ZoneTriggerEvent(e)
	local message = e:isLeaving() and 'Leaving' or 'Entering'
	message = message..' Zone: '..tostring(e:getZone())
	self:_displayMessage(message)
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
	self._cam:followTarget(self._level:getPrimeEntity())
	self._view:setViewport(self._cam:getViewport())
end

function st:_createDebugHUD()
	self._debugHUD = DebugHUD()
end

function st:_displayMessage(message, time)
	if self._messageHUD then
		cron.cancel(self._messageID)
		self._messageHUD:destroy()
	end

	time = time or 2
	self._messageHUD = MessageHUD(message, time)
	self._messageID = cron.after(time+1, function(self)
		self._messageHUD:destroy()
		self._messageHUD = nil
	end, self)
end

-- idle function, called when there are spare cycles
function st:idle(start)
	local cycles = 0
	local time_left = getMicroTime() - start
	while time_left < IDLE_TIME do
		cycles = cycles + 1
		collectgarbage('step', 0)
		collectgarbage('stop')
		time_left = getMicroTime() - start
	end
	return cycles
end

function st:update(dt)
	local start = getMicroTime() - dt
	if self._level then self._level:update(dt) end

	if self._level:needViewUpdate() then
		self._view:setViewport(self._cam:getViewport())
		self._level:postViewUpdate()
	end

	if self._view then self._view:update(dt) end
	if self._messageHUD then self._messageHUD:update(dt) end
	if self._debug then self._debugHUD:update(dt) end

	local cycles = self:idle(start)

	-- if we're on a slow machine that doesn't get much idle time, then
	-- collect garbage every COLLECT_THRESHOLD megs
	if cycles == 0 then
		local count = collectgarbage('count')
		if _lastCollect - count > COLLECT_THRESHOLD then
			collectgarbage('collect')
			collectgarbage('stop')
			_lastCollect = collectgarbage('count')
		end
	end
end

function st:draw()
	self._cam:predraw()
	self._view:draw()
	RenderSystem:draw()
	self._cam:postdraw()
	if self._messageHUD then self._messageHUD:draw() end
	if self._debug then self._debugHUD:draw() end
end

function st:leave()
	collectgarbage('restart')
	RenderSystem:destroy()
	TimeSystem:destroy()
	CollisionSystem:destroy()
	CommandEvents:unregisterAll(self)
	GameEvents:unregisterAll(self)
	love.keyboard.setKeyRepeat(self._keyDelay, self._keyInterval)
	self._keyDelay = nil
	self._keyInterval = nil
	self._view:destroy()
	self._view = nil
	self._cam:destroy()
	self._cam = nil
	self._messageHUD = nil
	if self._debugHUD then self._debugHUD:destroy() end
	self._debug = nil
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
			self:_createCamera()
		end,
		f = function()
			self._view:setAnimate(false)
			self._level:generateFileMap()
			self:_createMapView()
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
			self._cam:followTarget(self._level:getPrimeEntity())
			self._view:setViewport(self._cam:getViewport())
		end,
		f3 = function() if debug then self._debug = not self._debug end end,
		f7 = function()
			if self._debug then self._debugHUD:clearExtremes() end
		end,
		f9 = function() if self._debug then collectgarbage('collect') end end,
		backspace = function()
			local name = self._level:getMapName()
			local author = self._level:getMapAuthor()
			self:_displayMessage('Map: "'..name..'" by '..author)
		end,
	}
end

return st
