local Class = require 'lib.hump.class'
local Component = require 'pud.component.Component'
local ComponentMediator = require 'pud.component.ComponentMediator'


-- Entity
--
local _id = 0
local Entity = Class{name = 'Entity',
	inherits=ComponentMediator,
	function(self, name, entityType, components)
		ComponentMediator.construct(self)
		_id = _id + 1
		self._id = _id

		verify('string', name, entityType)
		self._name = name
		self._type = entityType

		if components ~= nil then
			verify('table', components)
			verifyClass(Component, unpack(components))
		end

		self._components = components
	end
}

-- destructor
function Entity:destroy()
	self._id = nil
	self._name = nil
	for k in pairs(self._components) do
		self._components[k]:destroy()
		self._components[k] = nil
	end
	self._components = nil
	ComponentMediator.destroy(self)
end

function Entity:getID() return self._id end
function Entity:getName() return self._name end
function Entity:getType() return self._type end


-- the class
return Entity
