local Class = require 'lib.hump.class'
local MapView = require 'pud.view.MapView'
local Map = require 'pud.map.Map'
local MapNode = require 'pud.map.MapNode'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'
local AnimatedTile = require 'pud.view.AnimatedTile'

local random = math.random

-- TileMapView
-- draws tiles for each node in the level map to a framebuffer, which is then
-- drawn to screen
local TileMapView = Class{name='TileMapView',
	inherits=MapView,
	function(self, map)
		MapView.construct(self)

		assert(map and map.is_a and map:is_a(Map))
		self._map = map

		self._tileW, self._tileH = 32, 32
		self._set = Image.dungeon

		local w = nearestPO2(map:getWidth() * self._tileW)
		local h = nearestPO2(map:getHeight() * self._tileH)
		self._fb = love.graphics.newFramebuffer(w, h)
		self._floorfb = love.graphics.newFramebuffer(self._tileW, self._tileH)

		self._tileVariant = tostring(random(1,4))
		self._doorVariant = tostring(random(1,5))
		self._torches = {}
		self._traps = {}

		self:_setupQuads()
		self:_extractAnimatedTiles()
		self._animID = cron.every(0.25, self._updateAnimatedTiles, self)

		-- make static floor tile
		local quad = self:_getQuad(MapNode('floor'))
		if quad then
			self._floorfb:renderTo(function()
				love.graphics.drawq(self._set, quad, 0, 0)
			end)
		end
	end
}

-- destructor
function TileMapView:destroy()
	self:_clearQuads()
	cron.cancel(self._animID)
	self._animID = nil
	self._set = nil
	self._tileW = nil
	self._tileH = nil
	self._fb = nil
	self._floorfb = nil
	self._map = nil
	self._tileVariant = nil
	self._doorVariant = nil
	for i in ipairs(self._torches) do self._torches[i] = nil end
	for i in ipairs(self._traps) do self._traps[i] = nil end
	self._torches = nil
	self._traps = nil
	GameEvent:unregisterAll(self)
	MapView.destroy(self)
end

-- return current tile size
function TileMapView:getTileSize()
	return self._tileW, self._tileH
end

-- update the animated tiles
function TileMapView:_updateAnimatedTiles()
	for _,torch in ipairs(self._torches) do
		if torch._flicker then
			torch._flicker = nil
			torch:advance()
		else
			if random(1,100) <= 3 then
				torch:advance()
				torch._flicker = true
			end
		end
	end

	for _,trap in ipairs(self._traps) do
		trap:advance()
	end

	self:drawToFB()
end

-- make a quad from the given tile position
function TileMapView:_makeQuad(mapType, variant, x, y)
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

function TileMapView:_getQuad(node)
	if self._quads then
		local mapType = node:getMapType()
		if not mapType:isType('empty') then
			local mtype, variant = mapType:get()
			if not variant then
				if mapType:isType('wall') then
					variant = 'V'
				end
			end

			variant = variant or ''

			if mapType:isType('doorClosed', 'doorOpen') then
				variant = variant .. self._doorVariant
			elseif not mapType:isType('torch', 'trap') then
				variant = variant .. self._tileVariant
			end

			if self._quads[mtype] then
				return self._quads[mtype][variant]
			end
		end
	end
	return nil
end

-- clear the quads table
function TileMapView:_clearQuads()
	if self._quads then
		for k,v in pairs(self._quads) do self._quads[k] = nil end
		self._quads = nil
	end
end

-- set up the quads
function TileMapView:_setupQuads()
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

function TileMapView:_createAnimatedTile(nodeA, nodeB, bgquad)
	local at = AnimatedTile()

	local quadA = self:_getQuad(nodeA)
	local quadB = self:_getQuad(nodeB)

	at:setNextFrame(self._set, quadA, bgquad)
	at:setNextFrame(self._set, quadB, bgquad)

	return at
end

function TileMapView:_extractAnimatedTiles()
	local torchA = MapNode('torch', 'A'..self._tileVariant)
	local torchB = MapNode('torch', 'B'..self._tileVariant)
	local trapA = MapNode()
	local trapB = MapNode()
	local floorquad = self:_getQuad(MapNode('floor'))

	for y=1,self._map:getHeight() do
		for x=1,self._map:getWidth() do
			local node = self._map:getLocation(x, y)
			local mapType = node:getMapType()

			if mapType:isType('torch') then
				local at = self:_createAnimatedTile(torchA, torchB)
				at:setPosition(x, y)
				self._torches[#self._torches+1] = at
			elseif mapType:isType('trap') then
				local variant = random(1,6)
				trapA:setMapType('trap', 'A'..tostring(variant))
				trapB:setMapType('trap', 'B'..tostring(variant))
				local at = self:_createAnimatedTile(trapA, trapB, floorquad)
				at:setPosition(x, y)
				self._traps[#self._traps+1] = at
			end
		end
	end
end

-- register for events that will cause this view to redraw
function TileMapView:registerEvents()
	local events = {
		MapUpdateFinishedEvent,
	}
	GameEvent:register(self, events)
end

-- handle registered events as they are fired
function TileMapView:onEvent(e, ...)
	if e:is_a(MapUpdateFinishedEvent) then
		local map = e:getMap()
		if map == self._map then
			self:drawToFB()
		end
	end
end

-- draw a floor tile if needed
function TileMapView:_drawFloorIfNeeded(node, x, y)
	local mapType = node:getMapType()
	if not mapType:isType('floor', 'wall', 'torch') then
		self:_drawFloor(x, y)
	end
end

-- draw a floor tile
function TileMapView:_drawFloor(x, y)
	if self._floorfb then
		love.graphics.draw(self._floorfb, x, y)
	end
end

-- draw to the framebuffer
function TileMapView:drawToFB()
	if self._fb and self._set and self._map then
		self._isDrawing = true
		love.graphics.setRenderTarget(self._fb)
		love.graphics.setColor(1,1,1)

		for y=1,self._map:getHeight() do
			local drawY = (y-1)*self._tileH
			for x=1,self._map:getWidth() do
				local node = self._map:getLocation(x, y)
				local mapType = node:getMapType()
				if not mapType:isType('torch', 'trap') then
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
		end

		for _,torch in ipairs(self._torches) do
			local x, y = torch:getPosition()
			local drawY = (y-1)*self._tileH
			local drawX = (x-1)*self._tileW
			torch:draw(drawX, drawY)
		end

		for _,trap in ipairs(self._traps) do
			local x, y = trap:getPosition()
			local drawY = (y-1)*self._tileH
			local drawX = (x-1)*self._tileW
			trap:draw(drawX, drawY)
		end

		love.graphics.setRenderTarget()
		self._isDrawing = false
	end
end

-- draw the framebuffer to the screen
function TileMapView:draw()
	if self._fb and self._isDrawing == false then
		love.graphics.setColor(1,1,1)
		love.graphics.draw(self._fb)
	end
end

-- the class
return TileMapView
