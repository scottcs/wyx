
         --[[--
       DEBUG STATE
          ----
    For fixing stuff.
         --]]--

local st = GameState.new()

local math_floor = math.floor

-- target time between frames for 60Hz and 30Hz
local TARGET_FRAME_TIME_60 = 0.016666666667
local TARGET_FRAME_TIME_30 = 0.033333333333

-- point at which target frame time minus actual frame time is too low
local UNACCEPTABLE_BALANCE = TARGET_FRAME_TIME_60 * 0.2

-- warning and extreme values for memory usage
local MEMORY_WARN = 20000
local MEMORY_EXTREME = 25000

function st:enter(prev)
	self._hudinfo = {
		h = GameFont.debug:getHeight(),
		x = 8,
		y = 8,
		x2 = 248,
	}
	self._hudinfo.y2 = self._hudinfo.y + self._hudinfo.h
	self._hudinfo.y3 = self._hudinfo.y + self._hudinfo.h*2

	self:_createHUD()
	self:_drawHUDfb()
end

function st:_createHUD()
	if not self._HUDfb then
		local w, h = nearestPO2(WIDTH), nearestPO2(HEIGHT)
		self._HUDfb = love.graphics.newFramebuffer(w, h)
	end
end

local _accum = 0
function st:update(dt)
	self._memory = math_floor(collectgarbage('count'))
	local balance = TARGET_FRAME_TIME_60 - dt
	local time = love.timer.getMicroTime()

	if self._memory then
		if self._memory > MEMORY_EXTREME then
			self._memory_clr = {1, 0, 0}
		elseif self._memory > MEMORY_WARN then
			self._memory_clr = {1, .9, 0}
		else
			self._memory_clr = {1, 1, 1}
		end
	end

	if self._clearTime and time > self._clearTime then
		self._lastBadDT = nil
		self._lastBadBalance = nil
		self._clearTime = nil
	end

	local resetTime = false
	if dt > TARGET_FRAME_TIME_60
		and (not self._lastBadDT or dt > self._lastBadDT)
	then
		self._lastBadDT = dt

		if self._lastBadDT > TARGET_FRAME_TIME_30 then
			self._lastBadDT_clr = {1, 0, 0}
		else
			self._lastBadDT_clr = {1, .9, 0}
		end

		resetTime = true
	end

	if balance < UNACCEPTABLE_BALANCE
		and (not self._lastBadBalance
			or balance < self._lastBadBalance)
	then
		self._lastBadBalance = balance

		if self._lastBadBalance < 0 then
			self._lastBadBalance_clr = {1, 0, 0}
		else
			self._lastBadBalance_clr = {1, .9, 0}
		end
		resetTime = true
	end

	if resetTime then self._clearTime = time + 3 end

	_accum = _accum + dt
	if _accum > 0.1 then
		_accum = 0
		self._lastDT = dt
		self._lastBalance = balance

		if self._lastDT > TARGET_FRAME_TIME_30 then
			self._lastDT_clr = {1, 0, 0}
		elseif self._lastDT > TARGET_FRAME_TIME_60 then
			self._lastDT_clr = {1, .9, 0}
		else
			self._lastDT_clr = {1, 1, 1}
		end

		if self._lastBalance < 0 then
			self._lastBalance_clr = {1, 0, 0}
		elseif self._lastBalance < UNACCEPTABLE_BALANCE then
			self._lastBalance_clr = {1, .9, 0}
		else
			self._lastBalance_clr = {1, 1, 1}
		end
	end

	self:_drawHUDfb()
end

function st:_drawHUD()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self._HUDfb)
end

function st:_drawHUDfb()
	love.graphics.setRenderTarget(self._HUDfb)

	local inf = self._hudinfo
	love.graphics.setFont(GameFont.debug)

	if self._memory then
		love.graphics.setColor(self._memory_clr)
		love.graphics.print('mem: '..tostring(self._memory),
			inf.x, inf.y)
	end

	if self._lastDT then
		love.graphics.setColor(self._lastDT_clr)
		love.graphics.print('dt: '..tostring(self._lastDT),
			inf.x, inf.y2)
	end

	if self._lastBadDT then
		love.graphics.setColor(self._lastBadDT_clr)
		love.graphics.print(tostring(self._lastBadDT),
			inf.x2, inf.y2)
	end

	if self._lastBalance then
		love.graphics.setColor(self._lastBalance_clr)
		love.graphics.print('bal: '..tostring(self._lastBalance),
			inf.x, inf.y3)
	end

	if self._lastBadBalance then
		love.graphics.setColor(self._lastBadBalance_clr)
		love.graphics.print(tostring(self._lastBadBalance),
			inf.x2, inf.y3)
	end

	love.graphics.setRenderTarget()
end

function st:draw()
	self:_drawHUD()
end

function st:leave()
	for k in pairs(self._hudinfo) do self._hudinfo[k] = nil end
	self._hudinfo = nil
end

function st:keypressed(key, unicode)
	switch(key) {
		escape = function() love.event.push('q') end,
	}
end

return st
