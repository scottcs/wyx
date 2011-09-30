
         --[[--
     CONSTRUCT STATE
          ----
   Create resources for
     the play state.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.construct' end}
setmetatable(st, mt)

local GameCam = getClass 'wyx.view.GameCam'
local TileMapView = getClass 'wyx.view.TileMapView'
local InGameUI = getClass 'wyx.ui.InGameUI'

local math_floor = math.floor


function st:init()
	self._ui = InGameUI()
end

function st:enter(prevState, viewstate)
	self._prevState = prevState
	self._viewstate = viewstate
	self._loadStep = 0
	self._doLoadStep = true
end

function st:leave()
	self._doLoadStep = nil
	self._loadStep = nil
	self._viewstate = nil
	if Console then Console:hide() end
end

function st:destroy()
	self._prevState = nil
	self._view:destroy()
	self._view = nil
	self._cam:destroy()
	self._cam = nil
	self._ui:destroy()
	self._ui = nil
end

function st:InputCommandEvent(e)
	if self._prevState and self._prevState.InputCommandEvent then
		self._prevState:InputCommandEvent(e)
	end
end

function st:_generateWorld()
	World:generate()
	local place = World:getCurrentPlace()
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
		local width, height = self._ui:getGameSize()
		self._cam:setWorldSize(math.floor(width), math.floor(height))
	else
		self._cam:setHome(startX, startY)
	end

	local minX, minY = math_floor(tileW/2), math_floor(tileH/2)
	local maxX, maxY = mapTileW - minX, mapTileH - minY
	self._cam:setLimits(minX, minY, maxX, maxY)
	self._cam:home()
	self._cam:followTarget(World:getPrimeEntity())
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
		[3] = function() self:_createMapView() end,
		[4] = function() self:_createCamera() end,
		[5] = function()
			RunState.switch(State.play, self._view, self._cam)
		end,
		default = function() end,
	}

	cron.after(LOAD_DELAY, self._nextLoadStep, self)
end

function st:update(dt)
	if self._doLoadStep then self:_load() end
end

function st:draw() end


return st
