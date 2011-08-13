local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- MotionComponent
--
local MotionComponent = Class{name='MotionComponent',
	inherits=ModelComponent,
	function(self, properties)
		Component.construct(self, properties)
		self._attachMessages = {'COLLIDE_NONE'}
	end
}

-- destructor
function MotionComponent:destroy()
	Component.destroy(self)
end

function MotionComponent:_setPosition(pos)
	self._entity:setPosition(pos)
	self._entity:send(message('HAS_MOVED'), pos)
end

function MotionComponent:_move(pos)
	local oldpos = self._entity:query(property('Position'))
	self._entity:setPosition(pos)
	self._entity:send(message('HAS_MOVED'), pos, oldpos)
end

function MotionComponent:receive(msg, ...)
	if msg == message('COLLIDE_NONE') then self:_move(...) end
	if msg == message('SET_POSITION') then self:_setPosition(...) end
end


-- the class
return MotionComponent
