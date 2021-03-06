local Class = require 'lib.hump.class'
local Rect = getClass 'wyx.kit.Rect'
local depths = require 'wyx.system.renderDepths'

local math_max = math.max
local math_floor = math.floor
local getMousePosition = love.mouse.getPosition
local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle
local draw = love.graphics.draw
local drawq = love.graphics.drawq
local colors = colors
local cmult = colors.multiply
local unpack = unpack
local table_maxn = table.maxn

-- Frame
-- Basic UI Element
local Frame = Class{name='Frame',
	inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)

		self._children = {}
		self._layers = {}
		self._callbacks = {}
		self._callbackArgs = {}
		self._accum = 0
		self._depth = depths.uidefault
		self._show = true
		self._hoverWithChildren = false
		self._color = colors.clone(colors.WHITE)

		self._needsUpdate = true
		self:becomeIndependent()
	end
}

-- destructor
function Frame:destroy()
	self._needsUpdate = nil
	self._hoverWithChildren = nil

	for k in pairs(self._callbacks) do self:_clearCallback(k) end
	self._callbacks = nil
	self._callbackArgs = nil

	if self._fadeInID then tween.stop(self._fadeInID) end
	if self._fadeOutID then tween.stop(self._fadeOutID) end

	self._fadeInID = nil
	self._fadeOutID = nil
	self._fadeInColor = nil
	self._color = nil

	self:_unregisterWithUISystem()
	self._registered = nil

	self:clear()
	self._layers = nil
	self._children = nil
	self._parent = nil

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

	if self._tooltip then self._tooltip:destroy() end
	self._tooltip = nil

	Rect.destroy(self)
end

-- clear the frame by removing and destroying all children
function Frame:clear()
	self:_clearLayer('bg')
	self:_clearLayer('fg')
	self:_clearLayer('border')

	if self._children then
		for k,v in pairs(self._children) do
			self:removeChild(k)
			self._children[k]:destroy()
			self._children[k] = nil
		end
	end
end

-- set the frame color
function Frame:setColor(r, g, b, a)
	self._color = self._color or {}
	if type(r) == 'table' then
		self._color[1], self._color[2], self._color[3], self._color[4] = unpack(r)
	else
		self._color[1], self._color[2], self._color[3], self._color[4] = r,g,b,a
	end
end
function Frame:getColor(color) return self._color end

-- set the frame alpha
function Frame:setAlpha(alpha)
	self._color[4] = alpha or 255
end
function Frame:getAlpha() return self._color[4] or 255 end

-- fade the frame to full alpha
function Frame:fadeIn(time)
	time = time or 0.3
	self:show()
	local fadeInColor = self._fadeInColor or colors.WHITE
	self._fadeInID = tween(time, self._color, fadeInColor, 'inSine',
		self._postFadeIn, self)
end

function Frame:_postFadeIn()
	self._fadeInID = nil
	self._fadeInColor = nil
end

-- fade the frame to zero alpha
function Frame:fadeOut(time)
	time = time or 0.3
	self._fadeInColor = colors.clone(self._color)
	self._fadeOutID = tween(time, self._color, colors.WHITE_A00, 'outQuint',
		self._postFadeOut, self)
end

function Frame:_postFadeOut()
	self:hide()
	self._fadeOutID = nil
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

	self._needsUpdate = true
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
	self._needsUpdate = true
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

	self._needsUpdate = true
	return handled
end

-- hover when children are hovered
function Frame:hoverWithChildren(yes)
	if type(yes) ~= 'boolean' then yes = not self._hoverWithChildren end
	self._hoverWithChildren = yes
end

-- add a child
function Frame:addChild(frame, depth)
	verifyClass(Frame, frame)

	local num = #self._children
	self._children[num+1] = frame
	frame:becomeChild(self, depth)

	self._needsUpdate = true
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
			child:becomeIndependent()
		end
		self._children[i] = nil
	end

	self._children = newChildren

	self._needsUpdate = true
end

-- get all of the children of this frame
function Frame:getChildren() return self._children end

-- register with the UI system
function Frame:_registerWithUISystem()
	UISystem:register(self)
	self._registered = true
end

-- unregister with the UI system
function Frame:_unregisterWithUISystem()
	UISystem:unregister(self)
	self._registered = false
end

-- return true if this frame is registered with the UI system
function Frame:isRegisteredWithUISystem() return self._registered == true end

-- perform necessary tasks to become an independent frame (no parent)
function Frame:becomeIndependent()
	if self._parent then
		local x = self._parent:getX() - self:getX()
		local y = self._parent:getY() - self:getY()
		self._parent = nil
		self:setPosition(x, y)
	end

	self:_registerWithUISystem()
end

