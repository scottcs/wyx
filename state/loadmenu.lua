
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

function st:update(dt) end

function st:draw() end

function st:InputCommandEvent(e)
	local cmd = e:getCommand()
	--local args = e:getCommandArgs()

	switch(cmd) {
		-- run state
		EXIT_MENU = function()
			if State.initialize.destroy then State.initialize:destroy() end
			rawset(State, 'initialize', nil)
			RunState.switch(State.menu)
		end,
		DELETE_GAME = function()
			if self._ui then
				local file, wyx = self._ui:getSelectedFile()

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
			end
		end,
		LOAD_GAME = function()
			if self._ui then
				local file, wyx = self._ui:getSelectedFile()
				if file then
					self._world.FILENAME = file
					self._world.WYXNAME = wyx
					RunState.switch(State.loadgame, self._world)
				end
			end
		end,
	}
end


return st
