
         --[[--
     LOADGAME STATE
          ----
    Load and construct
    everything needed
    to continue a game.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.loadgame' end}
setmetatable(st, mt)

require 'lib.serialize'
local warning, tostring = warning, tostring

function st:init() end

function st:enter(prevState, world)
	self._world = world
	self._loadStep = 0

	local filename = world.FILENAME

	if filename and love.filesystem.exists(filename) then
		self._filename = filename
		self._doLoadStep = true
		if Console then
			Console:show()
			Console:print('Loading savegame: %q', self._filename)
		end
	else
		RunState.switch(State.menu)
	end
end

function st:leave()
	if self._file then self._file:close() end
	self._state = nil
	self._world = nil
	self._file = nil
	self._filename = nil
	self._loadStep = nil
	self._doLoadStep = nil
end

function st:destroy() end

function st:_loadFile()
	local contents = love.filesystem.read(self._filename)
	local ok, err = pcall(loadstring,contents)
	if ok then
		ok, err = pcall(err)
		if ok then
			self._state = err

			if self._state.GAMESEED then
				GAMESEED = self._state.GAMESEED
				Random = random.new(GAMESEED)
			end
		end
	end

	if not ok then
		err = err or ''
		warning(err..' (Game not loaded)')
	end
end

function st:_setWorldState()
	if self._state then
		self._world:setState(self._state)
	end
end

function st:_nextLoadStep()
	if nil ~= self._doLoadStep then self._doLoadStep = true end
	if nil ~= self._loadStep then self._loadStep = self._loadStep + 1 end
end

function st:_load()
	self._doLoadStep = false

	-- load entities
	switch(self._loadStep) {
		[1] = function() self:_loadFile() end,
		[2] = function() self:_setWorldState() end,
		[3] = function()
			local viewstate = self._state and self._state.view
			RunState.switch(State.construct, self._world, viewstate)
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
