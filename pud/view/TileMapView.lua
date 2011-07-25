local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'
local MapView = require 'pud.view.MapView'
local Map = require 'pud.map.Map'
local MapNode = require 'pud.map.MapNode'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'
local AnimatedTile = require 'pud.view.AnimatedTile'

local random = math.random
local math_floor = math.floor
local math_min, math_max = math.min, math.max

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

		local p2w = nearestPO2(map:getWidth() * self._tileW)
		local p2h = nearestPO2(map:getHeight() * self._tileH)
		self._fb = love.graphics.newFramebuffer(p2w, p2h)
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
	if self._mapViewport then self._mapViewport:destroy() end
	self._mapViewport = nil
	GameEvent:unregisterAll(self)
	MapView.destroy(self)
end

-- set the viewport
function TileMapView:setViewport(rect)
	assert(rect and rect.is_a and rect:is_a(Rect),
		'viewport must be a Rect (was %s (%s))', tostring(rect), type(rect))

	if self._mapViewport then self._mapViewport:destroy() end

	local tl, br = rect:getBBoxVectors()
	tl.x = math_max(1, math_floor(tl.x/self._tileW)-2)
	tl.y = math_max(1, math_floor(tl.y/self._tileH)-2)
	br.x = math_min(self._map:getWidth(), math_floor(br.x/self._tileW)+2)
	br.y = math_min(self._map:getHeight(), math_floor(br.y/self._tileH)+2)

	self._mapViewport = Rect(tl, br-tl)

	self:_drawToFB()
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

	self:_drawToFB()
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

local quadresults = setmetatable({}, {__mode = 'v'})
function TileMapView:_getQuad(node)
	local quad = quadresults[node]
	if quad == nil then
		quad = 0
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
					quad = self._quads[mtype][variant]
				end
			end

			quadresults[node] = quad
		end
	end
	return quad ~= 0 and quad or nil
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
		local drawY = (y-1)*self._tileH
		for x=1,self._map:getWidth() do
			local drawX = (x-1)*self._tileW
			local node = self._map:getLocation(x, y)
			local mapType = node:getMapType()


			if mapType:isType('torch') then
				local at = self:_createAnimatedTile(torchA, torchB)
				at:setPosition(drawX, drawY)
				self._torches[#self._torches+1] = at
			elseif mapType:isType('trap') then
				local variant = random(1,6)
				trapA:setMapType('trap', 'A'..tostring(variant))
				trapB:setMapType('trap', 'B'..tostring(variant))
				local at = self:_createAnimatedTile(trapA, trapB, floorquad)
				at:setPosition(drawX, drawY)
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
			self:_drawToFB()
		end
	end
end

-- draw a floor tile if needed
local floorcache = setmetatable({}, {__mode = 'v'})
function TileMapView:_shouldDrawFloor(node)
	local should = floorcache[node]
	if should == nil then
		local mapType = node:getMapType()
		should = not mapType:isType('floor', 'wall', 'torch')
		floorcache[node] = should
	end
	return should
end

-- draw a floor tile
function TileMapView:_drawFloor(x, y)
	if self._floorfb then
		love.graphics.draw(self._floorfb, x, y)
	end
end

-- draw to the framebuffer
function TileMapView:_drawToFB()
	if self._fb and self._set and self._map and self._mapViewport then
		self._isDrawing = true
		local tl, br = self._mapViewport:getBBoxVectors()
		local mtl, mbr = self._map:getBBoxVectors()
		if tl.x < mtl.x then tl.x = mtl.x end
		if tl.y < mtl.y then tl.y = mtl.y end
		if br.x > mbr.x then br.x = mbr.x end
		if br.y > mbr.y then br.y = mbr.y end

		love.graphics.setRenderTarget(self._fb)
		love.graphics.setColor(1,1,1)

		for y=tl.y,br.y do
			local drawY = (y-1)*self._tileH
			for x=tl.x,br.x do
				local node = self._map:getLocation(x, y)
				local mapType = node:getMapType()
				if not mapType:isType('torch', 'trap') then
					local quad = self:_getQuad(node)
					if quad then
						local drawX = (x-1)*self._tileW
						if self:_shouldDrawFloor(node) then
							self:_drawFloor(drawX, drawY)
						end
						love.graphics.drawq(self._set, quad, drawX, drawY)
					elseif not node:getMapType():isType('empty') then
						warning('no quad found for %s', tostring(node:getMapType()))
					end
				end
			end
		end

		for _,torch in ipairs(self._torches) do torch:draw() end
		for _,trap in ipairs(self._traps) do trap:draw() end

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
