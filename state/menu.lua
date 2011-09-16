
         --[[--
     MAIN MENU STATE
          ----
  Display the main menu.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.menu' end}
setmetatable(st, mt)

local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local MenuUI = getClass 'wyx.ui.MenuUI'

function st:init()
	-- create global UI system
	UISystem = UISystem or getClass('wyx.system.UISystem')()
end

function st:enter(prevState, nextState, ...)
	if nil ~= nextState then
		RunState.switch(State[nextState], ...)
	else
		InputEvents:register(self, InputCommandEvent)
		self._ui = MenuUI(UI.MainMenu)
	end
end

function st:leave()
	InputEvents:unregisterAll(self)
	if self._ui then
		self._ui:destroy()
		self._ui = nil
	end
end

function st:destroy()
	UISystem:destroy()
	UISystem = nil
end

function st:update(dt)
	UISystem:update(dt)
end

function st:draw()
	UISystem:draw()
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
			QUIT_NOSAVE = function() RunState.switch(State.shutdown) end,
			NEW_GAME = function()
				RunState.switch(State.initialize, 'construct')
			end,
			MENU_LOAD_GAME = function()
				RunState.switch(State.initialize, 'loadgame')
			end,
			MENU_OPTIONS = function()
				--RunState.switch(State.options, 'menu')
				print('Options')
			end,
			MENU_HELP = function()
				--RunState.switch(State.help, 'menu')
				print('Help')
			end,
		}
	end
end


return st
