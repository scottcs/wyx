local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local EntityArray = getClass 'pud.entity.EntityArray'
local message = require 'pud.component.message'
local property = require 'pud.component.property'

-- ContainerComponent
--
local ContainerComponent = Class{name='ContainerComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {
			'MaxContainerSize',
			'ContainedEntities',
		})
		ModelComponent.construct(self, properties)
		self:_addMessages(message('ALL'))

		self._entities = EntityArray()
	end
}

-- destructor
function ContainerComponent:destroy()
	self._entities:destroy()
	self._entities = nil
	ModelComponent.destroy(self)
end

function ContainerComponent:_setProperty(prop, data, ...)
	prop = property(prop)
	if nil == data then data = property.default(prop) end

	if prop == property('MaxContainerSize') then
		verify('number', data)
	if prop == property('ContainedEntities') then
		verify('table', data)
	else
		error('ContainerComponent does not support property: %s', tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function ContainerComponent:receive(msg, ...)
	local continue = true

	if     msg == message('CONTAINER_INSERT') then
		self:_insert(...)
		continue = false
	elseif msg == message('CONTAINER_REMOVE') then
		self:_remove(...)
		continue = false
	elseif msg == message('CONTAINER_RESIZE') then
		self:_resize(...)
		continue = false
	end

	if continue then
		for id in self._entities:iterate() do
			local entity = EntityRegistry:get(id)
			entity:send(msg, ...)
		end
	end
end

function ContainerComponent:_insert(...)
	local num = select('#', ...)
	if num > 0 then
		local msg = message('CONTAINER_INSERTED')
		local size = self._entities:size()
		local max = self._mediator:query(property('MaxContainerSize')) - size
		local loop = max > num and num or max

		for i=1,loop do
			local id = select(i, ...)
			if self._entities:add(id) then
				local entity = EntityRegistry:get(id)
				entity:send(msg, self)
			end
		end
	end
end

function ContainerComponent:_remove(...)
	local num = select('#', ...)
	if num > 0 then
		local msg = message('CONTAINER_REMOVED')

		for i=1,num do
			local id = select(i, ...)
			if self._entities:remove(id) then
				local entity = EntityRegistry:get(id)
				entity:send(msg, self)
			end
		end
	end
end

function ContainerComponent:_resize(size)
	self:_setProperty(property('MaxContainerSize'), size)
end

function ContainerComponent:getProperty(p, intermediate, ...)
	if p == property('ContainedEntities') then
		if intermediate then return intermediate end
		return self._entities:getArray()
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return ContainerComponent
