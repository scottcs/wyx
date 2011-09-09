local Class = require 'lib.hump.class'
local Place = getClass 'wyx.map.Place'
local Level = getClass 'wyx.map.Level'

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

-- regenerate all levels from the saved state
function Dungeon:regenerate()
	if self._loadstate then
		for which,levelState in pairs(self._loadstate.levels) do
			local level = Level()
			level:setState(levelState)
			level:regenerate()
			self:setLevel(which, level)
		end

		self._curLevel = self._loadstate.curLevel

		self._loadstate = nil
	end
end


-- the class
return Dungeon