-- perform necessary tasks to become a child frame (with a parent)
function Frame:becomeChild(parent, depth)
	if parent then
		local x, y = self:getX() + parent:getX(), self:getY() + parent:getY()
		self:setPosition(x, y)
		self._parent = parent
	end

	self:_unregisterWithUISystem()
	if depth then self:setDepth(depth) end
end

-- get screen position, regardless of whether this frame is a child or not
function Frame:getScreenPosition()
	local x, y = self:getPosition()

	if self._parent then
		local parentX, parentY = self._parent:getScreenPosition()
		x = x - parentX
		y = y - parentY
	end

	return x, y
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
		self._needsUpdate = true
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
		self._needsUpdate = true
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
	if self._show then
		if self._needsUpdate then
			self:_calculateDrawing()
			self._needsUpdate = false
		end

		if nil == x or nil == y then
			x, y = getMousePosition()
		end

		hovered = hovered or false
		local num = #self._children
		for i=1,num do
			local child = self._children[i]
			if child:isVisible() then
				hovered = child:onTick(dt, x, y, hovered) or hovered
			end
		end

		if (not hovered or self._hoverWithChildren)
			and self:containsPoint(x, y)
		then
			if not self._hovered then self:onHoverIn(x, y) end
			self._hovered = true
			hovered = true
			self:_setTooltipPosition(x, y)
		else
			if self._hovered then self:onHoverOut(x, y) end
			self._hovered = false
		end
	end

	return hovered
end

-- onHoverIn - called when the mouse starts hovering over the frame
function Frame:onHoverIn(x, y)
	if not self._mouseDown then
		self:switchToHoverStyle()
		self._needsUpdate = true
	end
end

-- onHoverOut - called when the mouse stops hovering over the frame
function Frame:onHoverOut(x, y)
	if not self._mouseDown then
		self:switchToNormalStyle()
		self._needsUpdate = true
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
	self._curStyle = self._curStyle or which
	self._needsUpdate = true
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
	self._curStyle = '_normalStyle'
end

function Frame:switchToHoverStyle()
	if self._hoverStyle then
		self._curStyle = '_hoverStyle'
	else
		self:switchToNormalStyle()
	end
end

function Frame:switchToActiveStyle()
	if self._activeStyle then
		self._curStyle = '_activeStyle'
	else
		self:switchToHoverStyle()
	end
end

function Frame:getCurrentStyle() return self[self._curStyle] end

-- attach a tooltip to this frame that will be drawn on mouseover
function Frame:attachTooltip(tooltip)
	verifyClass('wyx.ui.Tooltip', tooltip)
	self._tooltip = tooltip
end

-- get the tooltip attached to this frame
function Frame:getTooltip() return self._tooltip end

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
	if self:isRegisteredWithUISystem() then
		-- NOTE: Order of operations here is very important
		self:_unregisterWithUISystem()
		self:setDepth(depth)
		self:_registerWithUISystem()
	else
		self._depth = depth
	end
end

-- calculate draw positions and size
function Frame:_calculateDrawing()
	self:_updateBackground()
	self:_updateForeground()
	self:_updateBorder()
end

-- update the background
function Frame:_updateBackground()
	local style = self:getCurrentStyle()
	if style then
		self:_makeLayer('bg',
			style:getBGColor(), style:getBGImage(), style:getBGQuad())
	end
end

-- update the foreground
function Frame:_updateForeground()
	local style = self:getCurrentStyle()
	if style then
		self:_makeLayer('fg',
			style:getFGColor(), style:getFGImage(), style:getFGQuad())
	end
end

-- update the border
function Frame:_updateBorder()
	local style = self:getCurrentStyle()
	if style then
		self:_makeLayer('border',
			style:getBorderColor(), style:getBorderImage(), style:getBorderQuad(),
			style:getBorderSize(), style:getBorderInset())
	end
end

-- draw the frame
function Frame:_draw(color)
	self:_drawBackground(color)
	self:_drawForeground(color)
	self:_drawBorder(color)
end

-- draw the background, foreground, and border
function Frame:_drawBackground(color) self:_drawLayer('bg', color) end
function Frame:_drawForeground(color) self:_drawLayer('fg', color) end
function Frame:_drawBorder(color) self:_drawLayer('border', color) end

-- clear a draw layer
function Frame:_clearLayer(layer)
	if self._layers[layer] then
		for k,v in pairs(self._layers[layer]) do
			if type(v) == 'table' and k ~= 'color' then
				for j,w in pairs(v) do
					if type(w) == 'table' then
						for i in pairs(w) do w[i] = nil end
					end
					v[j] = nil
				end
			end
			self._layers[layer][k] = nil
		end
		self._layers[layer] = nil
	end
end

