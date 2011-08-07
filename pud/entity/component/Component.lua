local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'

-- Component
--
local Component = Class{name='Component',
	function(self, newProperties)
		self._properties = {}

		if newProperties ~= nil then
			verify('table', newProperties)
			for p in pairs(newProperties) do
				self._properties[property(p)] = newProperties[p]
			end
		end
	end
}

-- destructor
function Component:destroy()
	for k in pairs(self._properties) do self._properties[k] = nil end
	self._properties = nil
end

-- update
function Component:update(entity, level, view) end

-- receive a message
-- precondition: msg is a valid component message
function Component:receive(msg, ...) end

-- return the given property if we have it, or nil if we do not
-- precondition: p is a valid component property
function Component:getProperty(p) return self._properties[p] end

-- the class
return Component
