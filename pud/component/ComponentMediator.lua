local Class = require 'lib.hump.class'
local Component = require 'pud.component.Component'
local ListenerBag = require 'pud.kit.ListenerBag'
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
			comp:receive(message(msg, ...))
		end
	end
end

-- ask all of the given components to attach themselves to this
-- ComponentMediator with messages they wish to listen for.
function ComponentMediator:registerComponents(components)
	for _,comp in pairs(components) do comp:attachMessages(self) end
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
-- function only checks for existance of the property in any component.
function ComponentMediator:query(prop, func)
	prop = property(prop)
	local values = {}
	func = func or queryFunc.exists
	if type(func) == 'string' then func = queryFunc[func] end
	verify('function', func)

	for i=1,#self._components do
		local v = self._components[i]:getProperty(prop)
		if v ~= nil then values[#values+1] = v end
	end
	return #values > 0 and func(values) or nil
end


-- the class
return ComponentMediator
