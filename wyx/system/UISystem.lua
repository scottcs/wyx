local Class = require 'lib.hump.class'
local RenderSystem = getClass 'wyx.system.RenderSystem'
local MousePressedEvent = getClass 'wyx.event.MousePressedEvent'
local MouseReleasedEvent = getClass 'wyx.event.MouseReleasedEvent'
local KeyboardEvent = getClass 'wyx.event.KeyboardEvent'
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local MouseIntersectResponse = getClass 'wyx.event.MouseIntersectResponse'
local MouseIntersectRequest = getClass 'wyx.event.MouseIntersectRequest'
local depths = require 'wyx.system.renderDepths'

local getMousePos = love.mouse.getPosition
local select, unpack, type = select, unpack, type
local format = string.format

-- how many times per second should we tick?
local FRAME_UPDATE_TICK = 1/30

-- UISystem
-- Handles input and draws User Interface Frames
local UISystem = Class{name='UISystem',
	inherits=RenderSystem,
	function(self)
		RenderSystem.construct(self)
		self._defaultDepth = depths.uidefault
		self._accum = 0
		InputEvents:register(self, {
			MousePressedEvent,
			MouseReleasedEvent,
			KeyboardEvent,
			MouseIntersectResponse,
		})
	end
}

-- destructor
function UISystem:destroy()
	InputEvents:unregisterAll(self)

	self._accum = nil
	for k in pairs(self._keybindings) do
		for j in pairs(self._keybindings[k]) do
			self._keybindings[k][j] = nil
		end
		self._keybindings[k] = nil
	end
	self._keybindings = nil

	self:_clearMouseHoverCB()
	self:_clearMousePressCB()

	RenderSystem.destroy(self)
end

function UISystem:_clearMouseHoverCB()
	if self._mouseHoverCBArgs then
		for k in pairs(self._mouseHoverCBArgs) do
			self._mouseHoverCBArgs[k] = nil
		end
		self._mouseHoverCBArgs = nil
	end
	self._mouseHoverObj = nil
	self._mouseHoverCB = nil
end

function UISystem:_clearMousePressCB()
	if self._mousePressCBArgs then
		for k in pairs(self._mousePressCBArgs) do
			self._mousePressCBArgs[k] = nil
		end
		self._mousePressCBArgs = nil
	end
	self._mousePressObj = nil
	self._mousePressCB = nil
end

-- MousePressedEvent
function UISystem:MousePressedEvent(e)
	self._mouseDown = true

	local x, y = e:getPosition()
	local button = e:getButton()
	local mods = e:getModifiers()
	local numDepths = #self._depths
	local handled = false

	for i=numDepths, 1, -1 do
		local depth = self._depths[i]
		for frame in self._registered[depth]:listeners() do
			if frame and frame:isRegisteredWithUISystem() then
				local ok = frame:handleMousePress(x, y, button, mods)
				if not handled and ok then handled = true end
			end
		end
	end

	-- send a request to find the topmost entity
	if not handled and self._mousePressCB then
		self:castMouseRay(x, y, '_mouseRayHitOnPress', button, mods)
	end
end

-- MouseReleasedEvent
function UISystem:MouseReleasedEvent(e)
	self._mouseDown = false

	local x, y = e:getPosition()
	local button = e:getButton()
	local mods = e:getModifiers()
	local numDepths = #self._depths

	for i=numDepths, 1, -1 do
		local depth = self._depths[i]
		for frame in self._registered[depth]:listeners() do
			if frame and frame:isRegisteredWithUISystem() then
				frame:handleMouseRelease(x, y, button, mods)
			end
		end
	end
end

-- KeyboardEvent
function UISystem:KeyboardEvent(e)
	local mods = e:getModifiers()
	local key = e:getKey()
	local unicode, unicodeValue = e:getUnicode(), e:getUnicodeValue()
	local steal
	local numDepths = #self._depths

	for i=numDepths, 1, -1 do
		if steal then break end
		local depth = self._depths[i]

		for frame in self._registered[depth]:listeners() do
			if steal then break end
			if frame and frame:isRegisteredWithUISystem() then
				steal = frame:handleKeyboard(key, unicode, unicodeValue, mods)
			end
		end
	end

	if not steal then
		self:_sendInputCommand(key, unicode, unicodeValue, mods)
	end
end

-- MouseIntersectResponse
function UISystem:MouseIntersectResponse(e)
	local ids = e:getIDs()
	local args = e:getArgsTable()
	if args then
		local cb = args[1]
		if cb and self[cb] and type(self[cb]) == 'function' then
			if #args > 1 then
				self[cb](self, ids, select(2, unpack(args)))
			else
				self[cb](self, ids)
			end
		end
	end
end

