local Class = require 'lib.hump.class'
local Component = require 'pud.entity.component.Component'

-- ModelComponent
--
local ModelComponent = Class{name='ModelComponent',
	inherits=Component,
	function(self, newProperties)
		Component.construct(self, newProperties)
	end
}

-- destructor
function ModelComponent:destroy()
	Component.destroy(self)
end


-- the class
return ModelComponent
