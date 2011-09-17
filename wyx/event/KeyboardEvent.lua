local Class = require 'lib.hump.class'
local InputEvent = getClass 'wyx.event.InputEvent'

local string_char = string.char

-- KeyboardEvent
--
local KeyboardEvent = Class{name='KeyboardEvent',
	inherits=InputEvent,
	function(self, key, unicode, modifiers)
		InputEvent.construct(self, 'Keyboard Event', modifiers)
		self._key = key
		self._unicode = unicode
	end
}

-- destructor
function KeyboardEvent:destroy()
	self._key = nil
	self._unicode = nil
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
		c = string_char(self._unicode)
	end
	return c
end

function KeyboardEvent:__tostring()
	local modstr = self:_getModString()
	local unicode = tostring(self:getUnicode())
	return self:_msg('k: %s, u: %s, v: %s, m: {%s}',
		tostring(self._key), unicode, tostring(self._unicode), modstr)
end


-- the class
return KeyboardEvent
