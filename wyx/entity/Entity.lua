local Class = require 'lib.hump.class'
local ComponentMediator = getClass 'wyx.component.ComponentMediator'
local property = require 'wyx.component.property'

local verify, verifyClass, isClass = verify, verifyClass, isClass
local type, pairs, tostring = type, pairs, tostring
local match = string.match

-- Entity
--
local Entity = Class{name = 'Entity',
	inherits=ComponentMediator,
	function(self, etype, info, components)
		ComponentMediator.construct(self)
		verify('string', etype)
		verify('table', info)

		self._regkey = info.regkey
		self._unique = info.unique
		self._name = info.name
		self._etype = etype
		self._family = info.family
		self._kind = info.kind
		self._variation = info.variation
		self._description = info.description
		self._components = {}
		self._componentCache = setmetatable({}, {__mode = 'kv'})

		if components ~= nil then
			for _,comp in pairs(components) do
				self:addComponent(comp)
			end
		end

		self:_calculateELevel()
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

-- get/set the ID of this entity
function Entity:getID() return self._id end
function Entity:setID(id) self._id = id end

function Entity:getRegKey() return self._regkey end
function Entity:getName() return self._name end
function Entity:getEntityType() return self._etype end
function Entity:getFamily() return self._family end
function Entity:getKind() return self._kind end
function Entity:getVariation() return self._variation end
function Entity:getELevel() return self._elevel end
function Entity:getDescription() return self._description end
function Entity:isUnique() return self._unique == true end

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
	verifyClass('wyx.component.Component', component)
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
	self:_calculateELevel()
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
	self:_calculateELevel()
end

-- calculate this entity's EntityLevel
function Entity:_calculateELevel()
	self._elevel = 0

	for k,comp in pairs(self._components) do
		self._elevel = self._elevel + comp:getELevel()
	end
end

-- override some ComponentMediator methods to ensure ELevel is always up to
-- date.
function Entity:rawsend(...)
	ComponentMediator.rawsend(self, ...)
	self:_calculateELevel()
end

-- query all components for a property, passing the intermediate result each
-- time, to allow the component to modify the result as it sees fit.
function Entity:query(prop, ...)
	return self:rawquery(prop, nil, ...)
end

function Entity:rawquery(prop, intermediate, ...)
	for k,comp in pairs(self._components) do
		intermediate = comp:getProperty(prop, intermediate, ...)
	end
	return intermediate
end

-- functions to save and restore state
-- getState returns a table with key/value pairs representing state data
function Entity:getState()
	local state = {}

	state.name = self._name
	state.regkey = self._regkey
	state.etype = self._etype
	state.unique = self._unique
	state.family = self._family
	state.kind = self._kind
	state.variation = self._variation
	state.elevel = self._elevel
	state.description = self._description
	state.components = {}

	if self._components then
		for name,comp in pairs(self._components) do
			state.components[name] = comp:getState()
		end
	end

	return state
end


-- the class
return Entity
