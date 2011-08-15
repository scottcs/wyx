local Class = require 'lib.hump.class'
local Component = getClass 'pud.component.Component'
local ListenerBag = getClass 'pud.kit.ListenerBag'
local property = require 'pud.component.property'
local message = require 'pud.component.message'
local queryFunc = require 'pud.component.queryFunc'

-- ComponentMediator
--
local ComponentMediator = Class{name='ComponentMediator',
	function(self)
		self._listeners = {}
	end
}

-- destructor
function ComponentMediator:destroy()
	for k in pairs(self._listeners) do
		self._listeners[k]:destroy()
		self._listeners[k] = nil
	end
	self._listeners = nil
end

-- send a message to all attached components
function ComponentMediator:send(msg, ...)
	if self._listeners[msg] then
		for comp in self._listeners[msg]:listeners() do
			--if debug then print(comp,message(msg)) end
			comp:receive(message(msg), ...)
		end
	end
end

-- attach a component to the given message
-- (component will receive this message)
function ComponentMediator:attach(msg, comp)
	self._listeners[msg] = self._listeners[msg] or ListenerBag()
	self._listeners[msg]:push(comp)
end

-- detach a component from the given message
-- (component will no longer receive this message)
function ComponentMediator:detach(msg, comp)
	if self._listeners[msg] then self._listeners[msg]:pop(comp) end
end

-- query all components for a property, collect their responses, then feed the
-- responses to the given function and return the result. by default, the
-- 'sum' function is used.
function ComponentMediator:query(prop, func)
	prop = property(prop)
	func = func or queryFunc.sum
	if type(func) == 'string' then func = queryFunc[func] end
	verify('function', func)
	
	local values = {}
	local numValues = 1
	for k in pairs(self._components) do
		local v = self._components[k]:getProperty(prop)
		if v ~= nil then
			values[numValues] = v
			numValues = numValues+1
		end
	end
	return #values > 0 and func(values) or nil
end


-- the class
return ComponentMediator
