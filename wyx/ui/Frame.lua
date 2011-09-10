local Class = require 'lib.hump.class'
local Rect = getClass 'wyx.kit.Rect'

local math_max = math.max
local math_floor = math.floor
local getMousePosition = love.mouse.getPosition
local newFramebuffer = love.graphics.newFramebuffer
local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle
local draw = love.graphics.draw
local drawq = love.graphics.drawq
local setRenderTarget = love.graphics.setRenderTarget
local nearestPO2 = nearestPO2
local colors = colors

-- Frame
-- Basic UI Element
local Frame = Class{name='Frame',
	inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)

		self._children = {}
		self._accum = 0
		self._depth = 30
		self._show = true

		self:_drawFB()
		self:becomeIndependent()
	end
}

-- destructor
function Frame:destroy()
	if self._registered then UISystem:unregister(self) end
	self._registered = nil

	if self._children then
		for k,v in pairs(self._children) do
			self._children[k]:destroy()
			self._children[k] = nil
		end
		self._children = nil
	end

	self._ffb = nil
	self._bfb = nil

	self._curStyle = nil

	if self._normalStyle then
		self._normalStyle = nil
	end

	if self._hoverStyle then
		self._hoverStyle = nil
	end

	if self._activeStyle then
		self._activeStyle = nil
	end

	if self._destroyStyles then
		local num = #self._destroyStyles
		for i=1,num do
			self._destroyStyles[i]:destroy()
			self._destroyStyles[i] = nil
		end
		self._destroyStyles = nil
	end

	self._hovered = nil
	self._mouseDown = nil
	self._accum = nil
	self._show = nil
	self._tooltip = nil

	Rect.destroy(self)
end

-- depth-first search of children, lowest child that contains the mouse click
-- will handle it
function Frame:handleMousePress(x, y, button, mods)
	local handled = false

	if self:containsPoint(x, y) then
		local num = #self._children
		local i = 0

		while not handled and i < num do
			i = i + 1
			local child = self._children[i]
			handled = child:handleMousePress(x, y, button, mods)
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

function Frame:handleMouseRelease(x, y, button, mods)
	local num = #self._children
	local handled = false

	local i = 0
	while not handled and i < num do
		i = i + 1
		local child = self._children[i]
		handled = child:handleMouseRelease(x, y, button, mods)
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

-- handle keyboard events
function Frame:handleKeyboard(key, unicode, unicodeValue, mods)
	local handled = false

	local num = #self._children
	local i = 0

	while not handled and i < num do
		i = i + 1
		local child = self._children[i]
		handled = child:handleKeyboard(key, unicode, unicodeValue, mods)
	end

	if not handled then
		handled = self:onKey(key, unicode, unicodeValue, mods)
	end

	self:_drawFB()
	return handled
end

-- add a child
function Frame:addChild(frame, depth)
	verifyClass(Frame, frame)

	local num = #self._children
	self._children[num+1] = frame
	frame:becomeChild(self, depth)

	self:_drawFB()
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

	self:_drawFB()
end

-- get all of the children of this frame
function Frame:getChildren() return self._children end

-- get an appropriately sized PO2 framebuffer
function Frame:_getFramebuffer()
	local size = nearestPO2(math_max(self:getWidth(), self:getHeight()))
	local fb = newFramebuffer(size, size)
	return fb
end

-- perform necessary tasks to become an independent frame (no parent)
function Frame:becomeIndependent(parent)
	if parent then
		local x, y = parent:getX() - self:getX(), parent:getY() - self:getY()
		self:setPosition(x, y)
	end

	UISystem:register(self)
	self._registered = true
end

-- perform necessary tasks to become a child frame (with a parent)
function Frame:becomeChild(parent, depth)
	if parent then
		local x, y = self:getX() + parent:getX(), self:getY() + parent:getY()
		self:setPosition(x, y)
	end

	UISystem:unregister(self)
	self._registered = false
	if depth then self:setDepth(depth) end
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
function Frame:onTick(dt, x, y, hovered)
	if nil == x or nil == y then
		x, y = getMousePosition()
	end

	hovered = hovered or false
	local num = #self._children
	for i=1,num do
		local child = self._children[i]
		hovered = child:onTick(dt, x, y, hovered) or hovered
	end

	if not hovered and self:containsPoint(x, y) then
		if not self._hovered then self:onHoverIn(x, y) end
		self._hovered = true
		hovered = true
		self:_setTooltipPosition(x, y)
	else
		if self._hovered then self:onHoverOut(x, y) end
		self._hovered = false
	end

	return hovered
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

-- onKey - called when a key is pressed
function Frame:onKey(key, unicode, unicodeValue, mods) end

-- set the given style
function Frame:_setStyle(which, style)
	verifyClass('wyx.ui.Style', style)
	self[which] = style
	self._curStyle = self._curStyle or style
	self:_drawFB()
end

-- set/get normal style
-- if destroy is true, Frame will destroy the style when Frame is destroyed
function Frame:setNormalStyle(style, destroy)
	self:_setStyle('_normalStyle', style)
	if destroy then self:_addStyleToDestroy(style) end
end
function Frame:getNormalStyle() return self._normalStyle end

