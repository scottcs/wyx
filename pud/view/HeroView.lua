local Class = require 'lib.hump.class'
local EntityView = require 'pud.view.EntityView'

-- HeroView
--
local HeroView = Class{name='HeroView',
	inherits=EntityView,
	function(self)
		EntityView.construct(self)
	end
}

-- destructor
function HeroView:destroy()
	EntityView.destroy(self)
end


-- the class
return HeroView
