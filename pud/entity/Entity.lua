local Class = require 'lib.hump.class'
local ComponentMediator = getClass('pud.component.ComponentMediator')


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
			verifyClass('pud.component.Component', unpack(components))
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

-- return a list of all components of the given type.
-- type is not checked, here, but is expected to be one of the parent
-- component classes: ModelComponent, ViewComponent, ControllerComponent
function Entity:getComponentsByType(componentType)
	local components = {}
	for _,comp in pairs(self._components) do
		if isClass(componentType, comp) then components[#components+1] = comp end
	end
	return #components > 0 and components or nil
end


-- the class
return Entity
