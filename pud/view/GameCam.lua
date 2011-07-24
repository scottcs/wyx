require 'pud.util'
local Class = require 'lib.hump.class'
local Camera = require 'lib.hump.camera'
local vector = require 'lib.hump.vector'
local Rect = require 'pud.kit.Rect'

local _zoomLevels = {1, 0.5, 0.25}

local _isVector = function(...)
	local n = select('#',...)
	for i=1,n do
		local v = select(i,...)
		assert(vector.isvector(v), 'vector expected, got %s (%s)',
			tostring(v), type(v))
	end
	return n > 0
end

local GameCam = Class{name='GameCam',
	function(self, v, zoom)
		v = v or vector(0,0)
		if _isVector(v) then
			self._zoom = math.max(1, math.min(#_zoomLevels, zoom or 1))
			self._home = v
			self._cam = Camera(v, _zoomLevels[self._zoom])
		end
	end
}

-- destructor
function GameCam:destroy()
	self._cam = nil
	self._home = nil
	self._zoom = nil
	self._target = nil
	self._targetFuncs.setX = nil
	self._targetFuncs.setY = nil
	self._targetFuncs.setCenter = nil
	self._targetFuncs.setPosition = nil
	self._targetFuncs = nil
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
function GameCam:zoomIn()
	if self._zoom > 1 and not self:isAnimating() then
		self._zoom = self._zoom - 1
		self:_setAnimating(true)
		tween(0.25, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outBack',
			self._setAnimating, self, false)
	else
		self:_bumpZoom(1.1)
	end
end

-- zoom out smoothly
function GameCam:zoomOut()
	if self._zoom < #_zoomLevels and not self:isAnimating() then
		self._zoom = self._zoom + 1
		self:_setAnimating(true)
		tween(0.25, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outBack',
			self._setAnimating, self, false)
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
		setPosition = rect.setPosition,
		setCenter = rect.setCenter,
	}

	local function _follow(self, theRect)
		self._cam.pos = theRect:getCenterVector()
		self:_correctCam()
	end

	rect.setX = function(theRect, x)
		self._targetFuncs.setX(theRect, x)
		_follow(self, theRect)
	end

	rect.setY = function(theRect, y)
		self._targetFuncs.setY(theRect, y)
		_follow(self, theRect)
	end

	rect.setPosition = function(theRect, x, y)
		self._targetFuncs.setPosition(theRect, x, y)
		_follow(self, theRect)
	end

	rect.setCenter = function(theRect, x, y, flag)
		self._targetFuncs.setCenter(theRect, x, y, flag)
		_follow(self, theRect)
	end
end

-- unfollow a target Rect
function GameCam:unfollowTarget()
	if self._target then
		self._target.setX = self._targetFuncs.setX
		self._target.setY = self._targetFuncs.setY
		self._target.setPosition = self._targetFuncs.setPosition
		self._target.setCenter = self._targetFuncs.setCenter
		self._targetFuncs.setX = nil
		self._targetFuncs.setY = nil
		self._targetFuncs.setPosition = nil
		self._targetFuncs.setCenter = nil
		self._target = nil
	end
end

-- center on initial vector
function GameCam:home()
	self:unfollowTarget()
	self._cam.pos = self._home
	self:_correctCam()
end

-- change home vector
function GameCam:setHome(home)
	if _isVector(home) then
		self._home = home
	end
end

-- translate along v
function GameCam:translate(v)
	if _isVector(v) and not self:isAnimating() then
		local target = self._cam.pos + v
		if self:_shouldTranslate(v) then
			self:_setAnimating(true)
			tween(0.15, self._cam.pos, target, 'outQuint',
				self._setAnimating, self, false)
		end
	end
end

function GameCam:_shouldTranslate(v)
	local pos = self._cam.pos + v
	return not (pos.x > self._limits.max.x or pos.x < self._limits.min.x
		or pos.y > self._limits.max.y or pos.y < self._limits.min.y)
end

-- set x and y limits for camera
function GameCam:setLimits(minV, maxV)
	if _isVector(minV, maxV) then
		self._limits = {min = minV, max = maxV}
	end
end

-- correct the camera position if it is beyond the limits
function GameCam:_correctCam()
	if self._cam.pos.x > self._limits.max.x then
		self._cam.pos.x = self._limits.max.x
	end
	if self._cam.pos.x < self._limits.min.x then
		self._cam.pos.x = self._limits.min.x
	end

	if self._cam.pos.y > self._limits.max.y then
		self._cam.pos.y = self._limits.max.y
	end
	if self._cam.pos.y < self._limits.min.y then
		self._cam.pos.y = self._limits.min.y
	end
end

-- camera draw callbacks
function GameCam:predraw() self._cam:predraw() end
function GameCam:postdraw() self._cam:postdraw() end
function GameCam:draw(...) self._cam:draw(...) end

-- the class
return GameCam
