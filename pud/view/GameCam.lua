require 'pud.util'
local Class = require 'lib.hump.class'
local Camera = require 'lib.hump.camera'
local vector = require 'lib.hump.vector'
local Rect = require 'pud.kit.Rect'

local _zoomLevels = {1, 0.5, 0.25}

local GameCam = Class{name='GameCam',
	function(self, v, zoom)
		v = v or vector(0,0)
		self._zoom = math.max(1, math.min(#_zoomLevels, zoom or 1))
		self._home = v
		self._cam = Camera(v, _zoomLevels[self._zoom])
	end
}

-- destructor
function GameCam:destroy()
	self._cam = nil
	self._home = nil
	self._zoom = nil
	self._target = nil
	self._targetSetX = nil
	self._targetSetY = nil
	for k,v in pairs(self._limits) do self._limits[k] = nil end
	self._bounday = nil
end

-- zoom in smoothly
function GameCam:zoomIn()
	if self._zoom > 1 then
		self._zoom = self._zoom - 1
		tween(0.25, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outBack')
	else
		self:_bumpZoom(1.1)
	end
end

-- zoom out smoothly
function GameCam:zoomOut()
	if self._zoom < #_zoomLevels then
		self._zoom = self._zoom + 1
		tween(0.25, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outBack')
	else
		self:_bumpZoom(0.9)
	end
end

-- bump the zoom but don't change it
function GameCam:_bumpZoom(mult)
	tween(0.1, self._cam, {zoom = _zoomLevels[self._zoom] * mult}, 'inQuad',
		tween, 0.1, self._cam, {zoom = _zoomLevels[self._zoom]}, 'outQuad')
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
	self._targetSetX = rect.setX
	self._targetSetY = rect.setY

	rect.setX = function(theRect, x)
		self._targetSetX(theRect, x)
		local cx, cy = theRect:getCenter('floor')
		self:_setPos(cx, cy)
		self:_correctCam()
	end

	rect.setY = function(theRect, y)
		self._targetSetY(theRect, y)
		local cx, cy = theRect:getCenter('floor')
		self:_setPos(cx, cy)
		self:_correctCam()
	end
end

-- unfollow a target Rect
function GameCam:unfollowTarget()
	if self._target then
		self._target.setX = self._targetSetX
		self._target.setY = self._targetSetY
		self._targetSetX = nil
		self._targetSetY = nil
		self._target = nil
	end
end

-- set position
function GameCam:_setPos(x, y)
	if type(x) == 'table' then
		x, y = x.x, x.y
	end
	verify('number', x, y)
	self._cam.pos.x = x
	self._cam.pos.y = y
end

-- center on initial vector
function GameCam:home()
	self:unfollowTarget()
	self:_setPos(self._home)
	self:_correctCam()
end

-- change home vector
function GameCam:setHome(x, y)
	local v = x
	if type(x) == 'number' then v = vector(x, y) end
	self._home = v
end

-- translate along x and y
function GameCam:translate(x, y)
	local v = x
	if type(x) == 'number' then v = vector(x, y) end
	self._cam:translate(v)
	self:_correctCam()
end

-- set x and y limits for camera
function GameCam:setLimits(minX, minY, maxX, maxY)
	local minV, maxV = minX, minY
	if type(minX) == 'number' then
		minV = vector(minX, minY)
		maxV = vector(maxX, maxY)
	end
	self._limits = {min = minV, max = maxV}
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
