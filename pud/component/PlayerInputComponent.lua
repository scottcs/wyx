local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local InputComponent = getClass 'pud.component.InputComponent'
local KeyboardEvent = getClass 'pud.event.KeyboardEvent'

-- PlayerInputComponent
--
local PlayerInputComponent = Class{name='PlayerInputComponent',
	inherits=InputComponent,
	function(self, properties)
		self._requiredProperties = {
		}
		InputComponent.construct(self, properties)
		InputEvents:register(self, KeyboardEvent)
	end
}

-- destructor
function PlayerInputComponent:destroy()
	InputEvents:unregisterAll(self)
	InputComponent.destroy(self)
end

-- on keyboard input, issue the appropriate command
function PlayerInputComponent:KeyboardEvent(e)
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
return PlayerInputComponent
