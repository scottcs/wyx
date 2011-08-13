local Class = require 'lib.hump.class'
local ComponentMediator = getClass 'pud.component.ComponentMediator'


-- Entity
--
local _id = 0
local Entity = Class{name = 'Entity',
	inherits=ComponentMediator,
	function(self, entityType, name, components)
		ComponentMediator.construct(self)
		_id = _id + 1
		self._id = _id

		verify('string', name, entityType)
		self._name = name
		self._type = entityType
		self._components = {}

		if components ~= nil then
			verify('table', components)
			verifyClass('pud.component.Component', unpack(components))

			for _,comp in components do
				self._components[tostring(comp.__class)] = comp
			end
		end
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
-- class can be a parent component class or derived component class.
function Entity:getComponentsByClass(class)
	local components = {}
	for _,comp in pairs(self._components) do
		if isClass(class, comp) then components[#components+1] = comp end
	end
	return #components > 0 and components or nil
end

local _getComponentName = function(component)
	verifyClass('pud.component.Component', component)
	return tostring(component.__class)
end

-- add a component to the entity
function Entity:addComponent(component)
	local name = _getComponentName(component)
	self:removeComponent(name)
	self._components[name] = component
end

-- remove a component from the entity
function Entity:removeComponent(component)
	local name
	if type(component) == 'string' then
		name = component
	else
		name = _getComponentName(component)
	end

	if name and self._components[name] then
		self._components[name]:destroy()
		self._components[name] = nil
	end
end


-- the class
return Entity
