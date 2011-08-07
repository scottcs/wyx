local property = {}

-- check if a given property is valid
local isproperty = function(prop) return property[prop] ~= nil end

-- get a property from the property table
local get = function(prop)
	assert(isproperty(prop), 'invalid component property: %s', prop)
	return property[prop]
end

-- the actual properties
property.FLAMMABLE = 'FLAMMABLE'

-- the structure of valid property
return setmetatable({isproperty = isproperty},
	{__call = function(_, prop) return get(prop) end})
