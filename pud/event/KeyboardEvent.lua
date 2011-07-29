local Class = require 'lib.hump.class'
local InputEvent = require 'pud.event.InputEvent'

local string_char = string.char

-- KeyboardEvent
--
local KeyboardEvent = Class{name='KeyboardEvent',
	inherits=InputEvent,
	function(self, key, unicode, modifiers)
		InputEvent.construct(self, modifiers)
		self._key = key
		self._unicode = unicode
	end
}

-- destructor
function KeyboardEvent:destroy()
	InputEvent.destroy(self)
end

-- get the key pressed
function KeyboardEvent:getKey() return self._key end

-- get the unicode value of the key pressed
function KeyboardEvent:getUnicodeValue() return self._unicode end

-- get the unicode value of the key pressed as a string
function KeyboardEvent:getUnicode()
	local c = nil
	if self._unicode and self._unicode ~= 0 and self._unicode < 1000 then
		c = string_char(unicode)
	end
	return c
end

-- the class
return KeyboardEvent
