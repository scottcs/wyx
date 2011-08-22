local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'
local EntityPositionEvent = getClass 'pud.event.EntityPositionEvent'

local GameEvents = GameEvents

-- MotionComponent
--
local MotionComponent = Class{name='MotionComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {'Position', 'CanMove'})
		ModelComponent.construct(self, properties)
		self:_addMessages('SET_POSITION')
	end
}

-- destructor
function MotionComponent:destroy()
	ModelComponent.destroy(self)
end

function MotionComponent:_setProperty(prop, data, ...)
	prop = property(prop)
	if nil == data then data = property.default(prop) end

	if prop == property('Position') then
		if type(data) == 'number' then
			local x, y = data, select(1,...)
			data = {x, y}
		end
		assert(#data == 2, 'Invalid Position: %s', tostring(data))
		verify('number', data[1], data[2])
	elseif prop == property('CanMove') then
		verify('boolean', data)
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

function MotionComponent:receive(msg, ...)
	if     msg == message('SET_POSITION') then self:_move(...)
	end
end

function MotionComponent:getProperty(p, intermediate, ...)
	if p == property('CanMove') then
		local prop = self._properties[p]
		if nil == intermediate then return prop end
		print(prop or intermediate)
		return (prop or intermediate)
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return MotionComponent
