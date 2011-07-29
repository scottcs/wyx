local Class = require 'lib.hump.class'
local HeroController = require 'pud.controller.HeroController'

-- HeroPlayerController
--
local HeroPlayerController = Class{name='HeroPlayerController',
	inherits=HeroController,
	function(self)
		HeroController.construct(self)
		InputEvents:registerAll(self)
	end
}

-- destructor
function HeroPlayerController:destroy()
		InputEvents:unregisterAll(self)
		HeroController.destroy(self)
end


-- the class
return HeroPlayerController
