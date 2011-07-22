
local Class = require 'lib.hump.class'

-- LevelView
-- prototype class for other level view classes
local LevelView = Class{name='LevelView',
	function(self)
	end
}

-- destructor
function LevelView:destroy()
end

-- draw the level
function LevelView:draw() end

-- register events
function LevelView:registerEvents() end

-- handle events
function LevelView:onEvent(e, ...) end

-- the class
return LevelView
