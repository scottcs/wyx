local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local EntityArray = getClass 'pud.entity.EntityArray'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- AttachmentComponent
--
local AttachmentComponent = Class{name='AttachmentComponent',
	inherits=ModelComponent,
	function(self, properties, family, max)
		max = max or 1
		verify('number', max)
		verify('string', family)

		ModelComponent._addRequiredProperties(self, {'AttachedEntities'})
		ModelComponent.construct(self, properties)
		self:_addMessages(message('ALL'))

		self._entities = EntityArray()
		self._max = max
		self._family = family
	end
}

-- destructor
function AttachmentComponent:destroy()
	self._entities:destroy()
	self._entities = nil
	ModelComponent.destroy(self)
end

function AttachmentComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if prop == property('AttachedEntities') then
		verify('table', data)
	else
		error('AttachmentComponent does not support property: %s', tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function AttachmentComponent:receive(msg, ...)
	local continue = false

	if     msg == message('ATTACHMENT_ATTACH') then
		self:_attach(...)
		continue = false
	elseif msg == message('ATTACHMENT_DETACH') then
		self:_detach(...)
		continue = false
	end

	if continue then
		for id in self._entities:iterate() do
			local entity = EntityRegistry:get(id)
			entity:send(msg, ...)
		end
	end
end

function AttachmentComponent:_attach(...)
	local num = select('#', ...)
	if num > 0 then
		local msg = message('ATTACHMENT_ATTACHED')
		local size = self._entities:size()
		local max = self._max - size
		local loop = max > num and num or max

		for i=1,loop do
			local id = select(i, ...)
			local entity = EntityRegistry:get(id)
			local efamily = entity:getFamily()
			if efamily == self._family then
				if self._entities:add(id) then
					entity:send(msg, self)
				end
			end
		end
	end
end

function AttachmentComponent:_detach(...)
	local num = select('#', ...)
	if num > 0 then
		local msg = message('ATTACHMENT_DETACHED')

		for i=1,num do
			local id = select(i, ...)
			if self._entities:remove(id) then
				local entity = EntityRegistry:get(id)
				entity:send(msg, self)
			end
		end
	end
end

-- XXX I hate this.
-- Need a better way to separate properties that should be queried on attached
-- entities vs. properties that should not.
local _queriable = {
	AttackBonus = true,
	DefenseBonus = true,
	DamageBonus = true,
	HealthBonus = true,
	MaxHealthBonus = true,
	SpeedBonus = true,
	VisibilityBonus = true,
	CanMove = true,
	BlockedBy = true,
	CanOpenDoors = true,
	DefaultCost = true,
	AttackCost = true,
	MoveCost = true,
	WaitCost = true,
}


function AttachmentComponent:getProperty(p, intermediate, ...)
	if _queriable[p] then
		for id in self._entities:iterate() do
			local entity = EntityRegistry:get(id)
			intermediate = entity:rawquery(p, intermediate, ...)
		end
	end

	if p == property('AttachedEntities') then
		if self._entities:size() == 0 then return intermediate end

		local entities = intermediate or {}
		local num = #entities

		for id in self._entities:iterate() do
			num = num + 1
			entities[num] = id
		end

		return entities
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return AttachmentComponent
