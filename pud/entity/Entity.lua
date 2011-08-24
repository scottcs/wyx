local Class = require 'lib.hump.class'
local ComponentMediator = getClass 'pud.component.ComponentMediator'
local property = require 'pud.component.property'

local verify, verifyClass, isClass = verify, verifyClass, isClass
local type, pairs, tostring = type, pairs, tostring

-- Entity
--
local _id = 0
local Entity = Class{name = 'Entity',
	inherits=ComponentMediator,
	function(self, etype, info, components)
		ComponentMediator.construct(self)
		_id = _id + 1
		self._id = _id

		verify('string', etype)
		verify('table', info)

		self._name = info.name
		self._etype = etype
		self._family = info.family
		self._kind = info.kind
		self._variation = info.variation
		self._elevel = info.elevel
		self._components = {}
		self._componentCache = setmetatable({}, {__mode = 'kv'})

		if components ~= nil then
			for _,comp in pairs(components) do
				self:addComponent(comp)
			end
		end
	end
}

-- destructor
function Entity:destroy()
	self._id = nil
	self._name = nil

	self:_clearComponentCache()
	self._componentCache = nil

	for k in pairs(self._components) do
		self._components[k]:destroy()
		self._components[k] = nil
	end
	self._components = nil

	ComponentMediator.destroy(self)
end

function Entity:getID() return self._id end
function Entity:getName() return self._name end
function Entity:getEntityType() return self._etype end
function Entity:getFamily() return self._family end
function Entity:getKind() return self._kind end
function Entity:getVariation() return self._variation end
function Entity:getELevel() return self._elevel end

function Entity:_clearComponentCache()
	for k in pairs(self._componentCache) do self._componentCache[k] = nil end
end

-- return a list of all components of the given type.
-- class can be a parent component class or derived component class.
function Entity:getComponentsByClass(class)
	local components = self._componentCache[class]

	if nil == components then
		components = {}
		local count = 1
		for _,comp in pairs(self._components) do
			if isClass(class, comp) then
				components[count] = comp
				count = count + 1
			end
		end
		if #components == 0 then components = false end
		self._componentCache[class] = components
	end

	return components ~= false and components or nil
end

local _getComponentName = function(component)
	verifyClass('pud.component.Component', component)
	return tostring(component.__class or component)
end

-- add a component to the entity
function Entity:addComponent(component)
	local name = _getComponentName(component)
	self:removeComponent(name)
	component:setMediator(self)
	component:attachMessages()
	self._components[name] = component

	self:_clearComponentCache()
end

-- remove a component from the entity
function Entity:removeComponent(component)
	local name
	if type(component) == 'string' then
		name = component
	else
		-- an actual class, check for component child or self
		for k,v in pairs(self._components) do
			if v == component or v:is_a(component) then
				name = _getComponentName(component)
				break
			end
		end
	end

	if name and self._components[name] then
		self._components[name]:destroy()
		self._components[name] = nil
	end

	self:_clearComponentCache()
end

-- query all components for a property, passing the intermediate result each
-- time, to allow the component to modify the result as it sees fit.
function Entity:query(prop, ...)
	local result
	for k in pairs(self._components) do
		result = self._components[k]:getProperty(prop, result, ...)
	end
	return result
end

function Entity:rawquery(prop, intermediate, ...)
	for k in pairs(self._components) do
		intermediate = self._components[k]:getProperty(prop, intermediate, ...)
	end
	return intermediate
end



-- the class
return Entity
