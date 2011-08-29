local Class = require 'lib.hump.class'
local Place = getClass 'pud.map.Place'
local Level = getClass 'pud.map.Level'

-- Dungeon
--
local Dungeon = Class{name='Dungeon',
	inherits=Place,
	function(self, name)
		Place.construct(self, name)
	end
}

-- destructor
function Dungeon:destroy()
	Place.destroy(self)
end

-- generate the given level of the dungeon
function Dungeon:generateLevel(which)
	verifyAny(which, 'number', 'string')

	local level = Level()

	local how = {
		'generateSimpleGridMap',
		'generateFileMap',
	}

	local numHow = #how

	-- randomly pick a method of generating the level
	level[how[Random(numHow)]](level)

	self:setLevel(which, level)
end


-- the class
return Dungeon
