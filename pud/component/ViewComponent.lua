local Class = require 'lib.hump.class'
local Component = getClass('pud.component.Component')

-- ViewComponent
--
local ViewComponent = Class{name='ViewComponent',
	inherits=Component,
	function(self, newProperties)
		Component.construct(self, newProperties)
	end
}

-- destructor
function ViewComponent:destroy()
	Component.destroy(self)
end

-- draw
function Component:draw() end


-- the class
return ViewComponent
