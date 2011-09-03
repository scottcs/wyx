local Class = require 'lib.hump.class'
local Rect = getClass 'pud.kit.Rect'
local MousePressedEvent = getClass 'pud.event.MousePressedEvent'
local MouseReleasedEvent = getClass 'pud.event.MouseReleasedEvent'

local math_max = math.max
local getMousePosition = love.mouse.getPosition
local newFramebuffer = love.graphics.newFramebuffer
local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle
local draw = love.graphics.draw
local drawq = love.graphics.drawq
local pushRenderTarget = pushRenderTarget
local popRenderTarget = popRenderTarget
local nearestPO2 = nearestPO2
local colors = colors

local FRAME_UPDATE_TICK = 1/60

-- Frame
-- Basic UI Element
local Frame = Class{name='Frame',
	inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)

		self._children = {}

		self._accum = 0

		self:_drawFB()

		InputEvents:register(self, {MousePressedEvent, MouseReleasedEvent})
	end
}

-- destructor
function Frame:destroy()
	InputEvents:unregisterAll(self)

	for k,v in pairs(self._children) do
		self._children[k]:destroy()
		self._children[k] = nil
	end
	self._children = nil

	self._ffb = nil
	self._bfb = nil

	self._curStyle = nil

	if self._normalStyle then
		self._normalStyle:destroy()
		self._normalStyle = nil
	end

	if self._hoverStyle then
		self._hoverStyle:destroy()
		self._hoverStyle = nil
	end

	if self._activeStyle then
		self._activeStyle:destroy()
		self._activeStyle = nil
	end

	self._hovered = nil
	self._mouseDown = nil
	self._accum = nil

	Rect.destroy(self)
end

-- MousePressedEvent - check if the event occurred within this frame
function Frame:MousePressedEvent(e)
	self._mouseDown = true
	local x, y = e:getPosition()
	if self:containsPoint(x, y) then
		local button = e:getButton()
		local mods = e:getModifiers()
		self:onPress(button, mods)
	end
end

-- MouseReleasedEvent - check if the event occurred within this frame
function Frame:MouseReleasedEvent(e)
	self._mouseDown = false
	local x, y = e:getPosition()
	local button = e:getButton()
	local mods = e:getModifiers()
	self:onRelease(button, mods, self:containsPoint(x, y))
end

-- add a child
function Frame:addChild(frame)
	verifyClass(Frame, frame)

	local num = #self._children
	self._children[num+1] = frame
end

-- remove a child
function Frame:removeChild(frame)
	local num = #self._children
	local newChildren = {}
	local count = 0

	for i=1,num do
		local child = self._children[i]
		if child ~= frame then
			count = count + 1
			newChildren[count] = child
		end
		self._children[i] = nil
	end

	self._children = newChildren
end

-- get an appropriately sized PO2 framebuffer
function Frame:_getFramebuffer()
	local size = nearestPO2(math_max(self:getWidth(), self:getHeight()))
	local fb = newFramebuffer(size, size)
	return fb
end

-- what to do when update ticks
function Frame:_onTick(dt, x, y)
	if nil == x or nil == y then
		x, y = getMousePosition()
	end

	if self:containsPoint(x, y) then
		if not self._hovered then self:onHoverIn(x, y) end
		self._hovered = true
	else
		if self._hovered then self:onHoverOut(x, y) end
		self._hovered = false
	end

	local num = #self._children
	for i = 1,num do
		local child = self._children[i]
		child:update(dt, x, y)
	end
end

-- update - check for mouse hover
function Frame:update(dt, x, y)
	self._accum = self._accum + dt
	if self._accum > FRAME_UPDATE_TICK then
		self._accum = 0
		self:_onTick(dt, x, y)
	end
end

-- onHoverIn - called when the mouse starts hovering over the frame
function Frame:onHoverIn(x, y)
	self._curStyle = self._hoverStyle or self._normalStyle
	self:_drawFB()
end

-- onHoverOut - called when the mouse stops hovering over the frame
function Frame:onHoverOut(x, y)
	if not self._mouseDown then
		self._curStyle = self._normalStyle
	end
	self:_drawFB()
end

-- onPress - called when the mouse is pressed inside the frame
function Frame:onPress(button, mods)
	self._curStyle = self._activeStyle or self._hoverStyle or self._normalStyle
	self:_drawFB()
end

-- onRelease - called when the mouse is released inside the frame
function Frame:onRelease(button, mods, wasInside)
	if self._hovered then
		self._curStyle = self._hoverStyle or self._normalStyle
	else
		self._curStyle = self._normalStyle
	end
	self:_drawFB()
end

-- set the given style
function Frame:_setStyle(which, style)
	verifyClass('pud.ui.Style', style)
	self[which] = style
	self._curStyle = self._curStyle or style
	self:_drawFB()
end

-- set/get normal style
function Frame:setNormalStyle(style)
	self:_setStyle('_normalStyle', style)
end
function Frame:getNormalStyle() return self._normalStyle end

-- set/get hover style
function Frame:setHoverStyle(style)
	self:_setStyle('_hoverStyle', style)
end
function Frame:getHoverStyle() return self._hoverStyle end

-- set/get active style
function Frame:setActiveStyle(style)
	self:_setStyle('_activeStyle', style)
end
function Frame:getActiveStyle() return self._activeStyle end

-- draw the frame to framebuffer (including all children)
function Frame:_drawFB()
	self._bfb = self._bfb or self:_getFramebuffer()
	pushRenderTarget(self._bfb)
	self:_drawBackground()
	popRenderTarget()
	self._ffb, self._bfb = self._bfb, self._ffb
end

function Frame:_drawBackground()
	if self._curStyle then
		local color = self._curStyle:getColor()
		local image = self._curStyle:getImage()
		local quad = self._curStyle:getQuad()

		if color then
			setColor(color)

			if image then
				if quad then
					drawq(image, quad, 0, 0)
				else
					draw(image, 0, 0)
				end
			else
				-- draw background rectangle if color was specified
				rectangle('fill', 0, 0, self._w, self._h)
			end
		end
	end
end

-- draw the framebuffer and all child framebuffers
function Frame:draw(offsetX, offsetY)
	if self._ffb then
		offsetX = offsetX or 0
		offsetY = offsetY or 0

		local drawX, drawY = self._x + offsetX, self._y + offsetY

		setColor(colors.WHITE)
		draw(self._ffb, drawX, drawY)

		love.graphics.setFont(GameFont.console)
		local coords = love.mouse.getX()..','..love.mouse.getY()
		love.graphics.print(coords, 0, 0)

		local num = #self._children
		for i=1,num do
			local child = self._children[i]
			child:draw(drawX, drawY)
		end
	end
end


-- the class
return Frame
