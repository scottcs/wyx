local Class = require 'lib.hump.class'
local ListenerBag = getClass 'wyx.kit.ListenerBag'
local message = require 'wyx.component.message'

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
	self:rawsend(self, msg, ...)
end

function ComponentMediator:rawsend(sender, msg, ...)
	msg = message(msg)
	if self._listeners[msg] then
		for comp in self._listeners[msg]:listeners() do
			--if debug then print(comp,msg) end
			comp:receive(sender, msg, ...)
		end
	end
	if self._listeners.ALL then
		for comp in self._listeners.ALL:listeners() do
			--if debug then print(comp,msg) end
			comp:receive(sender, msg, ...)
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


-- the class
return ComponentMediator
