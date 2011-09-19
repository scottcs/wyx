
         --[[--
     PLAY MENU STATE
          ----
  Display the play menu.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.playmenu' end}
setmetatable(st, mt)

local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local MenuUI = getClass 'wyx.ui.MenuUI'

function st:init() end

function st:enter(prevState, world, view)
	InputEvents:register(self, InputCommandEvent)
	self._ui = MenuUI(UI.PlayMenu)
	self._world = world
	self._view = view
end

function st:leave()
	InputEvents:unregisterAll(self)
	self._world = nil
	self._view = nil
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
		EXIT_MENU = function()
			RunState.switch(State.play)
		end,
		DELETE_GAME = function()
			local file = self._world.FILENAME
			local wyx = self._world.WYXNAME

			if file then
				if not love.filesystem.remove(file) then
					warning('Could not remove file: %q', file)
				end
			end

			if wyx then
				if not love.filesystem.remove(wyx) then
					warning('Could not remove file: %q', wyx)
				end
			end

			RunState.switch(State.destroy)
		end,
		MENU_MAIN = function()
			--RunState.switch(State.save, self._world, self._view, 'destroy')
			RunState.switch(State.destroy)
		end,
		MENU_SAVE_GAME = function()
			RunState.switch(State.save, self._world, self._view, 'play')
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
