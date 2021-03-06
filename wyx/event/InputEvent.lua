local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

local concat = table.concat

-- InputEvent
--
local InputEvent = Class{name='InputEvent',
	inherits=Event,
	function(self, name, modifiers)
		name = name or 'Input Event'
		Event.construct(self, name)
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

function InputEvent:_getModString()
	local modstr = ''

	if self._modifiers then
		local mods = {}
		local count = 0
		for k in pairs(self._modifiers) do
			count = count + 1
			mods[count] = k
		end
		modstr = concat(mods, ', ')
	end

	return modstr
end

function InputEvent:__tostring()
	local modstr = self:_getModString()
	return self:_msg('%s', modstr)
end


-- the class
return InputEvent
