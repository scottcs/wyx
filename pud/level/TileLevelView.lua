local Class = require 'lib.hump.class'
local LevelView = require 'pud.level.LevelView'
local Map = require 'pud.level.Map'
local MapNode = require 'pud.level.MapNode'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'

local random = math.random

-- TileLevelView
-- draws tiles for each node in the level map to a framebuffer, which is then
-- drawn to screen
local TileLevelView = Class{name='TileLevelView',
	inherits=LevelView,
	function(self, mapW, mapH)
		LevelView.construct(self)

		verify('number', mapW, mapH)

		self._tileW, self._tileH = 32, 32
		self._set = Image.dungeon

		local w, h = nearestPO2(mapW*self._tileW), nearestPO2(mapH*self._tileH)
		self._fb = love.graphics.newFramebuffer(w, h)

		self._tileVariant = tostring(random(1,4))
		self._doorVariant = tostring(random(1,5))
		self._trapVariant = tostring(random(1,6))
		self._lastTorch = 'A'
		self._lastTrap = 'A'

		self:_setupQuads()
	end
}

-- destructor
function TileLevelView:destroy()
	self:_clearQuads()
	self._set = nil
	GameEvent:unregisterAll(self)
	LevelView.destroy(self)
end

-- make a quad from the given tile position
function TileLevelView:_makeQuad(mapType, variant, x, y)
	variant = tostring(variant)
	self._quads[mapType] = self._quads[mapType] or {}
	self._quads[mapType][variant] = love.graphics.newQuad(
		self._tileW*(x-1),
		self._tileH*(y-1),
		self._tileW,
		self._tileH,
		self._set:getWidth(),
		self._set:getHeight())
end

function TileLevelView:_getQuad(node)
	if self._quads then
		local mapType = node:getMapType()
		if not mapType:isType('empty') then
			local mtype, variant = mapType:get()
			if not variant then
				if mapType:isType('wall') then
					mtype = 'wall'
					variant = 'V'
				elseif mapType:isType('torch') then
					mtype = 'torch'
					variant = 'A'
				elseif mapType:isType('trap') then
					mtype = 'trap'
					variant = 'A'
				end
			end

			variant = variant or ''
			variant = variant .. '1'

			if self._quads[mtype] then
				return self._quads[mtype][variant]
			end
		end
	end
	return nil
end

-- clear the quads table
function TileLevelView:_clearQuads()
	if self._quads then
		for k,v in pairs(self._quads) do self._quads[k] = nil end
		self._quads = nil
	end
end

-- set up the quads
function TileLevelView:_setupQuads()
	self:_clearQuads()
	self._quads = {}
	for i=1,4 do
		self:_makeQuad('wall',     'H'..i,  1, i)
		self:_makeQuad('wall', 'HWorn'..i,  2, i)
		self:_makeQuad('wall',     'V'..i,  3, i)
		self:_makeQuad('torch',    'A'..i,  4, i)
		self:_makeQuad('torch',    'B'..i,  5, i)
		self:_makeQuad('floor',         i,  6, i)
		self:_makeQuad('floor', 'Worn'..i,  7, i)
		self:_makeQuad('floor',    'X'..i,  8, i)
		self:_makeQuad('floor',  'Rug'..i,  9, i)
		self:_makeQuad('stairUp',       i, 10, i)
		self:_makeQuad('stairDown',     i, 11, i)
	end
	for i=1,5 do
		self:_makeQuad('doorClosed',    i, i+(i-1), 5)
		self:_makeQuad('doorOpen',      i, i*2, 5)
	end
	for i=1,6 do
		self:_makeQuad('trap',     'A'..i, i+(i-1), 6)
		self:_makeQuad('trap',     'B'..i, i*2, 6)
	end
end


-- register for events that will cause this view to redraw
function TileLevelView:registerEvents()
	local events = {
		MapUpdateFinishedEvent,
	}
	GameEvent:register(self, events)
end

-- handle registered events as they are fired
function TileLevelView:onEvent(e, ...)
	if e:is_a(MapUpdateFinishedEvent) then
		self:drawToFB(e:getMap())
	end
end

-- draw a floor tile if needed
function TileLevelView:_drawFloorIfNeeded(node, x, y)
	local mapType = node:getMapType()
	if not (mapType:isType('floor')
		or mapType:isType('wall')
		or mapType:isType('torch'))
	then
		local quad = self:_getQuad(MapNode('floor'))
		if quad then
			love.graphics.drawq(self._set, quad, x, y)
		end
	end
end

-- draw to the framebuffer
function TileLevelView:drawToFB(map)
	if self._fb and self._set
		and map and map.is_a and map:is_a(Map) and map:getHeight()
	then
		self._isDrawing = true
		love.graphics.setRenderTarget(self._fb)
		love.graphics.setColor(1,1,1)

		for y=1,map:getHeight() do
			local drawY = (y-1)*self._tileH
			for x=1,map:getWidth() do
				local node = map:getLocation(x, y)
				local quad = self:_getQuad(node)
				if quad then
					local drawX = (x-1)*self._tileW
					self:_drawFloorIfNeeded(node, drawX, drawY)
					love.graphics.drawq(self._set, quad, drawX, drawY)
				elseif not node:getMapType():isType('empty') then
					warning('no quad found for %s', tostring(node:getMapType()))
				end
			end
		end

		love.graphics.setRenderTarget()
		self._isDrawing = false
	end
end

-- draw the framebuffer to the screen
function TileLevelView:draw()
	if self._fb and self._isDrawing == false then
		love.graphics.setColor(1,1,1)
		love.graphics.draw(self._fb)
	end
end

-- the class
return TileLevelView
