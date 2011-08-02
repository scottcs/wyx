local Class = require 'lib.hump.class'

-- Traveler
local Traveler = Class{name='Traveler',
	function(self)
	end
}

-- destructor
function Traveler:destroy()
end

function Traveler:canMove(node) return node:isAccessible() end

-- the class
return Traveler
