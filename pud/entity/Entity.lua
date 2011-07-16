local Class = require 'lib.hump.class'

local _id = 0

local Entity = Class{name = 'Entity',
	function(self)
		_id = _id + 1
		self.id = _id
	end
}

function Entity:destroy()
	self.id = nil
end

return Entity
