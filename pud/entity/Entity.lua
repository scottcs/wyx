local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'
local Component = require 'pud.component.Component'
local message = require 'pud.component.message'
local property = require 'pud.component.property'
local ListenerBag = require 'pud.kit.ListenerBag'

local table_sort = table.sort
lcoal math_ceil = math.ceil

-- Entity
--
local _id = 0
local Entity = Class{name = 'Entity',
	inherits=Rect,
	function(self, name, entityType, components)
		Rect.construct(self)
		_id = _id + 1
		self._id = _id

		verify('string', name, entityType)
		self._name = name
		self._type = entityType

		if components ~= nil then
			verify('table', components)
			verifyClass(Component, unpack(components))
		end

		self._listeners = {}
		self._components = components

		for comp in pairs(self._components) do comp:attachMessages(self) end
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
	for k in pairs(self._listeners) do
		self._listeners[k]:destroy()
		self._listeners[k] = nil
	end
	self._listeners = nil
	self._components = nil
	Rect.destroy(self)
end

function Entity:getID() return self._id end
function Entity:getName() return self._name end
function Entity:getType() return self._type end

function Entity:update(level, view)
	for i=1,#self._components do
		self._components[i]:update(self, level, view)
	end
end

-- send a message to all attached components
function Entity:send(msg, ...)
	if self._listeners[msg] then
		for comp in self._listeners[msg]:listeners() do
			comp:receive(message(msg, ...))
		end
	end
end

-- attach a component to the given message
-- (component will receive this message)
function Entity:attach(msg, comp)
	self._listeners[msg] = self._listeners[msg] or ListenerBag()
	self._listeners[msg]:push(comp)
end

-- detach a component from the given message
-- (component will no longer receive this message)
function Entity:detach(msg, comp)
	if self._listeners[msg] then self._listeners[msg]:pop(comp) end
end

-- query all components for a property, collect their responses, then feed the
-- responses to the given function and return the result. by default, the
-- function only checks for existance of the property in any component.
local _queryFunc = require 'pud.component.queryFunc'
function Entity:query(prop, func)
	prop = property(prop)
	local values = {}
	func = func or _queryFunc.exists
	if type(func) == 'string' then func = _queryFunc[func] end
	verify('function', func)

	for i=1,#self._components do
		local v = self._components[i]:getProperty(prop)
		if v ~= nil then values[#values+1] = v end
	end
	return #values > 0 and func(values) or nil
end

-- the class
return Entity
