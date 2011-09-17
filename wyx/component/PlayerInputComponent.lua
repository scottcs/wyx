local Class = require 'lib.hump.class'
local InputComponent = getClass 'wyx.component.InputComponent'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local message = require 'wyx.component.message'
local property = require 'wyx.component.property'
local command = require 'wyx.ui.command'

local InputEvents = InputEvents
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'

-- PlayerInputComponent
--
local PlayerInputComponent = Class{name='PlayerInputComponent',
	inherits=InputComponent,
	function(self, properties)
		InputComponent.construct(self, properties)
		self:_addMessages('TIME_PRETICK')
		InputEvents:register(self, {InputCommandEvent})
	end
}

-- destructor
function PlayerInputComponent:destroy()
	InputEvents:unregisterAll(self)
	InputComponent.destroy(self)
end

function PlayerInputComponent:_setProperty(prop, data)
	if prop == property('CanOpenDoors') then data = true end
	InputComponent._setProperty(self, prop, data)
end

-- on InputCommandEvent, call the correlating function
function PlayerInputComponent:InputCommandEvent(e)
	local cmd = e:getCommand()
	if PAUSED and command.pause(cmd) then return end
	local args = e:getCommandArgs()

	local doTick = true

	switch(cmd) {
		ATTACH_ENTITY = function()
			assert(args and #args == 2,
				'Invalid args for InputCommand ATTACH_ENTITY')
			local id, to = unpack(args)
			if to == self._mediator:getID() then self:_doAttach(id, true) end
		end,

		DETACH_ENTITY = function()
			assert(args and #args == 2,
				'Invalid args for InputCommand DETACH_ENTITY')
			local id, to = unpack(args)
			if to == self._mediator:getID() then self:_doDetach(id, true) end
		end,

		PICKUP_ENTITY = function()
			assert(args and #args == 2,
				'Invalid args for InputCommand PICKUP_ENTITY')
			local id, to = unpack(args)
			if to == self._mediator:getID() then self:_doPickup(id, true) end
		end,

		DROP_ENTITY = function()
			assert(args and #args == 2,
				'Invalid args for InputCommand DROP_ENTITY')
			local id, to = unpack(args)
			if to == self._mediator:getID() then self:_doDrop(id, true) end
		end,

		PRINT_INVENTORY = function() self:_printInventory(); doTick = false end,
		PRINT_STATS = function() self:_printStats(); doTick = false end,

		WAIT = function() self:_wait() end,
		MOVE_N = function() self:_attemptMove( 0, -1) end,
		MOVE_S = function() self:_attemptMove( 0,  1) end,
		MOVE_W = function() self:_attemptMove(-1,  0) end,
		MOVE_E = function() self:_attemptMove( 1,  0) end,
		MOVE_NW = function() self:_attemptMove(-1,  -1) end,
		MOVE_NE = function() self:_attemptMove( 1,  -1) end,
		MOVE_SW = function() self:_attemptMove(-1,   1) end,
		MOVE_SE = function() self:_attemptMove( 1,   1) end,

		default = function() doTick = false end,
	}

	if doTick then self:_setProperty(property('DoTick'), true) end
end

function PlayerInputComponent:receive(sender, msg, ...)
	if msg == message('TIME_PRETICK') and sender == self._mediator then
		self:_setProperty(property('DoTick'), false)
	else
		InputComponent.receive(self, sender, msg, ...)
	end
end


-- the class
return PlayerInputComponent
