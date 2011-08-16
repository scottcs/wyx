local Class = require 'lib.hump.class'
local property = require 'pud.component.property'
local message = require 'pud.component.message'
local vector = require 'lib.hump.vector'

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
		local num = #self._attachMessages
		for i=1,num do
			local msg = message(self._attachMessages[i])
			self._mediator:attach(msg, self)
		end
	end
end

-- detach all of this component's messages to its mediator
function Component:detachMessages()
	if self._attachMessages then
		local num = #self._attachMessages
		for i=1,num do
			local msg = message(self._attachMessages[i])
			self._mediator:detach(msg, self)
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

-- evaluate a string property as if it were lua code
function Component:_evaluate(prop, ...)
	return 1
end

-- return the given property if we have it, or nil if we do not
-- precondition: p is a valid component property
function Component:getProperty(p, intermediate, ...)
	local prop = self._properties[p]
	if nil == prop then return intermediate end
	if nil == intermediate then return prop end

	if type(prop) == 'number' or vector.isvector(prop) then
		return prop + intermediate
	elseif type(prop) == 'boolean' then
		return (prop and intermediate)
	else
		error('Please implement getProperty() for: '..tostring(self.__class))
	end
end


-- the class
return Component
