local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- InputEvent
--
local InputEvent = Class{name='InputEvent',
	inherits=Event,
	function(self, modifiers)
		Event.construct(self)
		self._modifiers = modifiers
	end
}

-- destructor
function InputEvent:destroy()
	for k in pairs(self._modifiers) do self._modifiers[k] = nil end
	self._modifiers = nil
	Event.destroy(self)
end

-- get any modifiers that were pressed
function InputEvent:getModifiers() return self._modifiers end

-- return true if any of the given modifiers were pressed
function InputEvent:wasModifierDown(mod, ...)
	if nil == mod then return false end
	if self._modifiers[mod] then return true end
	return self:wasModifierDown(...)
end

-- the class
return InputEvent