-- make a new draw layer
function Frame:_makeLayer(layer, color, image, quad, bordersize, borderinset)
	self:_clearLayer(layer)

	local l = {
		color = color,
		image = image,
		quad = quad,
		bordersize = bordersize,
		borderinset = borderinset,
	}

	if color then
		local x, y = self:getPosition()
		local w, h = self:getSize()

		if image then
			if quad then
				local _,_, qw, qh = quad:getViewport()
				l.x = x + math_floor((w-qw) * 0.5)
				l.y = y + math_floor((h-qh) * 0.5)
			else
				local iw, ih = image:getWidth(), image:getHeight()
				l.x = x + math_floor((w-iw) * 0.5)
				l.y = y + math_floor((h-ih) * 0.5)
			end
		else
			if bordersize then
				local bx = borderinset and borderinset or 0
				local by = bx
				x = x + bx
				y = y + by
				w = borderinset and w - 2*borderinset or w
				h = borderinset and h - 2*borderinset or h

				l.rectangles = {
					{x, y, bordersize, h},
					{x, y, w, bordersize},
					{x+(w-bordersize), y, bordersize, h},
					{x, y+(h-bordersize), w, bordersize},
				}
			else
				l.rectangle = {x, y, w, h}
			end
		end
	end

	self._layers[layer] = l
end


-- draw a single layer
function Frame:_drawLayer(layer, color)
	local l = self._layers[layer]
	if not l then return end

	if l.color then
		setColor(cmult(self._color, color, l.color))

		if l.image then
			if l.quad then
				drawq(l.image, l.quad, l.x, l.y)
			else
				draw(l.image, l.x, l.y)
			end
		else
			if l.bordersize then
				if l.rectangles then
					for i=1,#l.rectangles do
						local r = l.rectangles[i]
						rectangle('fill', r[1], r[2], r[3], r[4])
					end
				end
			else
				if l.rectangle then
					local r = l.rectangle
					rectangle('fill', r[1], r[2], r[3], r[4])
				end
			end
		end
	end
end

-- draw the frame and all child frames
function Frame:draw(color)
	if self._show then
		if self._tooltip then
			if self._hovered then
				self:_showTooltip()
			else
				self:_hideTooltip()
			end
		end

		color = color or self._color

		setColor(color)
		self:_draw(color)

		local num = #self._children
		for i=1,num do
			local child = self._children[i]
			child:draw(self._color)
		end
	end
end

function Frame:_showTooltip()
	self._tooltip:show()
	self:_callTooltipCallback('tooltipshow')
end

function Frame:_hideTooltip()
	self._tooltip:hide()
	self:_callTooltipCallback('tooltiphide')
end

-- tooltip callback - called when tooltip is shown
function Frame:setTooltipShowCallback(func, ...)
	self:setCallback('tooltipshow', func, ...)
end

-- tooltip callback - called when tooltip is hidden
function Frame:setTooltipHideCallback(func, ...)
	self:setCallback('tooltiphide', func, ...)
end

function Frame:_callTooltipCallback(which)
	if self._callbacks[which] then
		local args = self._callbackArgs[which]
		if args then
			self._callbacks[which](unpack(args))
		else
			self._callbacks[which]()
		end
	end
end

-- set callback functions and arguments
function Frame:setCallback(which, func, ...)
	verify('string', which)
	verify('function', func)
	self:_clearCallback(which)

	self._callbacks[which] = func

	local numArgs = select('#', ...)
	if numArgs > 0 then self._callbackArgs[which] = {...} end
end

-- clear the given callback
function Frame:_clearCallback(which)
	self._callbacks[which] = nil
	if self._callbackArgs[which] then
		for k,v in pairs(self._callbackArgs[which]) do
			self._callbackArgs[which][k] = nil
		end
		self._callbackArgs[which] = nil
	end
end

-- return true if the given callback exists
function Frame:_callbackExists(which)
	return self._callbacks[which] ~= nil
end

-- call the given callback
function Frame:_callCallback(which, ...)
	local cb = self._callbacks[which]
	local cbArgs = self._callbackArgs[which]

	if cb then
		local args = {}
		local count = 0
		local num = select('#', ...)

		if num > 0 then
			for i=1,num do
				count = count + 1
				args[count] = select(i, ...)
			end
		end

		if cbArgs then
			num = table_maxn(cbArgs)
			for i=1,num do
				count = count + 1
				args[count] = cbArgs[i]
			end
		end

		if count > 0 then
			return cb(unpack(args, 1, table_maxn(args)))
		else
			return cb()
		end
	end
end


function Frame:show() self._show = true end
function Frame:hide()
	self._show = false
	if self._tooltip then self._tooltip:hide() end
end
function Frame:isVisible() return self._show == true end
function Frame:toggle()
	if self:isVisible() then self:hide() else self:show() end
end


-- the class
return Frame
