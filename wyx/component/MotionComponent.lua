local Class = require 'lib.hump.class'
local ModelComponent = getClass 'wyx.component.ModelComponent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'
local EntityPositionEvent = getClass 'wyx.event.EntityPositionEvent'

local GameEvents = GameEvents

-- MotionComponent
--
local MotionComponent = Class{name='MotionComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {
			'Position',
			'CanMove',
			'IsContained',
			'IsAttached',
		})
		ModelComponent.construct(self, properties)
		self:_addMessages(
			'SET_POSITION',
			'CONTAINER_INSERTED',
			'CONTAINER_REMOVED',
			'ATTACHMENT_ATTACHED',
			'ATTACHMENT_DETACHED')
	end
}

-- destructor
function MotionComponent:destroy()
	ModelComponent.destroy(self)
end

function MotionComponent:_setProperty(prop, data, ...)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if prop == property('Position') then
		if type(data) == 'number' then
			local x, y = data, select(1,...)
			data = {x, y}
		end

		verifyAny(data, 'expression', 'table')

		if type(data) == 'table' then
			assert(#data == 2, 'Invalid Position: %s', tostring(data))
			verify('number', data[1], data[2])
		end
	elseif prop == property('CanMove')
		or   prop == property('IsContained')
		or   prop == property('IsAttached')
	then
		verifyAny(data, 'boolean', 'expression')
	else
		error('MotionComponent does not support property: %s', tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function MotionComponent:_move(posX, posY, oldposX, oldposY)
	self:_setProperty(property('Position'), posX, posY)
	self._mediator:send(message('HAS_MOVED'), posX, posY, oldposX, oldposY)
	GameEvents:notify(
		EntityPositionEvent(self._mediator, posX, posY, oldposX, oldposY)
	)
end

function MotionComponent:receive(sender, msg, ...)
	local doSetPosition = false

	if     msg == message('SET_POSITION') then self:_move(...)

	elseif msg == message('CONTAINER_INSERTED')
		and sender == self._mediator
	then self:_setProperty(property('IsContained'), true)

	elseif msg == message('CONTAINER_REMOVED')
		and sender == self._mediator
	then
		self:_setProperty(property('IsContained'), false)
		doSetPosition = true

	elseif msg == message('ATTACHMENT_ATTACHED')
		and sender == self._mediator
	then self:_setProperty(property('IsAttached'), true)

	elseif msg == message('ATTACHMENT_DETACHED')
		and sender == self._mediator
	then
		self:_setProperty(property('IsAttached'), false)
		doSetPosition = true
	end

	if doSetPosition then
		local comp = select(1, ...)
		local mediator = comp:getMediator()
		local pPosition = property('Position')
		local mpos = mediator:query(pPosition)
		local pos = self._mediator:query(pPosition)

		self._mediator:send(message('SET_POSITION'),
			mpos[1], mpos[2], pos[1], pos[2])
	end
end

function MotionComponent:getProperty(p, intermediate, ...)
	if   p == property('CanMove')
		or p == property('IsContained')
		or p == property('IsAttached')
	then
		local prop = self:_evaluate(p)
		if nil == intermediate then return prop end
		return (prop or intermediate)
	elseif p == property('Position') then
		local prop = self:_evaluate(p)
		if nil == intermediate then return prop end
		intermediate[1] = intermediate[1] + prop[1]
		intermediate[2] = intermediate[2] + prop[2]
		return intermediate
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return MotionComponent
