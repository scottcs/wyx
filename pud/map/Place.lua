local Class = require 'lib.hump.class'
local Level = getClass 'pud.map.Level'

-- Place
--
local Place = Class{name='Place',
	function(self, name)
		self._levels = {}

		name = name or 'noname' -- TODO: generate name from algorithm
		self:setName(name)
	end
}

-- destructor
function Place:destroy()
	for k in pairs(self._levels) do
		self._levels[k]:destroy()
		self._levels[k] = nil
	end
	self._levels = nil
	self._curLevel = nil
end

-- get/set the name of the dungeon
function Place:getName() return self._name end
function Place:setName(name)
	verify('string', name)
	self._name = name
end

-- get a level
function Place:getLevel(which) return self._levels[which] end

-- set a level
function Place:setLevel(which, level)
	verifyAny(which, 'number', 'string')
	verifyClass(Level, level)

	self._levels[which] = level
	self._curLevel = self._curLevel or which
end

-- get the current level
function Place:getCurrentLevel() return self._levels[self._curLevel] end

-- set the current level
function Place:setCurrentLevel(which)
	verifyAny(which, 'number', 'string')
	assert(self._levels[which], 'No such level: %s', tostring(which))

	self._curLevel = which
end

-- get the state of this place
function Place:getState()
	local mt = {__mode = 'kv'}
	local state = setmetatable({}, mt)
	state.levels = setmetatable({}, mt)

	state.curLevel = self._curLevel
	state.name = self._name
	
	for which, level in pairs(self._levels) do
		state.levels[which] = level:getState()
	end

	return state
end

-- set the state of this place
function Place:setState()
end


-- the class
return Place
