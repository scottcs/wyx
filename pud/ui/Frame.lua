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
		self:becomeIndependent()
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
	self._isChild = nil

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

	if not self._isChild then
		local x, y = e:getPosition()
		local button = e:getButton()
		local mods = e:getModifiers()

		self:_handleMousePress(x, y, button, mods)
	end
end

-- depth-first search of children, lowest child that contains the mouse click
-- will handle it
function Frame:_handleMousePress(x, y, button, mods)
	local handled = false

	if self:containsPoint(x, y) then
		local num = #self._children
		local i = 0

		while not handled and i < num do
			i = i + 1
			local child = self._children[i]
			handled = child:_handleMousePress(x, y, button, mods)
		end

		if not handled then
			self:onPress(button, mods)
			self:switchToActiveStyle()
			handled = true
		end
	else
		self:switchToNormalStyle()
	end

	self:_drawFB()
	return handled
end

-- MouseReleasedEvent
function Frame:MouseReleasedEvent(e)
	self._mouseDown = false

	if not self._isChild then
		local x, y = e:getPosition()
		local button = e:getButton()
		local mods = e:getModifiers()
		self:_handleMouseRelease(x, y, button, mods)
	end
end

function Frame:_handleMouseRelease(x, y, button, mods)
	local num = #self._children
	local handled = false

	local i = 0
	while not handled and i < num do
		i = i + 1
		local child = self._children[i]
		handled = child:_handleMouseRelease(x, y, button, mods)
	end

	if handled or not self:containsPoint(x, y) then
		self:switchToNormalStyle()
	elseif not handled then
		self:onRelease(button, mods)
		self:switchToHoverStyle()
		handled = true
	end

	self._pressed = false
	self:_drawFB()
	return handled
end

-- add a child
function Frame:addChild(frame)
	verifyClass(Frame, frame)

	local num = #self._children
	self._children[num+1] = frame
	frame:becomeChild(self)
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
		else
			child:becomeIndependent(self)
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

-- perform necessary tasks to become an independent frame (no parent)
function Frame:becomeIndependent(parent)
	self._isChild = false
	if parent then
		local x, y = parent:getX() - self:getX(), parent:getY() - self:getY()
		self:setPosition(x, y)
	end
end

-- perform necessary tasks to become a child frame (with a parent)
function Frame:becomeChild(parent)
	self._isChild = true
	if parent then
		local x, y = self:getX() + parent:getX(), self:getY() + parent:getY()
		self:setPosition(x, y)
	end
end

-- override Rect:setX() to send translation to children
function Frame:setX(x)
	local oldx = self:getX()
	local diff
	if oldx then diff = x - oldx end

	Rect.setX(self, x)

	if diff then
		local num = #self._children
		for i=1,num do
			local child = self._children[i]
			child:_adjustX(diff)
		end
	end
end

-- override Rect:setY() to send translation to children
function Frame:setY(y)
	local oldy = self:getY()
	local diff
	if oldy then diff = y - oldy end

	Rect.setY(self, y)

	if diff then
		local num = #self._children
		for i=1,num do
			local child = self._children[i]
			child:_adjustY(diff)
		end
	end
end

-- adjust x position
function Frame:_adjustX(diff)
	self:setX(self:getX() + diff)
end

-- adjust y position
function Frame:_adjustY(diff)
	self:setY(self:getY() + diff)
end

-- what to do when update ticks
function Frame:_onTick(dt, x, y, hovered)
	if nil == x or nil == y then
		x, y = getMousePosition()
	end

	hovered = hovered or false
	local num = #self._children
	for i=1,num do
		local child = self._children[i]
		hovered = child:_onTick(dt, x, y, hovered) or hovered
	end

	if not hovered and self:containsPoint(x, y) then
		if not self._hovered then self:onHoverIn(x, y) end
		self._hovered = true
		hovered = true
	else
		if self._hovered then self:onHoverOut(x, y) end
		self._hovered = false
	end

	return hovered
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
	if not self._mouseDown then
		self:switchToHoverStyle()
		self:_drawFB()
	end
end

-- onHoverOut - called when the mouse stops hovering over the frame
function Frame:onHoverOut(x, y)
	if not self._mouseDown then
		self:switchToNormalStyle()
		self:_drawFB()
	end
end

-- onPress - called when the mouse is pressed inside the frame
function Frame:onPress(button, mods)
	self._pressed = true
end

-- onRelease - called when the mouse is released inside the frame
function Frame:onRelease(button, mods) end

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

-- switch between the styles
function Frame:switchToNormalStyle()
	self._curStyle = self._normalStyle
end

function Frame:switchToHoverStyle()
	if self._hoverStyle then
		self._curStyle = self._hoverStyle
	else
		self:switchToNormalStyle()
	end
end

function Frame:switchToActiveStyle()
	if self._activeStyle then
		self._curStyle = self._activeStyle
	else
		self:switchToHoverStyle()
	end
end


-- draw the frame to framebuffer
function Frame:_drawFB()
	self._bfb = self._bfb or self:_getFramebuffer()
	pushRenderTarget(self._bfb)
	self:_drawBackground()
	popRenderTarget()
	self._ffb, self._bfb = self._bfb, self._ffb
end

function Frame:_drawBackground()
	if self._curStyle then
		local color = self._curStyle:getBGColor()
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
function Frame:draw()
	if self._ffb then

		setColor(colors.WHITE)
		draw(self._ffb, self._x, self._y)

		love.graphics.setFont(GameFont.console)
		local coords = love.mouse.getX()..','..love.mouse.getY()
		love.graphics.print(coords, 0, 0)

		local num = #self._children
		for i=1,num do
			local child = self._children[i]
			child:draw()
		end
	end
end


-- the class
return Frame
