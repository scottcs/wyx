local Class = require 'lib.hump.class'
local message = require 'pud.component.message'
local property = require 'pud.component.property'

local math_max, math_min = math.max, math.min
local verify, verifyClass, select, pairs = verify, verifyClass, select, pairs

local _zoomLevels = {1, 0.5, 0.25}

local GameCam = Class{name='GameCam',
	function(self, x, y, zoom)
		x = x or 0
		y = y or 0
		verify('number', x, y)

		self._zoomLevel = math_max(1, math_min(#_zoomLevels, zoom or 1))
		self._zoom = _zoomLevels[self._zoomLevel]
		self._homeX, self._homeY = x, y
		self._x, self._y = x, y
	end
}

-- destructor
function GameCam:destroy()
	self:unfollowTarget()
	self._x = nil
	self._y = nil
	self._homeX = nil
	self._homeY = nil
	self._zoomLevel = nil
	self._zoom = nil
	for k,v in pairs(self._limits) do self._limits[k] = nil end
	self._limits = nil
	self._isAnimating = nil
end

function GameCam:_setAnimating(b)
	verify('boolean', b)
	self._isAnimating = b
end

function GameCam:isAnimating()
	return self._isAnimating == true
end

-- zoom in smoothly
-- allows a callback to be passed in that will be called after the animation
-- is complete.
function GameCam:zoomIn(...)
	if self._zoomLevel > 1 and not self:isAnimating() then
		self._zoomLevel = self._zoomLevel - 1
		self:_setAnimating(true)
		tween(0.25, self, {_zoom = _zoomLevels[self._zoomLevel]}, 'outBack',
			function(self, ...)
				self:_setAnimating(false)
				if select('#', ...) > 0 then
					local callback = select(1, ...)
					callback(select(2, ...))
				end
			end, self, ...)
	else
		self:_bumpZoom(1.1)
	end
end

-- zoom out smoothly
-- allows a callback to be passed in that will be called after the animation
-- is complete.
function GameCam:zoomOut(...)
	if self._zoomLevel < #_zoomLevels and not self:isAnimating() then
		self._zoomLevel = self._zoomLevel + 1
		self:_setAnimating(true)
		tween(0.25, self, {_zoom = _zoomLevels[self._zoomLevel]}, 'outBack',
			function(self, ...)
				self:_setAnimating(false)
				if select('#', ...) > 0 then
					local callback = select(1, ...)
					callback(select(2, ...))
				end
			end, self, ...)
	else
		self:_bumpZoom(0.9)
	end
end

-- bump the zoom but don't change it
function GameCam:_bumpZoom(mult)
	if not self:isAnimating() then
		self:_setAnimating(true)
		tween(0.1, self, {_zoom = _zoomLevels[self._zoomLevel] * mult}, 'inQuad',
			tween, 0.1, self, {_zoom = _zoomLevels[self._zoomLevel]}, 'outQuad',
			self._setAnimating, self, false)
	end
end

-- return zoom level
function GameCam:getZoom()
	return self._zoomLevel, _zoomLevels[self._zoomLevel]
end

-- receive - receives messages from followed ComponentMediator
function GameCam:receive(sender, msg, x, y)
	if msg == message('HAS_MOVED') then
		local size = self._targetSize
		self._x = (x-1) * size + size/2
		self._y = (y-1) * size + size/2
		self._x, self._y = self:_correctPos(self._x, self._y)
	end
end

-- follow a target
function GameCam:followTarget(t)
	if type(t) == 'number' then t = EntityRegistry:get(t) end
	verifyClass('pud.component.ComponentMediator', t)

	self:unfollowTarget()
	t:attach(message('HAS_MOVED'), self)
	self._targetSize = t:query(property('TileSize'))
	self._target = t

	-- set the initial position
	local pos = t:query(property('Position'))
	self:receive(t, message('HAS_MOVED'), pos[1], pos[2])
end

-- unfollow a target
function GameCam:unfollowTarget()
	if self._target then
		-- TODO: huh? what's this if statement for?
		if self._target:getID() then
			self._target:detach(message('HAS_MOVED'), self)
		end
		self._target = nil
		self._targetSize = nil
	end
end

-- center on initial position
function GameCam:home()
	self:unfollowTarget()
	self._x, self._y = self:_correctPos(self._homeX, self._homeY)
end

-- change home position
function GameCam:setHome(x, y)
	self._homeX, self._homeY = x, y
end

-- translate along v
-- allows a callback to be passed in that will be called after the animation
-- is complete.
local vec2_len2 = vec2.len2
function GameCam:translate(x, y, ...)
	if not self:isAnimating() then
		x, y = self:_checkLimits(x, y)
		if vec2_len2(x, y) ~= 0 then
			local targetX, targetY = self._x + x, self._y + y
			self:_setAnimating(true)
			tween(0.15, self, {_x=targetX, _y=targetY}, 'outQuint',
				function(self, ...)
					self:_setAnimating(false)
					if select('#', ...) > 0 then
						local callback = select(1, ...)
						callback(select(2, ...))
					end
				end, self, ...)
		end
	end
end

function GameCam:_checkLimits(x, y)
	local posX, posY = self._x + x, self._y + y

	if posX > self._limits.maxX then
		x = self._limits.maxX - self._x
	end
	if posX < self._limits.minX then
		x = self._limits.minX - self._x
	end
	if posY > self._limits.maxY then
		y = self._limits.maxY - self._y
	end
	if posY < self._limits.minY then
		y = self._limits.minY - self._y
	end

	return x, y
end

-- set x and y limits for camera
function GameCam:setLimits(minX, minY, maxX, maxY)
	verify('number', minX, minY, maxX, maxY)
	self._limits = {minX = minX, minY = minY, maxX = maxX, maxY = maxY}
end

-- correct the camera position if it is beyond the limits
function GameCam:_correctPos(x, y)
	if x > self._limits.maxX then
		x = self._limits.maxX
	end
	if x < self._limits.minX then
		x = self._limits.minX
	end

	if y > self._limits.maxY then
		y = self._limits.maxY
	end
	if y < self._limits.minY then
		y = self._limits.minY
	end

	return x, y
end

local push, pop = love.graphics.push, love.graphics.pop
local scale = love.graphics.scale
local translate = love.graphics.translate

function GameCam:predraw()
	local z = self._zoom
	local z2 = z*2
	local x, y = WIDTH/z2 - self._x, HEIGHT/z2 - self._y
	push()
	scale(z)
	translate(x, y)
end

function GameCam:postdraw()
	pop()
end

function GameCam:toWorldCoords(camX, camY, zoom, x, y)
	local pX, pY = (x-WIDTH/2) / zoom, (y-HEIGHT/2) / zoom
	return pX+camX, pY+camY
end

-- get a rect representing the camera viewport
function GameCam:getViewport(zoom, translateX, translateY)
	translateX = translateX or 0
	translateY = translateY or 0
	zoom = self._zoomLevel + (zoom or 0)
	zoom = math_max(1, math_min(#_zoomLevels, zoom))

	-- pretend to translate and zoom
	local x, y = self._x+translateX, self._y+translateY
	x, y = self:_correctPos(x, y)
	zoom = _zoomLevels[zoom]

	local x1,y1, x2,y2 = 0,0, WIDTH,HEIGHT
	local vp1X, vp1Y = self:toWorldCoords(x, y, zoom, x1, y1)
	local vp2X, vp2Y = self:toWorldCoords(x, y, zoom, x2, y2)
	local Rect = getClass 'pud.kit.Rect'
	return Rect(vp1X, vp1Y, vp2X-vp1X, vp2Y-vp1Y)
end

-- the class
return GameCam
