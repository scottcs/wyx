local Class = require 'lib.hump.class'
local Component = require 'pud.entity.component.Component'
local property = require 'pud.entity.component.property'
local vector = require 'lib.hump.vector'

-- GraphicsComponent
--
local GraphicsComponent = Class{name='GraphicsComponent',
	inherits=Component,
	function(self, properties)
		Component.construct(self, properties)
	end
}

-- destructor
function GraphicsComponent:destroy()
	Component.destroy(self)
end

function GraphicsComponent:_addProperty(prop, data)
	prop = property(prop)
	if prop == property('TileSet') then
		verify('string', data)
		assert(Image[data] ~= nil, 'Invalid TileSet: %s', tostring(data))
	elseif prop == property('TileCoords') then
		verify('table', data)
		assert(data.x and data.y, 'Invalid TileCoords: %s', tostring(data))
		verify('number', data.x, data.y)
		data = vector(data.x, data.y)
	elseif prop == property('Visibility') then
		verify('number', data)
	else
		error('GraphicsComponent does not support property: %s', tostring(prop))
	end

	self._properties[prop] = data
end


-- the class
return GraphicsComponent
