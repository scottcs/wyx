local Class = require 'lib.hump.class'
local Camera = require 'lib.hump.camera'
local vector = require 'lib.hump.vector'
local message = require 'pud.component.message'
local property = require 'pud.component.property'

local math_max, math_min = math.max, math.min
local verify, verifyClass, select, pairs = verify, verifyClass, select, pairs

local _zoomLevels = {1, 0.5, 0.25}

local _isVector = function(...)
	local n = select('#',...)
	for i=1,n do
		local v = select(i,...)
		verify('vector', v)
	end
	return n > 0
end

local GameCam = Class{name='GameCam',
	function(self, v, zoom)
		v = v or vector(0,0)
		if _isVector(v) then
			self._zoom = math_max(1, math_min(#_zoomLevels, zoom or 1))
			self._home = v
			self._cam = Camera(v, _zoomLevels[self._zoom])
		end
	end
}

-- destructor
function GameCam:destroy()
	self:unfollowTarget()
	self._cam = nil
	self._home = nil
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

-- receive - receives messages from followed ComponentMediator
function GameCam:receive(msg, pos, oldpos)
	if msg == message('HAS_MOVED') then
		local size = self._targetSize
		self._cam.pos.x = (pos.x-1) * size + size/2
		self._cam.pos.y = (pos.y-1) * size + size/2
		self:_correctPos(self._cam.pos)
	end
end

-- follow a target
function GameCam:followTarget(t)
	verifyClass('pud.component.ComponentMediator', t)

	self:unfollowTarget()
	t:attach(message('HAS_MOVED'), self)
	self._targetSize = t:query(property('TileSize'))
	self._target = t

	-- set the initial position
	self:receive(message('HAS_MOVED'), t:query(property('Position')))
end

-- unfollow a target
function GameCam:unfollowTarget()
	if self._target then
		if self._target:getID() then
			self._target:detach(message('HAS_MOVED'), self)
		end
		self._target = nil
		self._targetSize = nil
	end
end

-- center on initial vector
function GameCam:home()
	self:unfollowTarget()
	self._cam.pos = self._home
	self:_correctPos(self._cam.pos)
end

-- change home vector
function GameCam:setHome(home)
	if _isVector(home) then
		self._home = home
	end
end

-- translate along v
-- allows a callback to be passed in that will be called after the animation
-- is complete.
function GameCam:translate(v, ...)
	if _isVector(v) and not self:isAnimating() then
		self:_checkLimits(v)
		if v:len2() ~= 0 then
			local target = self._cam.pos + v
			self:_setAnimating(true)
			tween(0.15, self._cam.pos, target, 'outQuint',
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

function GameCam:_checkLimits(v)
	local pos = self._cam.pos + v

	if pos.x > self._limits.max.x then
		v.x = self._limits.max.x - self._cam.pos.x
	end
	if pos.x < self._limits.min.x then
		v.x = self._limits.min.x - self._cam.pos.x
	end
	if pos.y > self._limits.max.y then
		v.y = self._limits.max.y - self._cam.pos.y
	end
	if pos.y < self._limits.min.y then
		v.y = self._limits.min.y - self._cam.pos.y
	end
end

-- set x and y limits for camera
function GameCam:setLimits(minV, maxV)
	if _isVector(minV, maxV) then
		self._limits = {min = minV, max = maxV}
	end
end

-- correct the camera position if it is beyond the limits
function GameCam:_correctPos(p)
	if p.x > self._limits.max.x then
		p.x = self._limits.max.x
	end
	if p.x < self._limits.min.x then
		p.x = self._limits.min.x
	end

	if p.y > self._limits.max.y then
		p.y = self._limits.max.y
	end
	if p.y < self._limits.min.y then
		p.y = self._limits.min.y
	end
end

-- camera draw callbacks
function GameCam:predraw() self._cam:predraw() end
function GameCam:postdraw() self._cam:postdraw() end
function GameCam:draw(...) self._cam:draw(...) end

function GameCam:toWorldCoords(campos, zoom, p)
	local p = vector((p.x-WIDTH/2) / zoom, (p.y-HEIGHT/2) / zoom)
	return p + campos
end

-- get a rect representing the camera viewport
function GameCam:getViewport(translate, zoom)
	translate = translate or vector(0,0)
	zoom = self._zoom + (zoom or 0)
	zoom = math_max(1, math_min(#_zoomLevels, zoom))

	-- pretend to translate and zoom
	local pos = self._cam.pos:clone()
	pos = pos + translate
	self:_correctPos(pos)
	zoom = _zoomLevels[zoom]

	local tl, br = vector(0,0), vector(WIDTH, HEIGHT)
	local vp1 = self:toWorldCoords(pos, zoom, tl)
	local vp2 = self:toWorldCoords(pos, zoom, br)
	local Rect = getClass 'pud.kit.Rect'
	return Rect(vp1, vp2-vp1)
end

-- the class
return GameCam
