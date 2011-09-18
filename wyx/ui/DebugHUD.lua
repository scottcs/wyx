local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local ui = require 'ui.DebugHUD'
local depths = require 'wyx.system.renderDepths'
local command = require 'wyx.ui.command'

local math_floor = math.floor
local math_max = math.max
local pairs, tostring, collectgarbage = pairs, tostring, collectgarbage
local getTime = love.timer.getTime

local CLEAR_DELAY = 4

-- target time between frames for 60Hz and 30Hz
local TARGET_FRAME_TIME_60 = 1/60
local TARGET_FRAME_TIME_30 = 1/30

-- DebugHUD
--
local DebugHUD = Class{name='DebugHUD',
	inherits=Frame,
	function(self)
		Frame.construct(self, 0, 0, WIDTH, HEIGHT)
		self:setDepth(depths.debug)
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

		if ui and ui.keys then
			UISystem:registerKeys(ui.keys)
			self._uikeys = true
		end

		self:_makePanel()
		self:_drawFB()

		InputEvents:register(self, {
			InputCommandEvent,
		})
	end
}

-- destructor
function DebugHUD:destroy()
	InputEvents:unregisterAll(self)

	if self._uikeys then
		UISystem:unregisterKeys()
		self._uikeys = nil
	end

	for k in pairs(self._info) do
		for j in pairs(self._info[k]) do self._info[k][j] = nil end
		self._info[k] = nil
	end
	Frame.destroy(self)
end

local function _getInfoLine(info, key, which, frame)
	info = info[key]
	local ret = ''

	if not info then warning('Bad info key %q', key) end

	local ret = info[which] and tostring(info[which]) or nil
	if ret then
		local style = info[which..'Style'] or info.style
		if style then
			frame:setNormalStyle(style)
		else
			warning('Bad style for key %q: %q', key, which)
		end
	else
		ret = ''
	end

	return ret
end

function DebugHUD:_makePanel()
	local panel = Frame(ui.panel.x, ui.panel.y, ui.panel.w, ui.panel.h)
	panel:setNormalStyle(ui.panel.normalStyle)

	self:addChild(panel)

	local inner = Frame(ui.innerpanel.x, ui.innerpanel.y,
		ui.innerpanel.w, ui.innerpanel.h)
	panel:addChild(inner)

	-- headers
	local gridX, gridY = 1, 1
	local num = #ui.headers
	
	for i=1,num do
		local x, y = self:_getPos(gridX, gridY)
		local f = Text(x, y, ui.text.w, ui.text.h)
		f:setNormalStyle(ui.text.headerStyle)
		f:setText(ui.headers[i])
		inner:addChild(f)
		gridX = gridX + 1
	end

	-- info rows
	for key,info in pairs(self._info) do
		local f = Text(ui.sideheader.x, ui.sideheader.y + info.y,
			ui.sideheader.w, ui.sideheader.h)
		f:setNormalStyle(ui.text.headerStyle)
		f:setText(key)
		f:setJustifyRight()
		panel:addChild(f)
		
		f = Text(info.x, info.y, ui.text.w, ui.text.h)
		f:setNormalStyle(ui.text.normalStyle)
		f:watch(_getInfoLine, self._info, key, 'cur', f)
		inner:addChild(f)

		f = Text(info.warnX, info.warnY, ui.text.w, ui.text.h)
		f:setNormalStyle(ui.text.normalStyle)
		f:watch(_getInfoLine, self._info, key, 'warn', f)
		inner:addChild(f)

		f = Text(info.bestX, info.bestY, ui.text.w, ui.text.h)
		f:setNormalStyle(ui.text.normalStyle)
		f:watch(_getInfoLine, self._info, key, 'best', f)
		inner:addChild(f)

		f = Text(info.worstX, info.worstY, ui.text.w, ui.text.h)
		f:setNormalStyle(ui.text.normalStyle)
		f:watch(_getInfoLine, self._info, key, 'worst', f)
		inner:addChild(f)
	end
end

-- get the screen position from a grid position
function DebugHUD:_getPos(gridX, gridY)
	local x = (gridX - 1) * ui.text.w
	x = gridX > 1 and x + ui.innerpanel.hmargin or x
	local y = (gridY - 1) * ui.text.h
	y = gridY > 1 and y + ui.innerpanel.vmargin or y
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

local function _getCompareStyle(info, val)
	if _compare(false, val, info.good, info.reverse) then
		return ui.text.goodStyle
	elseif _compare(true, val, info.warn2, info.reverse) then
		return ui.text.warn2Style
	elseif _compare(true, val, info.warn1, info.reverse) then
		return ui.text.warn1Style
	end
	return ui.text.normalStyle
end

local _accum = {}
function DebugHUD:_updateInfo(key, dt)
	local time = getTime()
	if self._start > time then return end

	_accum[key] = _accum[key] and _accum[key] + dt or dt

	local info = self._info[key]
	local data = info.collect(dt)

	if info.warnTime and info.warnTime < time then
		info.warn = nil
	end

	if not info.best
		or _compare(false, data, info.best, info.reverse)
	then
		info.best = data
		info.bestStyle = _getCompareStyle(info, info.best)
	end

	if not info.worst
		or _compare(true, data, info.worst, info.reverse)
	then
		info.worst = data
		info.worstStyle = _getCompareStyle(info, info.worst)
	end

	if _accum[key] > info.tick then
		_accum[key] = 0
		local warn = false

		info.cur = data
		info.style = _getCompareStyle(info, info.cur)

		if _compare(true, data, info.warn2, info.reverse) then
			warn = true
			info.warnStyle = ui.text.warn2Style
		elseif _compare(true, data, info.warn1, info.reverse) then
			warn = true
			info.warnStyle = ui.text.warn1Style
		end

		if warn then
			info.warn = data
			info.warnTime = time + CLEAR_DELAY
		end
	end
end

local _lastTime = getTime()
function DebugHUD:update(dt)
	local realDT = getTime() - _lastTime
	for k in pairs(self._info) do self:_updateInfo(k, realDT) end
	_lastTime = getTime()
end

function DebugHUD:InputCommandEvent(e)
	local cmd = e:getCommand()
	if PAUSED and command.pause(cmd) then return end

	switch(cmd) {
		DEBUG_PANEL_TOGGLE = function()
			if self:isVisible() then self:hide() else self:show() end
		end,
		DEBUG_PANEL_RESET = function() self:clearExtremes() end,
		COLLECT_GARBAGE = function() collectgarbage('collect') end,
	}
end

-- the class
return DebugHUD
