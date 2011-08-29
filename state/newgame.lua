
         --[[--
      NEWGAME STATE
          ----
   Construct everything
  needed for a new game.
         --]]--

local st = RunState.new()

local Dungeon = getClass 'pud.map.Dungeon'

function st:init() end

function st:enter(prevState, world)
	print('newgame')

	self._world = world
	self._loadStep = 0
	self._doLoadStep = true
end

function st:leave()
	self._world = nil
	self._loadStep = nil
	self._doLoadStep = nil
end

function st:destroy() end

function st:_generateDungeon()
	local dungeon = Dungeon('Lonely Dungeon')
	self._world:addPlace(dungeon)
end

function st:_generateLevel()
	local dungeon = self._world:getCurrentPlace()
	dungeon:generateLevel(1)
end

function st:_nextLoadStep()
	if nil ~= self._doLoadStep then self._doLoadStep = true end
	if nil ~= self._loadStep then self._loadStep = self._loadStep + 1 end
end

function st:_load()
	self._doLoadStep = false

	-- load entities
	switch(self._loadStep) {
		[1] = function() self:_generateDungeon() end,
		[2] = function() self:_generateLevel() end,
		[3] = function() RunState.switch(State.construct, self._world) end,
		default = function() end,
	}

	cron.after(.1, self._nextLoadStep, self)
end

function st:update(dt)
	if self._doLoadStep then self:_load() end
end

function st:draw()
	if Console then Console:draw() end
end

function st:keypressed(key, unicode) end

return st