-- set/get hover style
-- if destroy is true, Frame will destroy the style when Frame is destroyed
function Frame:setHoverStyle(style, destroy)
	self:_setStyle('_hoverStyle', style)
	if destroy then self:_addStyleToDestroy(style) end
end
function Frame:getHoverStyle() return self._hoverStyle end

-- set/get active style
-- if destroy is true, Frame will destroy the style when Frame is destroyed
function Frame:setActiveStyle(style, destroy)
	self:_setStyle('_activeStyle', style)
	if destroy then self:_addStyleToDestroy(style) end
end
function Frame:getActiveStyle() return self._activeStyle end

-- add a style to be destroyed when this Frame is destroyed
function Frame:_addStyleToDestroy(style)
	self._destroyStyles = self._destroyStyles or {}
	self._destroyStyles[#self._destroyStyles + 1] = style
end

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

-- attach a tooltip to this frame that will be drawn on mouseover
function Frame:attachTooltip(tooltip)
	verifyClass('wyx.ui.Tooltip', tooltip)
	self._tooltip = tooltip
end

-- set the position of the tooltip
function Frame:_setTooltipPosition(x, y)
	if self._tooltip then
		local cursorW, cursorH = 8, 16
		local tw, th = self._tooltip:getSize()
		local w2, h2 = math_floor(WIDTH/2), math_floor(HEIGHT/2)

		-- place tooltip so that it always grows toward the center of the screen
		local left = (x + cursorW) > w2
		local top = (y + cursorH) > h2
	  x = top and x or x + cursorW
		x = left and x - tw or x
		y = top and y - th or y + cursorH

		self._tooltip:setPosition(x, y)
	end
end

-- get/set frame depth (draw layer... lower number is above higher number)
function Frame:getDepth() return self._depth end
function Frame:setDepth(depth)
	verify('number', depth)
	self._depth = depth
	if self._registered then
		UISystem:unregister(self)
		UISystem:register(self)
	end
end

-- draw the frame to framebuffer
function Frame:_drawFB()
	self._bfb = self._bfb or self:_getFramebuffer()
	setRenderTarget(self._bfb)
	self:_drawBackground()
	self:_drawForeground()
	self:_drawBorder()
	setRenderTarget()
	self._ffb, self._bfb = self._bfb, self._ffb
end

-- draw the background
function Frame:_drawBackground()
	if self._curStyle then
		local bgcolor = self._curStyle:getBGColor()
		local bgimage = self._curStyle:getBGImage()
		local bgquad = self._curStyle:getBGQuad()
		self:_drawLayer(bgcolor, bgimage, bgquad)
	end
end

-- draw the foreground
function Frame:_drawForeground()
	if self._curStyle then
		local fgcolor = self._curStyle:getFGColor()
		local fgimage = self._curStyle:getFGImage()
		local fgquad = self._curStyle:getFGQuad()
		self:_drawLayer(fgcolor, fgimage, fgquad)
	end
end

-- draw the border
function Frame:_drawBorder()
	if self._curStyle then
		local bordersize = self._curStyle:getBorderSize()
		local borderinset = self._curStyle:getBorderInset()
		local bordercolor = self._curStyle:getBorderColor()
		local borderimage = self._curStyle:getBorderImage()
		local borderquad = self._curStyle:getBorderQuad()
		self:_drawLayer(
			bordercolor,
			borderimage,
			borderquad,
			bordersize,
			borderinset)
	end
end

-- draw a single layer (foreground or background)
function Frame:_drawLayer(color, image, quad, bordersize, borderinset)
	if color then
	local inspect = require 'lib.inspect'
	print(tostring(self), inspect(color))
		setColor(color)
		local w, h = self:getSize()

		if image then
			if quad then
				local _,_, qw, qh = quad:getViewport()
				local x = math_floor((w-qw) * 0.5)
				local y = math_floor((h-qh) * 0.5)

				drawq(image, quad, x, y)
			else
				local iw, ih = image:getWidth(), image:getHeight()
				local x = math_floor((w-iw) * 0.5)
				local y = math_floor((h-ih) * 0.5)

				draw(image, x, y)
			end
		else
			if bordersize then
				local x = borderinset and borderinset or 0
				local y = x
				w = borderinset and w - 2*borderinset or w
				h = borderinset and h - 2*borderinset or h

				rectangle('fill', x, y, bordersize, h)
				rectangle('fill', x, y, w, bordersize)
				rectangle('fill', x+(w-bordersize), y, bordersize, h)
				rectangle('fill', x, y+(h-bordersize), w, bordersize)
			else
				rectangle('fill', 0, 0, w, h)
			end
		end
	end
end

-- draw the framebuffer and all child framebuffers
function Frame:draw()
	if self._ffb and self._show then

		setColor(colors.WHITE)
		draw(self._ffb, self._x, self._y)

		local num = #self._children
		for i=1,num do
			local child = self._children[i]
			child:draw()
		end

		if self._tooltip then
			if self._hovered then
				self._tooltip:show()
			else
				self._tooltip:hide()
			end
		end
	end
end

function Frame:show() self._show = true end
function Frame:hide() self._show = false end


-- the class
return Frame
