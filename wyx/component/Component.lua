local Class = require 'lib.hump.class'
local Expression = getClass 'wyx.component.Expression'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

local floor = math.floor

-- Component
--
local Component = Class{name='Component',
	function(self, newProperties)
		self._properties = {}
		self._messages = {}
		self._elevel = 0
		self:_createProperties(newProperties)
		self:_addMessages('ENTITY_CREATED')
	end
}

-- destructor
function Component:destroy()
	for k in pairs(self._properties) do self._properties[k] = nil end
	self._properties = nil

	self:detachMessages()
	for k in pairs(self._messages) do self._messages[k] = nil end
	self._messages = nil

	if self._accessAverages then
		for k in pairs(self._accessAverages) do self._accessAverages[k] = nil end
		self._accessAverages = nil
	end

	self._elevel = nil
	self._entityCreated = nil

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

-- add messages that will be attached
function Component:_addMessages(...)
	local num = select('#', ...)
	for i=1,num do
		local msg = message(select(i, ...))
		self._messages[msg] = true
	end
end

-- set/get the mediator who owns this component
function Component:setMediator(mediator)
	verifyClass('wyx.component.ComponentMediator', mediator)
	self._mediator = mediator
end
function Component:getMediator() return self._mediator end

-- attach all of this component's messages to its mediator
function Component:attachMessages()
	for msg in pairs(self._messages) do
		self._mediator:attach(msg, self)
	end
end

-- detach all of this component's messages to its mediator
function Component:detachMessages()
	for msg in pairs(self._messages) do
		self._mediator:detach(msg, self)
	end
end

-- set a property for this component
function Component:_setProperty(prop, data)
	if data == nil then data = property.default(prop) end
	self._properties[property(prop)] = data
	if self._entityCreated then self:_calculateELevel() end
end

-- receive a message
-- precondition: msg is a valid component message
function Component:receive(sender, msg, ...)
	if msg == message('ENTITY_CREATED') and sender == self._mediator then
		self:_calculateELevel()
		self._entityCreated = true
	end
end

-- evaluate a property and return its value
function Component:_evaluate(p)
	local prop = self._properties[p]

	if prop then
		if Expression.isCreatedExpression(prop) then
			if prop.onAccess then
				prop = prop.onAccess(self._mediator)
			elseif prop.onCreate then
				self._properties[p] = prop.onCreate(self._mediator)
				prop = self._properties[p]
			end
		end
	end

	return prop
end

-- return the given property if we have it, or nil if we do not
-- precondition: p is a valid component property
function Component:getProperty(p, intermediate, ...)
	local prop = self:_evaluate(p)
	if nil == prop then return intermediate end
	if nil == intermediate then return prop end

	if type(prop) == 'number' then
		return prop + intermediate
	elseif type(prop) == 'boolean' then
		return (prop and intermediate)
	else
		error('Please implement getProperty() for: '..tostring(self.__class))
	end
end

-- calculate the ELevel for this component
function Component:_calculateELevel()
	self._elevel = 0

	if self._properties then
		for name,prop in pairs(self._properties) do
			local value = 0

			if type(prop) == 'boolean' then
				value = prop and 1 or 0
			elseif type(prop) == 'number' then
				value = prop
			elseif Expression.isCreatedExpression(prop) then
				if prop.onAccess then
					self._accessAverages = self._accessAverages or {}
					value = self._accessAverages[name]

					if nil == value then
						local sum = 0
						local tries = 30
						for i=1,tries do sum = sum + prop.onAccess(self._mediator) end
						value = sum/tries
						self._accessAverages[name] = value
					end
				elseif prop.onCreate then
					value = self:_evaluate(name)
				else
					warning('getELevel: bad expression %q', tostring(prop))
				end
			end

			self._elevel = self._elevel + (property.weight(name) * value)
		end

		self._elevel = floor(self._elevel + 0.5)
	end
end

-- return the ELevel calculation for this component
function Component:getELevel() return self._elevel end

-- get the current state of the component
function Component:getState()
	local state = {}

	for k,v in pairs(self._properties) do
		state[k] = v
	end

	return state
end


-- the class
return Component
