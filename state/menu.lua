
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

function st:init() end

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

function st:destroy() end

function st:update(dt) end

function st:draw() end

function st:InputCommandEvent(e)
	local cmd = e:getCommand()
	--local args = e:getCommandArgs()

	switch(cmd) {
		-- run state
		QUIT_NOSAVE = function() RunState.switch(State.shutdown) end,
		NEW_GAME = function()
			RunState.switch(State.initialize, 'construct')
		end,
		MENU_LOAD_GAME = function()
			RunState.switch(State.initialize, 'loadmenu')
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


return st
