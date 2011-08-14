local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'
local match = string.match


-- CollisionComponent
--
local CollisionComponent = Class{name='CollisionComponent',
	inherits=ModelComponent,
	function(self, properties)
		self._requiredProperties = {
			'BlockedBy',
			'CanMove',
		}
		ModelComponent.construct(self, properties)
		self._attachMessages = {
			'COLLIDE_ENEMY',
			'COLLIDE_HERO',
			'COLLIDE_BLOCKED',
			'COLLIDE_NONE'
		}
	end
}

-- destructor
function CollisionComponent:destroy()
	ModelComponent.destroy(self)
end

function CollisionComponent:_setProperty(prop, data)
	prop = property(prop)
	data = data or property.default(prop)

	if prop == property('BlockedBy') then
		verify('table', data)
	else
		error('CollisionComponent does not support property: %s', tostring(prop))
	end

	self._properties[prop] = data
end

function CollisionComponent:receive(msg, ...)
	if     msg == message('COLLIDE_ENEMY') then
		self._properties[property('CanMove')] = false
	elseif msg == message('COLLIDE_HERO') then
		self._properties[property('CanMove')] = false
	elseif msg == message('COLLIDE_BLOCKED') then
		self._properties[property('CanMove')] = false
	elseif msg == message('COLLIDE_NONE') then
		self._properties[property('CanMove')] = true
	end
end


-- the class
return CollisionComponent
