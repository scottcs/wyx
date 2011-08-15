local Class = require 'lib.hump.class'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- Component
--
local Component = Class{name='Component',
	function(self, newProperties)
		self._properties = {}
		self:_createProperties(newProperties)
	end
}

-- destructor
function Component:destroy()
	for k in pairs(self._properties) do self._properties[k] = nil end
	self._properties = nil
	if self._attachMessages then
		self:detachMessages()
		self._attachMessages = nil
	end
	self._mediator = nil
end

-- add properties to the list of required properties (to be called by child
-- classes)
function Component:_addRequiredProperties(properties)
	self._requiredProperties = self._requiredProperties or {}
	local num = #properties
	for i=1,num do
		self._requiredProperties[property(properties[i])] = true
	end
end

-- create properties from the given table, add default values if needed
function Component:_createProperties(newProperties)
	if newProperties ~= nil then
		verify('table', newProperties)
		for p in pairs(newProperties) do
			self:_setProperty(p, newProperties[p])
		end
	end

	-- add missing defaults
	for p in pairs(self._requiredProperties) do
		if not self._properties[p] then self:_setProperty(p) end
	end
end

-- set/get the mediator who owns this component
function Component:setMediator(mediator)
	verifyClass('pud.component.ComponentMediator', mediator)
	self._mediator = mediator
end
function Component:getMediator() return self._mediator end

-- attach all of this component's messages to its mediator
function Component:attachMessages()
	if self._attachMessages then
		for _,msg in pairs(self._attachMessages) do
			self._mediator:attach(message(msg), self)
		end
	end
end

-- detach all of this component's messages to its mediator
function Component:detachMessages()
	if self._attachMessages then
		for _,msg in pairs(self._attachMessages) do
			self._mediator:detach(message(msg), self)
		end
	end
end

-- set a property for this component
function Component:_setProperty(prop, data)
	if data == nil then data = property.default(prop) end
	self._properties[property(prop)] = data
end

-- receive a message
-- precondition: msg is a valid component message
function Component:receive(msg, ...) end

-- return the given property if we have it, or nil if we do not
-- precondition: p is a valid component property
function Component:getProperty(p) return self._properties[p] end


-- the class
return Component
