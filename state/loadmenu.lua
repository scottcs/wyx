
         --[[--
     LOAD MENU STATE
          ----
  Display the load menu.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.loadmenu' end}
setmetatable(st, mt)

local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local LoadMenuUI = getClass 'wyx.ui.LoadMenuUI'

function st:init() end

function st:enter(prevState, world)
	InputEvents:register(self, InputCommandEvent)
	if Console then Console:hide() end
	self._ui = LoadMenuUI(UI.LoadMenu)
	self._world = world
end

function st:leave()
	InputEvents:unregisterAll(self)
	self._world = nil
	if self._ui then
		self._ui:destroy()
		self._ui = nil
	end
end

function st:destroy() end

function st:update(dt)
	UISystem:update(dt)
end

function st:draw()
	UISystem:draw()
	if Console then Console:draw() end
end

function st:InputCommandEvent(e)
	local cmd = e:getCommand()
	--local args = e:getCommandArgs()

	local continue = false

	-- commands that work regardless of console visibility
	switch(cmd) {
		CONSOLE_TOGGLE = function() Console:toggle() end,
		default = function() continue = true end,
	}

	if not continue then return end

	-- commands that only work when console is visible
	if Console:isVisible() then
		switch(cmd) {
			CONSOLE_HIDE = function() Console:hide() end,
			CONSOLE_PAGEUP = function() Console:pageup() end,
			CONSOLE_PAGEDOWN = function() Console:pagedown() end,
			CONSOLE_TOP = function() Console:top() end,
			CONSOLE_BOTTOM = function() Console:bottom() end,
			CONSOLE_CLEAR = function() Console:clear() end,
		}
	else
		switch(cmd) {
			-- run state
			EXIT_MENU = function()
				RunState.switch(State.menu)
			end,
			LOAD_GAME = function()
				RunState.switch(State.loadgame, self._world, self._filename)
			end,
		}
	end
end


return st
