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

function AttachmentComponent:receive(sender, msg, ...)
	local continue = false

	if     msg == message('ENTITIES_LOADED') then
		local attachedProp = property('AttachedEntities')
		if self._properties
			and self._properties[attachedProp]
		then
			local attached = self._properties[attachedProp]
			self._properties[attachedProp] = nil
			self:_attach(unpack(attached))
		end
	elseif msg == message('ATTACHMENT_ATTACH') then
		self:_attach(...)
		continue = false
	elseif msg == message('ATTACHMENT_DETACH') then
		self:_detach(...)
		continue = false
	end

	if continue then
		for id in self._entities:iterate() do
			local entity = EntityRegistry:get(id)
			if entity then
				entity:rawsend(sender, msg, ...)
			else
				warning('AttachmentComponent (recv): entity does not exist %q', id)
			end
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
			id = EntityRegistry:getValidID(id)
			if id then
				local entity = EntityRegistry:get(id)
				local efamily = entity:getFamily()
				if efamily == self._family then
					if self._entities:add(id) then
						entity:send(msg, self)
					end
				end
			else
				warning('Invalid id %q when attaching.', id)
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
	DefaultCostBonus = true,
	AttackCostBonus = true,
	MoveCostBonus = true,
}


function AttachmentComponent:getProperty(p, intermediate, ...)
	if _queriable[p] then
		for id in self._entities:iterate() do
			local entity = EntityRegistry:get(id)
			if entity then
				intermediate = entity:rawquery(p, intermediate, ...)
			else
				warning('AttachmentComponent (getP): entity does not exist %q', id)
			end
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

-- override the default getState to deal with contained entities
function AttachmentComponent:getState()
	local mt = {__mode = 'kv'}
	local state = setmetatable({}, mt)

	for k,v in pairs(self._properties) do
		state[k] = v
	end
	state.AttachedEntities = self._entities:getArray()

	return state
end


-- the class
return AttachmentComponent
