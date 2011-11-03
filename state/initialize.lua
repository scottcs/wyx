
         --[[--
    INITIALIZE STATE
          ----
   Initialize resources
   needed for the game.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.initialize' end}
setmetatable(st, mt)

local maxn = table.maxn

function st:init()
	-- entity databases
	HeroDB = getClass('wyx.entity.HeroEntityDB')()
	EnemyDB = getClass('wyx.entity.EnemyEntityDB')()
	ItemDB = getClass('wyx.entity.ItemEntityDB')()

	-- create systems
	RenderSystem = getClass('wyx.system.RenderSystem')()
	TimeSystem = getClass('wyx.system.TimeSystem')()
	CollisionSystem = getClass('wyx.system.CollisionSystem')()

	-- instantiate world
	World = getClass('wyx.map.World')()
end

function st:enter(prevState, ...)
	if Console then Console:show() end
	self._nextStates = {...}
	self._loadStep = 0
	self._doLoadStep = true
end

function st:leave()
	if self._nextStates then
		for k in pairs(self._nextStates) do 
			self._nextStates[k] = nil
		end
		self._nextStates = nil
	end

	self._doLoadStep = nil
	self._loadStep = nil
end

function st:destroy()
	World:destroy()

	EntityRegistry = nil

	-- destroy systems
	RenderSystem:destroy()
	TimeSystem:destroy()
	CollisionSystem:destroy()
	RenderSystem = nil
	TimeSystem = nil
	CollisionSystem = nil

	-- destroy entity databases
	HeroDB:destroy()
	EnemyDB:destroy()
	ItemDB:destroy()
	HeroDB = nil
	EnemyDB = nil
	ItemDB = nil
end

function st:_makeEntityRegistry()
	-- TODO: make this not global
	EntityRegistry = World:getEntityRegistry()
end

-- make a ridiculous seed for the PRNG
function st:_makeGameSeed()
	local time = os.time()
	local ltime = math.floor(love.timer.getTime() * 10000000)
	local mtime = math.floor(love.timer.getMicroTime() * 1000)
	local mx = love.mouse.getX()
	local my = love.mouse.getY()
	if time < ltime then time, ltime = ltime, time end
	GAMESEED = (time - ltime) + mtime + mx + my
	math.randomseed(GAMESEED) math.random() math.random() math.random()
	local rand = math.floor(math.random() * 10000000)
	GAMESEED = GAMESEED + rand

	-- create the real global PRNG instance with this ridiculous seed
	Random = random.new(GAMESEED)
end

function st:_nextLoadStep()
	if nil ~= self._doLoadStep then self._doLoadStep = true end
	if nil ~= self._loadStep then self._loadStep = self._loadStep + 1 end
end

function st:_load()
	self._doLoadStep = false

	-- load entities
	switch(self._loadStep) {
		[1] = function() self:_makeGameSeed() end,
		[2] = function() self:_makeEntityRegistry() end,
		[3] = function() HeroDB:load() end,
		[4] = function() EnemyDB:load() end,
		[5] = function() ItemDB:load() end,
		[6] = function()
			local states = self._nextStates
			if states then
				local nextState = states[1]
				if #states > 1 then
					RunState.switch(State[nextState], unpack(states, 2, maxn(states)))
				else
					RunState.switch(State[nextState])
				end
			end
		end,
		default = function() end,
	}

	cron.after(LOAD_DELAY, self._nextLoadStep, self)
end

function st:update(dt)
	if self._doLoadStep then self:_load() end
end

function st:draw() end

function st:keypressed(key, unicode) end

return st
