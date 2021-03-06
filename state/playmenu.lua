
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

function st:enter(prevState, view)
	InputEvents:register(self, InputCommandEvent)
	self._prevState = self._prevState or prevState
	self._ui = MenuUI(UI.PlayMenu)
	self._view = view
end

function st:leave()
	InputEvents:unregisterAll(self)
	self._view = nil
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
	--local args = e:getCommandArgs()

	switch(cmd) {
		-- run state
		EXIT_MENU = function()
			RunState.switch(State.play)
		end,
		default = function()
			if self._prevState and self._prevState.InputCommandEvent then
				self._prevState:InputCommandEvent(e)
			end
		end,
	}
end


return st
