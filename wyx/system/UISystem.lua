local Class = require 'lib.hump.class'
local RenderSystem = getClass 'wyx.system.RenderSystem'
local MousePressedEvent = getClass 'wyx.event.MousePressedEvent'
local MouseReleasedEvent = getClass 'wyx.event.MouseReleasedEvent'
local KeyboardEvent = getClass 'wyx.event.KeyboardEvent'
local MouseIntersectEvent = getClass 'wyx.event.MouseIntersectEvent'
local MouseIntersectRequest = getClass 'wyx.event.MouseIntersectRequest'

local getMousePos = love.mouse.getPosition
local select, unpack, type = select, unpack, type

-- how many times per second should we tick?
local FRAME_UPDATE_TICK = 1/30

-- UISystem
-- Handles input and draws User Interface Frames
local UISystem = Class{name='UISystem',
	inherits=RenderSystem,
	function(self)
		RenderSystem.construct(self)
		self._defaultDepth = 30
		self._accum = 0
		InputEvents:register(self, {
			MousePressedEvent,
			MouseReleasedEvent,
			KeyboardEvent,
			MouseIntersectEvent,
		})
	end
}

-- destructor
function UISystem:destroy()
	InputEvents:unregisterAll(self)
	self._accum = nil
	RenderSystem.destroy(self)
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
			local ok = frame:handleMousePress(x, y, button, mods)
			if not handled and ok then handled = true end
		end
	end

	-- send a request to find the topmost entity
	if not handled then
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
			frame:handleMouseRelease(x, y, button, mods)
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
			steal = frame:handleKeyboard(key, unicode, unicodeValue, mods)
		end
	end
end

-- MouseIntersectEvent
function UISystem:MouseIntersectEvent(e)
	local obj = e:getObject()
	local args = e:getArgsTable()
	if args then
		local cb = args[1]
		if cb and self[cb] and type(self[cb]) == 'function' then
			if #args > 1 then
				self[cb](obj, select(2, unpack(args)))
			else
				self[cb](obj)
			end
		end
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
			if frame:containsPoint(x, y) then
				count = count + 1
				intersection = intersection or {}
				intersection[count] = frame
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
			for frame in self._registered[depth]:listeners() do frame:onTick(dt) end
		end

		self:castMouseRay(nil, nil, '_mouseRayHitOnHover')
	end
end

-- send a request to check for entities under mouse cursor
function UISystem:castMouseRay(x, y, callbackName, ...)
	if nil == x and nil == y then x, y = getMousePos() end
	GameEvents:notify(MouseIntersectRequest(x, y, callbackName, ...))
end

function UISystem:_mouseRayHitOnPress(obj, button, mods)
	print('press!', tostring(obj))
end

function UISystem:_mouseRayHitOnHover(obj)
	print('hover!', tostring(obj))
end


-- the class
return UISystem
