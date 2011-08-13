local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'
local vector = require 'lib.hump.vector'


-- MotionComponent
--
local MotionComponent = Class{name='MotionComponent',
	inherits=ModelComponent,
	function(self, properties)
		self._requiredProperties = {
			'Position',
		}
		ModelComponent.construct(self, properties)
		self._attachMessages = {'COLLIDE_NONE', 'SET_POSITION'}
	end
}

-- destructor
function MotionComponent:destroy()
	ModelComponent.destroy(self)
end

function MotionComponent:_setProperty(prop, data)
	prop = property(prop)
	data = data or property.default(prop)

	if prop == property('Position') then
		verify('table', data)
		assert(data.x and data.y, 'Invalid Position: %s', tostring(data))
		verify('number', data.x, data.y)
		data = vector(data.x, data.y)
	else
		error('MotionComponent does not support property: %s', tostring(prop))
	end

	self._properties[prop] = data
end

function MotionComponent:_setPosition(pos)
	self:_setProperty(property('Position'), pos)
	self._mediator:send(message('HAS_MOVED'), pos)
end

function MotionComponent:_move(pos)
	local oldpos = self._mediator:query(property('Position'))
	self:_setProperty(property('Position'), pos)
	self._mediator:send(message('HAS_MOVED'), pos, oldpos)
end

function MotionComponent:receive(msg, ...)
	if msg == message('COLLIDE_NONE') then self:_move(...) end
	if msg == message('SET_POSITION') then self:_setPosition(...) end
end


-- the class
return MotionComponent
