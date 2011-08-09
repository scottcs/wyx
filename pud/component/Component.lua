local Class = require 'lib.hump.class'
local ComponentMediator = require 'pud.component.ComponentMediator'
local property = require 'pud.component.property'

-- Component
--
local Component = Class{name='Component',
	function(self, newProperties)
		self._properties = {}

		if newProperties ~= nil then
			verify('table', newProperties)
			for p in pairs(newProperties) do
				self:_addProperty(p, newProperties[p])
			end
		end
	end
}

-- destructor
function Component:destroy()
	for k in pairs(self._properties) do self._properties[k] = nil end
	self._properties = nil
	if self._attachMessages then
		for _,msg in pairs(self._attachMessages) do
			self._mediator:detach(message(msg), self)
		end
		self._attachMessages = nil
	end
	self._mediator = nil
end

-- set the mediator who owns this component
function Component:setMediator(mediator)
	verifyClass(ComponentMediator, mediator)
	self._mediator = mediator
end

-- attach all of this component's messages to its mediator
function Component:attachMessages()
	for _,msg in pairs(_attachMessages) do
		self._mediator:attach(message(msg), self)
	end
end

-- add a new property to this component
function Component:_addProperty(prop, data)
	self._properties[property(prop)] = data
end

-- update
function Component:update(level, view) end

-- receive a message
-- precondition: msg is a valid component message
function Component:receive(msg, ...) end

-- return the given property if we have it, or nil if we do not
-- precondition: p is a valid component property
function Component:getProperty(p) return self._properties[p] end

-- attach this component to the messages it wants to receive
function Component:attachMessages() end


-- the class
return Component
