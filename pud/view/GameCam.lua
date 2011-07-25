require 'pud.util'
local Class = require 'lib.hump.class'
local Camera = require 'lib.hump.camera'
local vector = require 'lib.hump.vector'
local Rect = require 'pud.kit.Rect'

local math_max, math_min = math.max, math.min

local _zoomLevels = {1, 0.5, 0.25}

local GameCam = Class{name='GameCam',
	function(self, homeX, homeY, zoom)
		self._zoom = math_max(1, math_min(#_zoomLevels, zoom or 1))
		self:setHome(homeX, homeY)
		self._cam = Camera(vector(homeX, homeY), _zoomLevels[self._zoom])
	end
}

-- destructor
function GameCam:destroy()
	self:unfollowTarget()
	self._cam = nil
	self._homeX = nil
	self._homeY = nil
	self._zoom = nil
	for k,v in pairs(self._limits) do self._limits[k] = nil end
	self._limits = nil
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
	if self._zoom > 1 and not self:isAnimating() then
		self._zoom = self._zoom - 1
		self:_setAnimating(true)
		tween(0.25, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outBack',
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
	if self._zoom < #_zoomLevels and not self:isAnimating() then
		self._zoom = self._zoom + 1
		self:_setAnimating(true)
		tween(0.25, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outBack',
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
		tween(0.1, self._cam, {zoom = _zoomLevels[self._zoom] * mult}, 'inQuad',
			tween, 0.1, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outQuad',
			self._setAnimating, self, false)
	end
end

-- return zoom level
function GameCam:getZoom()
	return self._zoom, _zoomLevels[self._zoom]
end

-- follow a target Rect
function GameCam:followTarget(rect)
	assert(rect and rect.is_a and rect:is_a(Rect),
		'GameCam can only follow a Rect (tried to follow %s)', tostring(rect))

	self._target = rect
	self._targetFuncs = {
		setX = rect.setX,
		setY = rect.setY,
	}

	local function _follow(self, theRect)
		local cx, cy = theRect:getCenter()
		self._cam.pos.x, self._cam.pos.y = self:_correctPos(cx, cy)
	end

	rect.setX = function(theRect, x)
		self._targetFuncs.setX(theRect, x)
		_follow(self, theRect)
	end

	rect.setY = function(theRect, y)
		self._targetFuncs.setY(theRect, y)
		_follow(self, theRect)
	end
end

-- unfollow a target Rect
function GameCam:unfollowTarget()
	if self._target then
		self._target.setX = self._targetFuncs.setX
		self._target.setY = self._targetFuncs.setY
		self._targetFuncs.setX = nil
		self._targetFuncs.setY = nil
		self._targetFuncs = nil
		self._target = nil
	end
end

-- center on initial point
function GameCam:home()
	self:unfollowTarget()
	local x, y = self._homeX, self._homeY
	self._cam.pos.x, self._cam.pos.y = self:_correctPos(x, y)
end

-- change home point
function GameCam:setHome(homeX, homeY)
	verify('number', homeX, homeY)
	self._homeX = homeX
	self._homeY = homeY
end

-- translate along v
-- allows a callback to be passed in that will be called after the animation
-- is complete.
function GameCam:translate(x, y, ...)
	if not self:isAnimating() and self:_shouldTranslate(x, y) then
		local targetX = self._cam.pos.x + x
		local targetY = self._cam.pos.y + y
		self:_setAnimating(true)
		tween(0.15, self._cam.pos, {x = targetX, y = targetY}, 'outQuint',
			function(self, ...)
				self:_setAnimating(false)
				if select('#', ...) > 0 then
					local callback = select(1, ...)
					callback(select(2, ...))
				end
			end, self, ...)
	end
end

function GameCam:_shouldTranslate(x, y)
	x = x + self._cam.pos.x
	y = y + self._cam.pos.y
	return not (x > self._limits.maxX or x < self._limits.minX
		or y > self._limits.maxY or y < self._limits.minY)
end

-- set x and y limits for camera
function GameCam:setLimits(minX, minY, maxX, maxY)
	verify('number', minX, minY, maxX, maxY)
	self._limits = {minX = minX, minY = minY, maxX = maxX, maxY = maxY}
end

-- correct the camera position if it is beyond the limits
function GameCam:_correctPos(x, y)
	if x > self._limits.maxX then x = self._limits.maxX end
	if x < self._limits.minX then x = self._limits.minX end
	if y > self._limits.maxY then y = self._limits.maxY end
	if y < self._limits.minY then y = self._limits.minY end
	return x, y
end

-- camera draw callbacks
function GameCam:predraw() self._cam:predraw() end
function GameCam:postdraw() self._cam:postdraw() end
function GameCam:draw(...) self._cam:draw(...) end

function GameCam:toWorldCoords(camX, camY, zoom, x, y)
	local wx, wy = (x-WIDTH/2) / zoom, (y-HEIGHT/2) / zoom
	return wx + camX, wy + camY
end

-- get a rect representing the camera viewport
function GameCam:getViewport(tx, ty, zoom)
	tx = tx or 0
	ty = ty or 0
	zoom = self._zoom + (zoom or 0)
	zoom = math_max(1, math_min(#_zoomLevels, zoom))

	-- pretend to translate and zoom
	local x, y = self._cam.pos.x, self._cam.pos.y
	x, y = self:_correctPos(x + tx, y + ty)
	zoom = _zoomLevels[zoom]

	local x1, y1, x2, y2 = 0, 0, WIDTH, HEIGHT
	local vpx1, vpy1 = self:toWorldCoords(x, y, zoom, x1, y1)
	local vpx2, vpy2 = self:toWorldCoords(x, y, zoom, x2, y2)
	return Rect(vpx1, vpy1, vpx2-vpx1, vpy2-vpy1)
end

-- the class
return GameCam
