local Class = require 'lib.hump.class'
local InputEvent = getClass 'wyx.event.InputEvent'

local string_char = string.char

-- KeyboardEvent
--
local KeyboardEvent = Class{name='KeyboardEvent',
	inherits=InputEvent,
	function(self, key, scancode, isrepeat, modifiers)
		InputEvent.construct(self, 'Keyboard Event', modifiers)
		self._key = key
		self._scancode = scancode
    self._isrepeat = isrepeat
	end
}

-- destructor
function KeyboardEvent:destroy()
	self._key = nil
	self._scancode = nil
	InputEvent.destroy(self)
end

-- get the key pressed
function KeyboardEvent:getKey() return self._key end

-- get the scancode value of the key pressed as a string
function KeyboardEvent:getScancode()
	return self._scancode
end

-- get the repeat value
function KeyboardEvent:getIsRepeat()
	return self._isrepeat
end

function KeyboardEvent:__tostring()
	local modstr = self:_getModString()
	local scancode = self:getScancode()
	return self:_msg('k: %s, s: %s, m: {%s}',
		tostring(self._key), scancode, modstr)
end


-- the class
return KeyboardEvent
