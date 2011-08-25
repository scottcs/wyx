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
		ModelComponent._addRequiredProperties(self, {'BlockedBy'})
		ModelComponent.construct(self, properties)
	end
}

-- destructor
function CollisionComponent:destroy()
	ModelComponent.destroy(self)
end

function CollisionComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if prop == property('BlockedBy') then
		verifyAny(data, 'table', 'expression')
	else
		error('CollisionComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function CollisionComponent:getProperty(p, intermediate, ...)
	if p == property('BlockedBy') then
		local node = select(1, ...)
		if node then
			local mapType = node:getMapType()
			local mt = match(tostring(mapType.__class), '^(%w+)MapType')
			local v = mapType:getVariant()
			local prop = self:_evaluate(p)
			local blocked = (prop[mt] and (v == prop[mt] or prop[mt] == 'ALL'))
			return (blocked or intermediate)
		else
			return true
		end
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return CollisionComponent
