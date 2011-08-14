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
		}
		ModelComponent.construct(self, properties)
		self._attachMessages = {'COLLIDE_CHECK'}
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

function CollisionComponent:_collideCheck(level, pos, oldpos)
	local collision = false
	local entities = level:getEntitiesAtLocation(pos)
	if entities then
		for _,otherEntity in pairs(entities) do
			local otherEntityType = otherEntity:getType()
			if otherEntityType == 'enemy' then
				self._mediator:send(message('COLLIDE_ENEMY'), otherEntity)
				collision = true
			elseif otherEntityType == 'hero' then
				self._mediator:sent(message('COLLIDE_HERO'), otherEntity)
				collision = true
			end
		end
	end

	if not collision then
		local node = level:getMapNode(pos)
		local blocked = false
		local mapType = node:getMapType()
		local variant = mapType:getVariant()
		local mt = match(tostring(mapType.__class), '^(%w+)MapType')
		if mt then
			blocked = self._mediator:query(property('BlockedBy'), function(t)
				for _,p in pairs(t) do
					if p[mt] and (variant == p[mt] or p[mt] == 'ALL') then
						return true
					end
				end
				return false
			end)
		end
		if blocked then
			self._mediator:send(message('COLLIDE_BLOCKED'), mapType)
			collision = true
		end
	end

	if not collision then
		self._mediator:send(message('COLLIDE_NONE'), pos, oldpos)
	end
end

function CollisionComponent:receive(msg, ...)
	if     msg == message('COLLIDE_CHECK') then self:_collideCheck(...)
	end
end


-- the class
return CollisionComponent
