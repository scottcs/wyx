
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
		if Console then Console:hide() end
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
	local args = e:getCommandArgs()

	switch(cmd) {
		-- run state
		QUIT_NOSAVE = function() RunState.switch(State.destroy, 'shutdown') end,
		NEW_GAME = function()
			RunState.switch(State.createchar)
		end,
		MENU_LOAD_GAME = function()
			if self._ui then
				RunState.switch(State.loadmenu)
			else
				RunState.switch(State.destroy, 'initialize', 'menu', 'loadmenu')
			end
		end,
		MENU_OPTIONS = function()
			--RunState.switch(State.options, 'menu')
			print('Options')
		end,
		MENU_HELP = function()
			--RunState.switch(State.help, 'menu')
			print('Help')
		end,
		DELETE_GAME = function()
			local file, wyx
			if args then
				file, wyx = args[1], args[2]
			end

			if file then
				if not love.filesystem.remove(file) then
					warning('Could not remove file: %q', file)
				end
			end

			if wyx then
				if love.filesystem.remove(wyx) then
					self._ui:destroy()
					self._ui = LoadMenuUI(UI.LoadMenu)
				else
					warning('Could not remove file: %q', wyx)
				end
			end
		end,
		LOAD_GAME = function()
			local file, wyx
			if args then
				file, wyx = args[1], args[2]
			end

			if file and wyx then
				World.FILENAME = file
				World.WYXNAME = wyx
				RunState.switch(State.loadgame)
			end
		end,
	}
end


return st
