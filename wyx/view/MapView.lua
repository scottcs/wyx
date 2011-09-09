
local Class = require 'lib.hump.class'

-- MapView
-- prototype class for other level view classes
local MapView = Class{name='MapView',
	function(self)
	end
}

-- destructor
function MapView:destroy()
end

-- draw the level
function MapView:draw() end

-- register events
function MapView:registerEvents() end

-- handle events
function MapView:onEvent(e, ...) end

-- serialize
function MapView:getState() end
function MapView:setState(state) end

-- the class
return MapView
