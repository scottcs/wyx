local Class = require 'lib.hump.class'
local Controller = require 'pud.controller.Controller'
local vector = require 'lib.hump.vector'

-- events this controller issues
local CommandEvent = require 'pud.event.CommandEvent'

-- commands this controller issues
local MoveCommand = require 'pud.command.MoveCommand'

-- HeroController
-- controls the hero of the game
local HeroController = Class{name='HeroController',
	inherits=Controller,
	function(self, hero)
		Controller.construct(self)
		self._hero = hero
	end
}

-- destructor
function HeroController:destroy()
	self._hero = nil
	self._commandCB = nil
	self._commandCBArgs = nil
	Controller.destroy(self)
end

-- set a callback to call whenever the Hero finishes a command
function HeroController:setCommandCallback(callback, ...)
	verify('function', callback)
	self._commandCB = callback
	self._commandCBArgs = {...}
end

-- issue a MoveCommand to move the hero along vector v
function HeroController:move(v)
	local command = MoveCommand(self._hero, v)
	if self._commandCB then
		command:setOnComplete(self._commandCB, unpack(self._commandCBArgs))
	end
	CommandEvents:push(CommandEvent(command))
end

-- the class
return HeroController
