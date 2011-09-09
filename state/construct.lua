
         --[[--
     CONSTRUCT STATE
          ----
   Create resources for
     the play state.
         --]]--

local st = RunState.new()

local GameCam = getClass 'wyx.view.GameCam'
local TileMapView = getClass 'wyx.view.TileMapView'

local math_floor = math.floor


function st:init() end

function st:enter(prevState, world, viewstate)
	self._world = world
	self._viewstate = viewstate
	self._loadStep = 0
	self._doLoadStep = true
end

function st:leave()
	self._doLoadStep = nil
	self._loadStep = nil
	self._world = nil
	self._viewstate = nil
	if Console then Console:hide() end
end

function st:destroy()
	self._view:destroy()
	self._view = nil
	self._cam:destroy()
	self._cam = nil
end

function st:_generateWorld()
	self._world:generate()
	local place = self._world:getCurrentPlace()
	self._level = place:getCurrentLevel()
end

function st:_createMapView()
	if self._view then self._view:destroy() end

	self._view = TileMapView(self._level, self._viewstate)
	self._view:registerEvents()
end

function st:_createCamera()
	local mapW, mapH = self._level:getMapSize()
	local tileW, tileH = self._view:getTileSize()
	local mapTileW, mapTileH = mapW * tileW, mapH * tileH
	local startX = math_floor(mapW/2+0.5) * tileW - math_floor(tileW/2)
	local startY = math_floor(mapH/2+0.5) * tileH - math_floor(tileH/2)

	if not self._cam then
		self._cam = GameCam(startX, startY, zoom)
	else
		self._cam:setHome(startX, startY)
	end

	local minX, minY = math_floor(tileW/2), math_floor(tileH/2)
	local maxX, maxY = mapTileW - minX, mapTileH - minY
	self._cam:setLimits(minX, minY, maxX, maxY)
	self._cam:home()
	self._cam:followTarget(self._level:getPrimeEntity())
	self._view:setViewport(self._cam:getViewport())
end

function st:_nextLoadStep()
	if nil ~= self._doLoadStep then self._doLoadStep = true end
	if nil ~= self._loadStep then self._loadStep = self._loadStep + 1 end
end

function st:_load()
	self._doLoadStep = false

	-- load entities
	switch(self._loadStep) {
		[1] = function() self:_generateWorld() end,
		[2] = function() CollisionSystem:setLevel(self._level) end,
		[3] = function() self._level:setPlayerControlled() end,
		[4] = function() self:_createMapView() end,
		[5] = function() self:_createCamera() end,
		[6] = function()
			RunState.switch(State.play, self._world, self._view, self._cam)
		end,
		default = function() end,
	}

	cron.after(LOAD_DELAY, self._nextLoadStep, self)
end

function st:update(dt)
	if self._doLoadStep then self:_load() end
end

function st:draw()
	if Console then Console:draw() end
end


return st
