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
		ModelComponent._addRequiredProperties(self, {
			'BlockedBy',
			'CanMove',
		})
		ModelComponent.construct(self, properties)
		self:_addMessages(
			'COLLIDE_ENEMY',
			'COLLIDE_HERO',
			'COLLIDE_BLOCKED',
			'COLLIDE_NONE'
		)
	end
}

-- destructor
function CollisionComponent:destroy()
	ModelComponent.destroy(self)
end

function CollisionComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == data then data = property.default(prop) end

	if prop == property('BlockedBy') then
		verify('table', data)
	elseif prop == property('CanMove') then
		verify('boolean', data)
	else
		error('CollisionComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function CollisionComponent:receive(msg, ...)
	if     msg == message('COLLIDE_ENEMY') then
		self:_setProperty(property('CanMove'), false)
	elseif msg == message('COLLIDE_HERO') then
		self:_setProperty(property('CanMove'), false)
	elseif msg == message('COLLIDE_BLOCKED') then
		self:_setProperty(property('CanMove'), false)
	elseif msg == message('COLLIDE_NONE') then
		self:_setProperty(property('CanMove'), true)
	end
end

function CollisionComponent:getProperty(p, intermediate, ...)
	if p == property('BlockedBy') then
		local node = select(1, ...)
		if node then
			local mapType = node:getMapType()
			local mt = match(tostring(mapType.__class), '^(%w+)MapType')
			local v = mapType:getVariant()
			local prop = self._properties[p]
			local blocked = (prop[mt] and (v == prop[mt] or prop[mt] == 'ALL'))
			return (blocked or intermediate)
		else
			return true
		end
	elseif p == property('CanMove') then
		local prop = self._properties[p]
		if nil == intermediate then return prop end
		print(prop or intermediate)
		return (prop or intermediate)
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return CollisionComponent
