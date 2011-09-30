
         --[[--
    CREATECHAR STATE
          ----
Create the player character.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.createchar' end}
setmetatable(st, mt)

local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local CreateCharUI = getClass 'wyx.ui.CreateCharUI'

function st:init() end

function st:enter(prevState)
	self._prevState = self._prevState or prevState
	InputEvents:register(self, InputCommandEvent)
	if Console then Console:hide() end
	self._ui = CreateCharUI(UI.CreateChar)
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
	--local args = e:getCommandArgs()

	switch(cmd) {
		-- run state
		EXIT_MENU = function()
			if State.initialize.destroy then State.initialize:destroy() end
			rawset(State, 'initialize', nil)
			RunState.switch(State.menu)
		end,
		CREATE_CHAR = function()
			if self._ui then
				local char = self._ui:getChar()
				if char then
					World:createHero(char)
					RunState.switch(State.construct)
				end
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
