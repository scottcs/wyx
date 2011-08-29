
         --[[--
    INITIALIZE STATE
          ----
   Initialize resources
   needed for the game.
         --]]--

local st = RunState.new()

function st:init()
	-- entity databases
	HeroDB = getClass('pud.entity.HeroEntityDB')()
	EnemyDB = getClass('pud.entity.EnemyEntityDB')()
	ItemDB = getClass('pud.entity.ItemEntityDB')()
end

function st:enter(prevState, nextState)
	print('initialize')
	if Console then Console:show() end
	self._nextState = nextState
	self._loadStep = 0
	self._doLoadStep = true
end

function st:leave()
	self._doLoadStep = nil
	self._loadStep = nil
end

function st:destroy()
	-- destroy entity databases
	HeroDB:destroy()
	EnemyDB:destroy()
	ItemDB:destroy()
	HeroDB = nil
	EnemyDB = nil
	ItemDB = nil
end

function st:_nextLoadStep()
	if nil ~= self._doLoadStep then self._doLoadStep = true end
	if nil ~= self._loadStep then self._loadStep = self._loadStep + 1 end
end

function st:_load()
	self._doLoadStep = false

	-- load entities
	switch(self._loadStep) {
		[1] = function() HeroDB:load() end,
		[2] = function() EnemyDB:load() end,
		[3] = function() ItemDB:load() end,
		[4] = function() RunState.switch(self._nextState) end,
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
