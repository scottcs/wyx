local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local HeroController = getClass('pud.controller.HeroController')

-- events this controller listens for
local KeyboardEvent = getClass('pud.event.KeyboardEvent')

-- HeroPlayerController
--
local HeroPlayerController = Class{name='HeroPlayerController',
	inherits=HeroController,
	function(self, hero)
		HeroController.construct(self, hero)
		InputEvents:register(self, KeyboardEvent)
	end
}

-- destructor
function HeroPlayerController:destroy()
		InputEvents:unregisterAll(self)
		HeroController.destroy(self)
end

-- on keyboard input, issue the appropriate command
function HeroPlayerController:KeyboardEvent(e)
	if #(e:getModifiers()) == 0 then
		local key = e:getKey()
		switch(key) {
			up    = function() self:move(vector( 0, -1)) end,
			down  = function() self:move(vector( 0,  1)) end,
			left  = function() self:move(vector(-1,  0)) end,
			right = function() self:move(vector( 1,  0)) end,
		}
	end
end


-- the class
return HeroPlayerController