-- send an InputCommand if a key has been registered
function UISystem:_sendInputCommand(key, unicode, unicodeValue, mods)
	if not self._keybindings then return end
	local keybindings = self._keybindings[#self._keybindings]

	local cmds
	unicodeValue = unicodeValue and format('%05d', unicodeValue) or -1

	if mods then
		for mod in pairs(mods) do
			mod = mod..'-'
			cmds = unicode and keybindings[mod..unicode] or nil
			if cmds then break end

			cmds = key and keybindings[mod..key] or nil
			if cmds then break end
		end
	end

	if not cmds then cmds = keybindings[unicodeValue] end
	if not cmds then cmds = unicode and keybindings[unicode] or nil end
	if not cmds then cmds = key and keybindings[key] or nil end

	if cmds then
		if type(cmds) == 'table' then
			local num = #cmds
			for i=1,num do
				InputEvents:notify(InputCommandEvent(cmds[i]))
			end
		else
			InputEvents:notify(InputCommandEvent(cmds))
		end
	end
end

-- register keybindings
-- if there are current keybindings, copy them and then set new ones
function UISystem:registerKeys(keytable)
	verify('table', keytable)
	self._keybindings = self._keybindings or {}
	local num = #self._keybindings
	local newBindings = {}

	if num > 0 then
		for k,v in pairs(self._keybindings[num]) do newBindings[k] = v end
	end

	for k,v in pairs(keytable) do newBindings[k] = v end

	self._keybindings[num+1] = newBindings
end

-- unregister last registered keybindings
function UISystem:unregisterKeys()
	if self._keybindings then
		local num = #self._keybindings
		for k in pairs(self._keybindings[num]) do
			self._keybindings[num][k] = nil
		end
		self._keybindings[num] = nil
	end
end

-- get all frames under the mouse cursor
function UISystem:getIntersection(x, y)
	if nil == x and nil == y then
		x, y = getMousePos()
	end

	local numDepths = #self._depths
	local intersection
	local count = 0

	for i=numDepths, 1, -1 do
		local depth = self._depths[i]
		for frame in self._registered[depth]:listeners() do
			if frame and frame:isRegisteredWithUISystem() then
				if frame:containsPoint(x, y) then
					count = count + 1
					intersection = intersection or {}
					intersection[count] = frame
				end
			end
		end
	end

	return intersection
end

-- update
function UISystem:update(dt)
	self._accum = self._accum + dt
	if self._accum > FRAME_UPDATE_TICK then
		self._accum = 0
		local numDepths = #self._depths

		for i=numDepths, 1, -1 do
			local depth = self._depths[i]
			for frame in self._registered[depth]:listeners() do
				if frame and frame:isRegisteredWithUISystem() then
					frame:onTick(dt)
				end
			end
		end

		if self._mouseHoverCB then
			self:castMouseRay(nil, nil, '_mouseRayHitOnHover')
		end
	end
end

-- send a request to check for entities under mouse cursor
function UISystem:castMouseRay(x, y, callbackName, ...)
	if nil == x and nil == y then x, y = getMousePos() end
	InputEvents:notify(MouseIntersectRequest(x, y, callbackName, ...))
end

-- set the callback to call when the mouse hovers over a non-frame entity
function UISystem:setNonFrameHoverCallback(obj, callback, ...)
	verify('table', obj)
	verify('function', callback)

	self:_clearMouseHoverCB()
	self._mouseHoverObj = obj
	self._mouseHoverCB = callback
	if select('#', ...) > 0 then self._mouseHoverCBArgs = {...} end
end

-- set the callback to call when the mouse presses over a non-frame entity
function UISystem:setNonFramePressCallback(obj, callback, ...)
	verify('table', obj)
	verify('function', callback)

	self:_clearMousePressCB()
	self._mousePressObj = obj
	self._mousePressCB = callback
	if select('#', ...) > 0 then self._mousePressCBArgs = {...} end
end

-- call mouse hover callback if it exists
function UISystem:_mouseRayHitOnHover(ids)
	local obj = self:_getLowestDepth(ids)

	if self._mouseHoverCBArgs then
		self._mouseHoverCB(
			self._mouseHoverObj, obj, unpack(self._mouseHoverCBArgs))
	else
		self._mouseHoverCB(self._mouseHoverObj, obj)
	end
end

-- call mouse press callback if it exists
function UISystem:_mouseRayHitOnPress(ids, button, mods)
	local obj = self:_getLowestDepth(ids)

	if self._mousePressCBArgs then
		self._mousePressCB(
			self._mousePressObj, obj, button, mods, unpack(self._mousePressCBArgs))
	else
		self._mousePressCB(self._mousePressObj, obj, button, mods)
	end
end

-- return the closest (lowest render depth) entity
function UISystem:_getLowestDepth(t)
	local lowestObj

	if t then
		local lowestDepth
		local num = #t

		for i=1,num do
			local obj = t[i]
			local depth = self:_getObjectDepth(obj)

			lowestDepth = lowestDepth or depth

			if depth <= lowestDepth then
				lowestDepth = depth
				lowestObj = obj
			end
		end
	end

	return lowestObj
end


-- the class
return UISystem
