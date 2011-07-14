local MapNode = require 'pud.level.MapNode'

-- Map
local Map = Class{name='Map',
	function(self)
		self._layout = {}
	end
}

-- destructor
function Map:destroy()
end

-- the class
return Map
