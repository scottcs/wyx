local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'

-- Button
-- a clickable Frame
local Button = Class{name='Button',
	inherits=Text,
	function(self, ...)
		Text.construct(self, ...)
		self._callbacks = {}
		self._callbackArgs = {}
		self:setJustifyCenter()
		self:setAlignCenter()
	end
}

-- destructor
function Button:destroy()
	for k in pairs(self._callbacks) do self:_clearCallback(k) end
	self._callbacks = nil
	self._callbackArgs = nil
	Text.destroy(self)
end

-- override Frame onRelease
function Button:onRelease(button, mods)
	if self._pressed then
		if self._callbacks[button] then
			local args = self._callbackArgs[button]
			if args then
				self._callbacks[button](mods, unpack(args))
			else
				self._callbacks[button](mods)
			end
		end
	end
end

-- clear the given callback
function Button:_clearCallback(button)
	self._callbacks[button] = nil
	if self._callbackArgs[button] then
		for k,v in self._callbackArgs[button] do
			self._callbackArgs[button][k] = nil
		end
		self._callbackArgs[button] = nil
	end
end

-- set the callback function and arguments
-- this will be called when the button is pressed
function Button:setCallback(button, func, ...)
	verify('string', button)
	verify('function', func)
	self:_clearCallback(button)

	self._callbacks[button] = func

	local numArgs = select('#', ...)
	if numArgs > 0 then self._callbackArgs[button] = {...} end
end


-- the class
return Button
