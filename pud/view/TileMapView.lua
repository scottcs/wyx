local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'
local MapView = require 'pud.view.MapView'
local Level = require 'pud.map.Level'
local MapNode = require 'pud.map.MapNode'
local MapType = require 'pud.map.MapType'
local FloorMapType = require 'pud.map.FloorMapType'
local WallMapType = require 'pud.map.WallMapType'
local DoorMapType = require 'pud.map.DoorMapType'
local StairMapType = require 'pud.map.StairMapType'
local TrapMapType = require 'pud.map.TrapMapType'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'
local TileMapNodeView = require 'pud.view.TileMapNodeView'
local AnimatedTile = require 'pud.view.AnimatedTile'

local math_floor = math.floor
local math_min, math_max = math.min, math.max

-- TileMapView
-- draws tiles for each node in the level map to a framebuffer, which is then
-- drawn to screen
local TileMapView = Class{name='TileMapView',
	inherits=MapView,
	function(self, level)
		MapView.construct(self)

		assert(level and level.is_a and level:is_a(Level))
		self._level = level
		local mapW, mapH = self._level:getMapSize()

		TileMapNodeView.resetCache()

		self._tileW, self._tileH = TILEW, TILEH
		self._set = Image.dungeon

		local p2w = nearestPO2(mapW * self._tileW)
		local p2h = nearestPO2(mapH * self._tileH)
		self._frontfb = love.graphics.newFramebuffer(p2w, p2h)
		self._backfb = love.graphics.newFramebuffer(p2w, p2h)

		self._tileStyle = tostring(Random(1,4))
		self._doorStyle = tostring(Random(1,5))
		self._tiles = {}
		self._animatedTiles = {}
		self._drawTiles = {}
		self._doAnimate = true

		self._animTick = 0.25
		self._dt = 0

		self:_setupQuads()
		self:_setupTiles()
	end
}

-- destructor
function TileMapView:destroy()
	self:_clearQuads()
	self._animID = nil
	self._set = nil
	self._tileW = nil
	self._tileH = nil
	self._frontfb = nil
	self._backfb = nil
	self._level = nil
	self._animTick = nil
	self._dt = nil
	self._tileStyle = nil
	self._doorStyle = nil
	self._quadresults = nil
	self._floorcache = nil

	for i in ipairs(self._tiles) do
		self._tiles[i]:destroy()
		self._tiles[i] = nil
	end
	self._tiles = nil

	for i in ipairs(self._animatedTiles) do
		self._animatedTiles[i]:destroy()
		self._animatedTiles[i] = nil
	end
	self._animatedTiles = nil

	for i in ipairs(self._drawTiles) do
		self._drawTiles[i] = nil
	end
	self._drawTiles = nil

	if self._mapViewport then self._mapViewport:destroy() end
	self._mapViewport = nil

	GameEvents:unregisterAll(self)
	MapView.destroy(self)
end

