
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

function st:enter(prevState)
	self._prevState = self._prevState or prevState
	InputEvents:register(self, InputCommandEvent)
	if Console then Console:hide() end
	self._ui = LoadMenuUI(UI.LoadMenu)
end

function st:leave()
	InputEvents:unregisterAll(self)
	if self._ui then
		self._ui:destroy()
		self._ui = nil
	end
end

function st:destroy()
	self._prevState = nil
end

function st:update(dt) end

function st:draw() end

function st:InputCommandEvent(e)
	local cmd = e:getCommand()
	local args = e:getCommandArgs()

	switch(cmd) {
		-- run state
		EXIT_MENU = function()
			RunState.switch(State.destroy)
		end,
		DELETE_GAME = function()
			local file, wyx
			if args then
				file, wyx = args[1], args[2]
			elseif self._ui then
				file, wyx = self._ui:getSelectedFile()
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
			elseif self._ui then
				file, wyx = self._ui:getSelectedFile()
			end

			if file and wyx then
				World.FILENAME = file
				World.WYXNAME = wyx
				RunState.switch(State.loadgame)
			end
		end,
		default = function()
			if self._prevState and self._prevState.InputCommandEvent then
				self._prevState:InputCommandEvent(e)
			end
		end,
	}
end


return st
