local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'

-- Button
-- a clickable Frame
local Button = Class{name='Button',
	inherits=Text,
	function(self, ...)
		Text.construct(self, ...)
		self:setJustifyCenter()
		self:setAlignCenter()
	end
}

-- destructor
function Button:destroy()
	Text.destroy(self)
end

-- override Frame onRelease
function Button:onRelease(button, mods)
  if self._pressed then self:_callCallback(button, mods) end
end


-- the class
return Button
