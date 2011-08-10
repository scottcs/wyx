local Class = require 'lib.hump.class'
local EntityView = getClass 'pud.view.EntityView'

-- HeroView
--
local HeroView = Class{name='HeroView',
	inherits=EntityView,
	function(self, hero, width, height)
		EntityView.construct(self, hero, width, height)
	end
}

-- destructor
function HeroView:destroy()
	EntityView.destroy(self)
end


-- the class
return HeroView
