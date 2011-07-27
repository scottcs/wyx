local Class = require 'lib.hump.class'
local EntityView = require 'pud.view.EntityView'

-- HeroView
--
local HeroView = Class{name='HeroView',
	inherits=EntityView,
	function(self)
	end
}

-- destructor
function HeroView:destroy()
end


-- the class
return HeroView
