
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local DebugHUD = debug and getClass 'pud.debug.DebugHUD'
local MessageHUD = getClass 'pud.view.MessageHUD'

-- events
local ZoneTriggerEvent = getClass 'pud.event.ZoneTriggerEvent'
local DisplayPopupMessageEvent = getClass 'pud.event.DisplayPopupMessageEvent'
local ConsoleEvent = getClass 'pud.event.ConsoleEvent'
local GameEvents = GameEvents

function st:init()
	if debug then
		self:_createDebugHUD()
		self._debug = true
	end
end

function st:enter(prevState, level, view, cam)
	print('play')
	self._level = level
	self._view = view
	self._cam = cam

	GameEvents:register(self, {
		ZoneTriggerEvent,
		DisplayPopupMessageEvent,
		ConsoleEvent,
	})
end

function st:leave()
	self:_killMessageHUD()
	GameEvents:unregisterAll(self)
end

function st:destroy()
	print('play destroy')
	self:_killMessageHUD()
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

function st:_createDebugHUD()
	self._debugHUD = DebugHUD()
end

function st:_killMessageHUD()
	if self._messageHUD then
		if self._messageID then cron.cancel(self._messageID) end
		self._messageID = nil
		self._messageHUD:destroy()
		self._messageHUD = nil
	end
end

function st:_displayMessage(message, time)
	GameEvents:push(ConsoleEvent(message))

	self:_killMessageHUD()

	time = time or 2
	self._messageHUD = MessageHUD(message, time)
	self._messageID = cron.after(time+1, function(self)
		self._messageHUD:destroy()
		self._messageHUD = nil
	end, self)
end

function st:update(dt)
	TimeSystem:tick()

	if self._level:needViewUpdate() then
		self._view:setViewport(self._cam:getViewport())
		self._level:postViewUpdate()
	end

	if self._view then self._view:update(dt) end
	if self._messageHUD then self._messageHUD:update(dt) end
	if self._debug then self._debugHUD:update(dt) end
end

function st:draw()
	self._cam:predraw()
	self._view:draw()
	RenderSystem:draw()
	self._cam:postdraw()
	if self._messageHUD then self._messageHUD:draw() end
	if self._debug then self._debugHUD:draw() end
	if Console then Console:draw() end
end

function st:_postZoomIn(vp)
	self._view:setViewport(vp)
	self._view:setAnimate(true)
end

function st:keypressed(key, unicode)
	local tileW, tileH = self._view:getTileSize()
	local _,zoomAmt = self._cam:getZoom()

	if Console:isVisible() then
		switch(key) {
			['`'] = function() Console:toggle() end,
			escape = function() Console:hide() end,
			pageup = function() Console:pageup() end,
			pagedown = function() Console:pagedown() end,
			home = function() Console:top() end,
			['end'] = function() Console:bottom() end,
			f10 = function() Console:clear() end,
			f11 = function() EntityRegistry:dumpEntities() end,
		}
	else
		switch(key) {
			escape = function() GameState.switch(State.destroy) end,
			['1'] = function()
				self._view:setAnimate(false)
				self._level:generateSimpleGridMap()
				GameState.switch(State.construct, self._level)
			end,
			['2'] = function()
				self._view:setAnimate(false)
				self._level:generateFileMap()
				GameState.switch(State.construct, self._level)
			end,

			-- camera
			pageup = function()
				if not self._cam:isAnimating() then
					self._view:setAnimate(false)
					self._view:setViewport(self._cam:getViewport(1))
					self._cam:zoomOut(self._view.setAnimate, self._view, true)
				end
			end,
			pagedown = function()
				if not self._cam:isAnimating() then
					local vp = self._cam:getViewport(-1)
					self._cam:zoomIn(self._postZoomIn, self, vp)
				end
			end,
			home = function()
				if not self._cam:isAnimating() then
					self._view:setViewport(self._cam:getViewport())
					self._cam:home()
				end
			end,
			f4 = function()
				self._cam:unfollowTarget()
				self._view:setViewport(self._cam:getViewport())
			end,
			f5 = function()
				self._cam:followTarget(self._level:getPrimeEntity())
				self._view:setViewport(self._cam:getViewport())
			end,
			f3 = function() if debug then self._debug = not self._debug end end,
			f7 = function()
				if self._debug then self._debugHUD:clearExtremes() end
			end,
			f9 = function() if self._debug then collectgarbage('collect') end end,
			f11 = function() EntityRegistry:dumpEntities() end,
			backspace = function()
				local name = self._level:getMapName()
				local author = self._level:getMapAuthor()
				self:_displayMessage('Map: "'..name..'" by '..author)
			end,
			['`'] = function() Console:show() end,
		}
	end
end


return st