-- set the viewport
function TileMapView:setViewport(rect)
	assert(rect and rect.is_a and rect:is_a(Rect),
		'viewport must be a Rect (was %s (%s))', tostring(rect), type(rect))

	if self._mapViewport then self._mapViewport:destroy() end

	local tl, br = rect:getBBoxVectors()
	local mapW, mapH = self._level:getMapSize()

	tl.x = math_max(1, math_floor(tl.x/self._tileW)-2)
	tl.y = math_max(1, math_floor(tl.y/self._tileH)-2)
	br.x = math_min(mapW, math_floor(br.x/self._tileW)+2)
	br.y = math_min(mapH, math_floor(br.y/self._tileH)+2)

	self._mapViewport = Rect(tl, br-tl)

	for i in ipairs(self._drawTiles) do self._drawTiles[i] = nil end
	for _,t in ipairs(self._tiles) do
		local color = self:_shouldDraw(t)
		if nil ~= color then
			self._drawTiles[#self._drawTiles+1] = {tile=t, color=color}
		end
	end
	for _,t in ipairs(self._animatedTiles) do
		local color = self:_shouldDraw(t)
		if nil ~= color then
			self._drawTiles[#self._drawTiles+1] = {tile=t, color=color}
		end
	end

	self:_drawFB()
end

-- return current tile size
function TileMapView:getTileSize()
	return self._tileW, self._tileH
end

function TileMapView:setAnimate(b)
	verify('boolean', b)
	self._doAnimate = b
end

function TileMapView:isAnimate() return self._doAnimate == true end

-- update the animated tiles
function TileMapView:update(dt)
	local updated = 0
	updated = updated + self:_updateTiles(dt)
	updated = updated + self:_updateAnimatedTiles(dt)
	if updated > 0 then self:_drawFB() end
end

function TileMapView:_updateAnimatedTiles(dt)
	self._dt = self._dt + dt
	local updated = 0

	if self._doAnimate and self._dt > self._animTick then
		self._dt = self._dt - self._animTick
		for _,t in ipairs(self._drawTiles) do
			if t.tile:is_a(AnimatedTile) then
				t.tile:update()
				updated = updated + 1
			end
		end
	end

	return updated
end

local _floorCache = setmetatable({}, {__mode='v'})
function TileMapView:getFloorQuad()
	local floorquad = _floorCache[self._tileStyle]

	if floorquad == nil then
		local floorNode = MapNode(FloorMapType('normal', self._tileStyle))
		floorquad = self:_getQuad(floorNode)
		floorNode:destroy()
		_floorCache[self._tileStyle] = floorquad
	end

	return floorquad
end

function TileMapView:_updateTiles(dt)
	local floorquad = self:getFloorQuad()
	local updated = 0

	for _,t in ipairs(self._drawTiles) do
		if t.tile:is_a(TileMapNodeView) then
			local key = t.tile:getKey()
			t.tile:update()
			if key ~= t.tile:getKey() then
				local node = t.tile:getNode()
				local quad = self:_getQuad(node)
				if quad then
					local bgquad
					if self:_shouldDrawFloor(node) then bgquad = floorquad end
					t.tile:setTile(self._set, quad, bgquad)
					updated = updated + 1
				end
			end
		end
	end

	return updated
end

-- make a quad from the given tile position
function TileMapView:_makeQuad(mapType, variant, style, x, y)
	local key = mapType(variant, style):getKey()
	self._quads[key] = love.graphics.newQuad(
		self._tileW*(x-1),
		self._tileH*(y-1),
		self._tileW,
		self._tileH,
		self._set:getWidth(),
		self._set:getHeight())
end

function TileMapView:_getQuad(node)
	local key = node:getMapType():getKey()

	local quad = self._quads[key]
	if quad == nil then
		warning('no quad found for %s', tostring(node:getMapType()))
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
		self:_makeQuad(WallMapType,    'normal',      i,  1, i)
		self:_makeQuad(WallMapType,      'worn',      i,  2, i)
		self:_makeQuad(WallMapType,  'vertical',      i,  3, i)
		self:_makeQuad(WallMapType,     'torch', 'A'..i,  4, i)
		self:_makeQuad(WallMapType,     'torch', 'B'..i,  5, i)
		self:_makeQuad(FloorMapType,   'normal',      i,  6, i)
		self:_makeQuad(FloorMapType,     'worn',      i,  7, i)
		self:_makeQuad(FloorMapType, 'interior',      i,  8, i)
		self:_makeQuad(FloorMapType,      'rug',      i,  9, i)
		self:_makeQuad(StairMapType,       'up',      i, 10, i)
		self:_makeQuad(StairMapType,     'down',      i, 11, i)
	end
	for i=1,5 do
		self:_makeQuad(DoorMapType,      'shut',      i, i+(i-1), 5)
		self:_makeQuad(DoorMapType,      'open',      i,     i*2, 5)
	end
	for i=1,6 do
		self:_makeQuad(TrapMapType,    'normal', 'A'..i, i+(i-1), 6)
		self:_makeQuad(TrapMapType,    'normal', 'B'..i, i*2, 6)
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

function TileMapView:_setupTiles()
	local torchA = MapNode(WallMapType('torch', 'A'..self._tileStyle))
	local torchB = MapNode(WallMapType('torch', 'B'..self._tileStyle))
	local trapA = MapNode(TrapMapType())
	local trapB = MapNode(TrapMapType())

	local floorquad = self:getFloorQuad()
	
	local torchUpdate = function(self)
		if self._flicker then
			self._flicker = nil
			self:advance()
		else
			if Random(1,100) <= 3 then
				self:advance()
				self._flicker = true
			end
		end
	end

	local trapUpdate = function(self)
		self:advance()
	end

	local mapW, mapH = self._level:getMapSize()

	for y=1,mapH do
		for x=1,mapW do
			local node = self._level:getMapNode(x, y)
			if node:isLit() == true then
				local mapType = node:getMapType()
				local bgquad
				if self:_shouldDrawFloor(node) then bgquad = floorquad end

				if mapType:isType(WallMapType('torch')) then
					local at = self:_createAnimatedTile(torchA, torchB, bgquad)
					at:setPosition(x, y)
					at:setUpdateCallback(torchUpdate, at)
					self._animatedTiles[#self._animatedTiles+1] = at

				elseif mapType:is_a(TrapMapType) then
					local style = Random(1,6)
					trapA:getMapType():setStyle('A'..tostring(style))
					trapB:getMapType():setStyle('B'..tostring(style))
					local at = self:_createAnimatedTile(trapA, trapB, bgquad)
					at:setPosition(x, y)
					at:setUpdateCallback(trapUpdate, at)
					self._animatedTiles[#self._animatedTiles+1] = at

				else
					if mapType:is_a(DoorMapType) then
						mapType:setStyle(self._doorStyle)
					else
						mapType:setStyle(self._tileStyle)
					end

					local quad = self:_getQuad(node)
					local t = TileMapNodeView(node)
					t:setTile(self._set, quad, bgquad)
					t:setPosition(x, y)
					self._tiles[#self._tiles+1] = t
				end
			end
		end
	end

	torchA:destroy()
	torchB:destroy()
	trapA:destroy()
	trapB:destroy()
end

-- register for events that will cause this view to redraw
function TileMapView:registerEvents()
	local events = {
		MapUpdateFinishedEvent,
	}
	GameEvents:register(self, events)
end

-- handle registered events as they are fired
function TileMapView:onEvent(e, ...)
	if e:is_a(MapUpdateFinishedEvent) then
		local map = e:getMap()
		if self._level:isMap(map) then self:_drawFB() end
	end
end

-- draw a floor tile if needed
function TileMapView:_shouldDrawFloor(node)
	local key = node:getMapType():getKey()

	self._floorcache = self._floorcache or {}
	local should = self._floorcache[key]
	if should == nil then
		local mapType = node:getMapType()
		should = not mapType:is_a(FloorMapType) and not mapType:is_a(WallMapType)
		self._floorcache[key] = should
	end
	return should
end

function TileMapView:_shouldDraw(tile)
	local pos = tile:getPositionVector()
	if self._mapViewport:containsPoint(pos)
		and self._level:isPointInMap(pos)
	then
		return self._level:getLightingColor(pos)
	end
	return nil
end

-- draw to the framebuffer
function TileMapView:_drawFB()
	if self._backfb and self._set and self._level and self._mapViewport then
		love.graphics.setRenderTarget(self._backfb)

		for _,t in ipairs(self._drawTiles) do
			love.graphics.setColor(t.color)
			t.tile:draw()
		end

		love.graphics.setRenderTarget()

		-- flip back and front frame buffers
		self._frontfb, self._backfb = self._backfb, self._frontfb
	end
end

-- draw the framebuffer to the screen
function TileMapView:draw()
	if self._frontfb then
		love.graphics.setColor(1,1,1)
		love.graphics.draw(self._frontfb)
	end
end

-- the class
return TileMapView
