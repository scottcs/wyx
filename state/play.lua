
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.play' end}
setmetatable(st, mt)

local DebugHUD = debug and getClass 'wyx.ui.DebugHUD'
local Text = getClass 'wyx.ui.Text'
local Style = getClass 'wyx.ui.Style'
local command = require 'wyx.ui.command'

-- events
local ZoneTriggerEvent = getClass 'wyx.event.ZoneTriggerEvent'
local DisplayPopupMessageEvent = getClass 'wyx.event.DisplayPopupMessageEvent'
local MouseIntersectRequest = getClass 'wyx.event.MouseIntersectRequest'
local MouseIntersectResponse = getClass 'wyx.event.MouseIntersectResponse'
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local GameEvents = GameEvents
local InputEvents = InputEvents

local colors = colors
local floor = math.floor

-- set up popup message style
local popup
do
	local font = GameFont.big
	local fontH = font:getHeight()
	local w = floor(WIDTH * 0.9)
	local h = floor(fontH * 1.8)

	popup = {
		x = floor(WIDTH/2 - w/2),
		y = HEIGHT - (h + 100),
		w = w,
		h = h,
		normalStyle = Style({
			bgcolor = colors.BLACK_A70,
			font = GameFont.big,
			fontcolor = colors.WHITE,
		})
	}
end

function st:init()
	if debug then
		self._debugHUD = DebugHUD()
		self._debug = true
	end
end

function st:enter(prevState, world, view, cam)
	self._world = self._world or world
	local place = self._world:getCurrentPlace()
	self._level = self._level or place:getCurrentLevel()
	self._view = self._view or view
	self._cam = self._cam or cam

	GameEvents:register(self, {
		ZoneTriggerEvent,
		DisplayPopupMessageEvent,
		ConsoleEvent,
	})

	InputEvents:register(self, {
		MouseIntersectRequest,
		InputCommandEvent,
	})

	self:_doPause(false, false)
end

function st:leave()
	self:_doPause(false, true)
	self:_killPopupMessage()
	GameEvents:unregisterAll(self)
	InputEvents:unregisterAll(self)
end

function st:destroy()
	self:_killPopupMessage()
	if self._popupMessage then
		self._popupMessage:destroy()
		self._popupMessage = nil
	end

	PAUSED = nil
	self._level = nil
	self._world = nil
	self._view = nil
	self._cam = nil
	if self._debugHUD then self._debugHUD:destroy() end
	self._debug = nil
end

function st:ZoneTriggerEvent(e)
	if self._level:getPrimeEntity() == e:getEntity() then
		local which = e:isLeaving() and '-' or '+'
		local zone = e:getZone()
		zone = zone and tostring(zone) or 'unknown zone'
		GameEvents:push(ConsoleEvent('Zone %s: %s', which, zone))
	end
end

function st:DisplayPopupMessageEvent(e)
	local message = e:getMessage()
	if message then self:_displayMessage(message) end
end

function st:MouseIntersectRequest(e)
	local mouseX, mouseY = e:getPosition()

	-- translate mouse x and y to world x and y
	local worldX, worldY = self._cam:toWorldCoords(mouseX, mouseY)

	-- translate world x and y to map x and y
	local x, y = self._view:toMapCoords(worldX, worldY)

	local entityIDs = self._level:getEntitiesAtLocation(x, y, true)
	InputEvents:notify(MouseIntersectResponse(entityIDs, e:getArgs()))
end

function st:InputCommandEvent(e)
	local cmd = e:getCommand()
	if PAUSED and command.pause(cmd) then return end
	--local args = e:getCommandArgs()

	switch(cmd) {
		DUMP_ENTITIES = function() EntityRegistry:dumpEntities() end,
		PAUSE = function() self:_doPause(true) end,
		-- camera
		CAMERA_ZOOMOUT = function()
			if not self._cam:isAnimating() then
				self._view:setAnimate(false)
				self._view:setViewport(self._cam:getViewport(1))
				self._cam:zoomOut(self._view.setAnimate, self._view, true)
				local zoom = self._cam:getZoom()
				self:_doPause(false, zoom ~= 1)
			end
		end,
		CAMERA_ZOOMIN = function()
			if not self._cam:isAnimating() then
				local vp = self._cam:getViewport(-1)
				self._cam:zoomIn(self._postZoomIn, self, vp)
				local zoom = self._cam:getZoom()
				self:_doPause(false, zoom ~= 1)
			end
		end,
		CAMERA_UNFOLLOW = function()
			self._cam:unfollowTarget()
			self._view:setViewport(self._cam:getViewport())
		end,
		CAMERA_FOLLOW = function()
			self._cam:followTarget(self._level:getPrimeEntity())
			self._view:setViewport(self._cam:getViewport())
		end,

		-- menu
		MENU_PLAY = function()
			RunState.switch(State.playmenu, self._world, self._view)
		end,
		MENU_MAIN = function()
			RunState.switch(State.destroy)
		end,

		-- debug
		NEW_LEVEL = function()
			RunState.switch(State.destroy, 'initialize', 'construct')
		end,
		DISPLAY_MAPNAME = function()
			local name = self._level:getMapName()
			local author = self._level:getMapAuthor()
			self:_displayMessage('Map: "'..name..'" by '..author)
		end,
	}
end

function st:ConsoleEvent(e)
	local message = e:getMessage()
	if message then
		local turns = self._level:getTurns()
		if turns then
			message = '<%07d> '..message
		end
		Console:print(message, turns)
	end
end

function st:_killPopupMessage()
	if self._popupMessage then
		if self._messageID then cron.cancel(self._messageID) end
		self._messageID = nil
		self._popupMessage:hide()
	end
end

function st:_displayMessage(message, time)
	GameEvents:push(ConsoleEvent(message))

	self:_killPopupMessage()

	time = time or 2
	if not self._popupMessage then
		self._popupMessage = Text(popup.x, popup.y, popup.w, popup.h)
		self._popupMessage:setNormalStyle(popup.normalStyle)
		self._popupMessage:setJustifyCenter()
		self._popupMessage:setAlignCenter()
		self._popupMessage:setAlpha(0)
		self._popupMessage:hide()
	end

	self._popupMessage:setText(message)
	self._popupMessage:fadeIn()

	self._messageID = cron.after(time+1, function(self)
		self._popupMessage:fadeOut()
	end, self)
end

function st:_doPause(display, pause)
	if nil == pause then pause = not PAUSED end
	PAUSED = pause
	if pause then
		GameEvents:flush()
		CommandEvents:flush()
		InputEvents:flush()
		if display then self:_displayMessage('Paused') end
	else
		GameEvents:clear()
		CommandEvents:clear()
		InputEvents:clear()
		if display then self:_displayMessage('Unpaused') end
	end
end

function st:update(dt)
	if not PAUSED then
		TimeSystem:tick()

		if self._level:needViewUpdate() then
			self._view:setViewport(self._cam:getViewport())
			self._level:postViewUpdate()
		end

		if self._view then self._view:update(dt) end
		if self._debugHUD then self._debugHUD:update(dt) end
	end
end

function st:draw()
	self._cam:predraw()
	self._view:draw()
	RenderSystem:draw()
	self._cam:postdraw()
end

function st:_postZoomIn(vp)
	self._view:setViewport(vp)
	self._view:setAnimate(true)
end


return st
