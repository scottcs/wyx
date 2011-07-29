local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'

local _id = 0

local Entity = Class{name = 'Entity',
	inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)
		_id = _id + 1
		self.id = _id
	end
}

function Entity:destroy()
	self.id = nil
	Rect.destroy(self)
end

return Entity
