local Class = require 'lib.hump.class'
local LevelView = require 'pud.level.LevelView'
local MapType = require 'pud.level.MapType'

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


		self:_setupQuads()
	end
}

-- destructor
function TileLevelView:destroy()
	self:_clearQuads()
	self._set = nil
	LevelView.destroy(self)
end

-- make a quad from the given tile position
function TileLevelView:_makeQuad(x, y)
	return love.graphics.newQuad(
		self._tileW*(x-1),
		self._tileH*(y-1),
		self._tileW,
		self._tileH,
		self._set:getWidth(),
		self._set:getHeight())
end

-- clear the quads table
function TileLevelView:_clearQuads()
	if self._quads then
		for k,v in pairs(self._quads) do self._quads[k] = nil end
		self._quads = nil
	end
end

-- set up the quads
-- TODO: this isn't going to work, because MapType resolves to its char
function TileLevelView:_setupQuads()
	self:_clearQuads()
	self._quads = {}
	for i=1,4 do
		self._quads[MapType['wallH'..i]] = self:_makeQuad(1, i)
		self._quads[MapType['wallHWorn'..i]] = self:_makeQuad(2, i)
		self._quads[MapType['wallV'..i]] = self:_makeQuad(3, i)
		self._quads[MapType['torchA'..i]] = self:_makeQuad(4, i)
		self._quads[MapType['torchB'..i]] = self:_makeQuad(5, i)
		self._quads[MapType['floor'..i]] = self:_makeQuad(6, i)
		self._quads[MapType['floorWorn'..i]] = self:_makeQuad(7, i)
		self._quads[MapType['floorX'..i]] = self:_makeQuad(8, i)
		self._quads[MapType['floorRug'..i]] = self:_makeQuad(9, i)
		self._quads[MapType['stairU'..i]] = self:_makeQuad(10, i)
		self._quads[MapType['stairD'..i]] = self:_makeQuad(11, i)
	end
	for i=1,5 do
		self._quads[MapType['doorC'..i]] = self:_makeQuad(12, i+(i-1))
		self._quads[MapType['doorO'..i]] = self:_makeQuad(12, i*2)
	end
	for i=1,6 do
		self._quads[MapType['trapA'..i]] = self:_makeQuad(13, i+(i-1))
		self._quads[MapType['trapB'..i]] = self:_makeQuad(13, i*2)
	end

	-- for compatibility
end


-- register for events that will cause this view to redraw
function TileLevelView:registerEvents()
	local events = {
		'MapUpdateFinished',
	}
	GameEvent:register(self, events)
end

-- handle registered events as they are fired
function TileLevelView:onEvent(e, ...)
	switch(e:getKey()) {
		MapUpdateFinished = function() self:drawToFB(e:getMap()) end,
	}
end

-- draw to the framebuffer
function TileLevelView:drawToFB(map)
	if self._fb and self._set and map then
		self._isDrawing = true
		love.graphics.setRenderTarget(self._fb)
		love.graphics.setColor(1,1,1)

		for y=1,map:getHeight() do
			local drawY = (y-1)*self._tileH
			for x=1,map:getWidth() do
				local node = map:getLocation(x, y)
				local quad = self._quads[node:getMapType()]
				if quad then
					local drawX = (x-1)*self._tileW
					love.graphics.drawq(self._set, quad, drawX, drawY)
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
