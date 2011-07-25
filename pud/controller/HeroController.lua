local Class = require 'lib.hump.class'
local Controller = require 'pud.controller.Controller'
local vector = require 'lib.hump.vector'

local MoveCommand = require 'pud.event.MoveCommand'

-- HeroController
-- controls the hero of the game
local HeroController = Class{name='HeroController',
	inherits=Controller,
	function(self)
		Controller.construct(self)
	end
}

-- destructor
function HeroController:destroy()
	Controller.destroy(self)
end

-- the class
return HeroController
