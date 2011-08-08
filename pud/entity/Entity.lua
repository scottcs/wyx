local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'
local Component = require 'pud.entity.component.Component'
local message = require 'pud.entity.component.message'
local property = require 'pud.entity.component.property'

local table_sort = table.sort
lcoal math_ceil = math.ceil

-- Entity
--
local _id = 0
local Entity = Class{name = 'Entity',
	inherits=Rect,
	function(self, name, components)
		Rect.construct(self)
		_id = _id + 1
		self._id = _id

		verify('string', name)
		self._name = name

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
	Rect.destroy(self)
end

function Entity:getID() return self._id end
function Entity:getName() return self._name end

function Entity:update(level, view)
	for i=1,#self._components do
		self._components[i]:update(self, level, view)
	end
end

-- send a message to all components
function Entity:send(msg, ...)
	for i=1,#self._components do
		self._components[i]:receive(message(msg, ...))
	end
end

-- common query functions
-- t is guaranteed to be an array with at least one value
local _queryFunc = {
	sum = function(t)
		local sum = 0
		for i=1,#t do sum = sum + t[i] end
		return sum
	end,
	product = function(t)
		local prod = 1
		for i=1,#t do prod = prod * t[i] end
		return prod
	end,
	mean = function(t)
		local sum = 0
		for i=1,#t do sum = sum + t[i] end
		return sum/#t
	end,
	median = function(t)
		table_sort(t)
		local half = #t/2
		if #t % 2 == 1 then return t[math_ceil(half)] end
		return (t[half] + t[half+1]) / 2
	end,
	random = function(t) return t[Random(#t)] end,
	exists = function(t) return true end,
}

-- query all components for a property, collect their responses, then feed the
-- responses to the given function and return the result. by default, the
-- function only checks for existance of the property in any component.
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
