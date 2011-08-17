local Class = require 'lib.hump.class'

local math_floor = math.floor
local math_max = math.max
local pairs, tostring, collectgarbage = pairs, tostring, collectgarbage
local getTime = love.timer.getTime
local newFramebuffer = love.graphics.newFramebuffer
local setColor = love.graphics.setColor
local gprint = love.graphics.print
local draw = love.graphics.draw
local setRenderTarget = love.graphics.setRenderTarget
local setFont = love.graphics.setFont
local rectangle = love.graphics.rectangle
local nearestPO2 = nearestPO2

local MARGIN = 8
local LABEL = 50
local CLEAR_DELAY = 4

-- target time between frames for 60Hz and 30Hz
local TARGET_FRAME_TIME_60 = 1/60
local TARGET_FRAME_TIME_30 = 1/30

local WARN1 = {1, 0.9, 0}
local WARN2 = {1, 0, 0}
local GOOD = {0, 1, 0}
local NORMAL = {0.9, 0.9, 0.9}
local BG = {0.1, 0.1, 0.9, 0.7}

local function _getColor(t)
	return {t[1], t[2], t[3], t[4]}
end

-- DebugHUD
--
local DebugHUD = Class{name='DebugHUD',
	function(self)
		self._font = GameFont.debug
		self._fontH = GameFont.debug:getHeight()
		local size = nearestPO2(math_max(WIDTH, HEIGHT))
		self._fb = newFramebuffer(size, size)
		self._info = {}
		self._start = getTime() + 0.2

		self:_set('mem', {
			gridX = 1, gridY = 2,
			tick = 0.05,
			warn1 = 15000000,
			warn2 = 20000000,
			good = 10000000,
			collect = function(dt)
				return math_floor(collectgarbage('count') * 1024)
			end,
		})
		self:_set('dt',  {
			gridX = 1, gridY = 3,
			tick = 0.1,
			warn1 = TARGET_FRAME_TIME_60,
			warn2 = TARGET_FRAME_TIME_30,
			good = TARGET_FRAME_TIME_60/4,
			collect = function(dt) return dt end,
		})
		self:_set('bal', {
			gridX = 1, gridY = 4,
			tick = 0.1,
			warn1 = 0,
			warn2 = -TARGET_FRAME_TIME_60,
			good = TARGET_FRAME_TIME_60 - TARGET_FRAME_TIME_60/4,
			reverse = true,
			collect = function(dt) return TARGET_FRAME_TIME_60 - dt end,
		})

		local infoSize = 1
		for k in pairs(self._info) do infoSize = infoSize + 1 end
		local bgWidth = WIDTH - MARGIN*2
		local bgHeight = MARGIN*2 + self._fontH * infoSize
		self._bg = {x=MARGIN, y=MARGIN, w=bgWidth, h=bgHeight}

		local x, y = self:_getPos(1, 1)
		self._topRow = {{name='current', x=x, y=y}}
		x, y = self:_getPos(2, 1)
		self._topRow[#self._topRow+1] = {name='warning', x=x, y=y}
		x, y = self:_getPos(3, 1)
		self._topRow[#self._topRow+1] = {name='best', x=x, y=y}
		x, y = self:_getPos(4, 1)
		self._topRow[#self._topRow+1] = {name='worst', x=x, y=y}

		self:_drawFB()
	end
}

-- destructor
function DebugHUD:destroy()
	self._font = nil
	self._fontH = nil
	self._fb = nil
	for k in pairs(self._info) do
		for j in pairs(self._info[k]) do self._info[k][j] = nil end
		self._info[k] = nil
	end
end

-- get the screen position from a grid position
function DebugHUD:_getPos(gridX, gridY)
	local quarter = math_floor((WIDTH-(MARGIN*4 + LABEL))/4)
	local x = MARGIN*2 + LABEL + (gridX-1) * quarter
	local y = MARGIN*2 + (gridY-1) * self._fontH
	return x, y
end

function DebugHUD:_set(key, attribs)
	self._info[key] = self._info[key] or {}
	for k,v in pairs(attribs) do self._info[key][k] = v end

	local x, y = self._info[key].gridX, self._info[key].gridY
	x, y = self:_getPos(x, y)
	self._info[key].x, self._info[key].y = x, y

	x, y = self:_getPos(2, self._info[key].gridY)
	self._info[key].warnX, self._info[key].warnY = x, y

	x, y = self:_getPos(3, self._info[key].gridY)
	self._info[key].bestX, self._info[key].bestY = x, y

	x, y = self:_getPos(4, self._info[key].gridY)
	self._info[key].worstX, self._info[key].worstY = x, y
end

function DebugHUD:clearExtremes()
	for k in pairs(self._info) do
		self._info[k].best = nil
		self._info[k].worst = nil
	end
end

local function _compare(gt, a, b, reverse)
	if reverse then gt = not gt end
	if gt then return a > b end
	return a < b
end

local function _getCompareColor(info, val)
	if _compare(false, val, info.good, info.reverse) then
		return GOOD
	elseif _compare(true, val, info.warn2, info.reverse) then
		return WARN2
	elseif _compare(true, val, info.warn1, info.reverse) then
		return WARN1
	end
	return NORMAL
end

local _accum = {}
function DebugHUD:_updateInfo(key, dt)
	local time = getTime()
	if self._start > time then return end

	_accum[key] = _accum[key] and _accum[key] + dt or dt

	local info = self._info[key]
	local data = info.collect(dt)

	if info.warnTime and info.warnTime < time then
		info.warning = nil
	end

	if not info.best
		or _compare(false, data, info.best, info.reverse)
	then
		info.best = data
		info.bestColor = _getCompareColor(info, info.best)
	end

	if not info.worst
		or _compare(true, data, info.worst, info.reverse)
	then
		info.worst = data
		info.worstColor = _getCompareColor(info, info.worst)
	end

	if _accum[key] > info.tick then
		_accum[key] = 0
		local warn = false

		info.cur = data
		info.color = _getCompareColor(info, info.cur)

		if _compare(true, data, info.warn2, info.reverse) then
			warn = true
			info.warnColor = WARN2
		elseif _compare(true, data, info.warn1, info.reverse) then
			warn = true
			info.warnColor = WARN1
		end

		if warn then
			info.warning = data
			info.warnTime = time + CLEAR_DELAY
		end
	end

end

local _lastTime = getTime()
function DebugHUD:update(dt)
	local realDT = getTime() - _lastTime
	for k in pairs(self._info) do self:_updateInfo(k, realDT) end
	self:_drawFB()
	_lastTime = getTime()
end

function DebugHUD:_drawFB()
	setRenderTarget(self._fb)

	setFont(self._font)

	setColor(BG)
	rectangle('fill',
		self._bg.x, self._bg.y, self._bg.w, self._bg.h)

	setColor(NORMAL)
	for i=1,#self._topRow do
		gprint(self._topRow[i].name,
			self._topRow[i].x, self._topRow[i].y)
	end

	for k in pairs(self._info) do
		local info = self._info[k]

		if info.cur then
			setColor(NORMAL)
			gprint(k..': ', MARGIN*2, info.y)
			setColor(info.color)
			gprint(tostring(info.cur), info.x, info.y)
		end

		if info.warning then
			setColor(info.warnColor)
			gprint(tostring(info.warning), info.warnX, info.warnY)
		end

		if info.best then
			setColor(info.bestColor)
			gprint(tostring(info.best), info.bestX, info.bestY)
		end

		if info.worst then
			setColor(info.worstColor)
			gprint(tostring(info.worst), info.worstX, info.worstY)
		end
	end

	setRenderTarget()
end

function DebugHUD:draw()
	setColor(1, 1, 1)
	draw(self._fb)
end


-- the class
return DebugHUD
