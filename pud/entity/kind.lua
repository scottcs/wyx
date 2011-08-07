local kind = {}

-- check if a given kind is valid
local iskind = function(k) return kind[k] ~= nil end

-- get a kind from the kind table
local get = function(k)
	assert(iskind(k), 'invalid component kind: %s', k)
	return kind[k]
end

-- the actual kinds
kind.enemy = 'enemy'
kind.hero = 'hero'
kind.item = 'item'

-- the structure of valid kind
return setmetatable({iskind = iskind},
	{__call = function(_, k) return get(k) end})
