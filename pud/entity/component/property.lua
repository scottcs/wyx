local property = {}

-- check if a given property is valid
local isproperty = function(prop) return property[prop] ~= nil end

-- get a property from the property table
local get = function(prop)
	assert(isproperty(prop), 'invalid component property: %s', prop)
	return property[prop]
end

---------------------------
-- the actual properties --
---------------------------

-- status properties
property.Flammable         = 'Flammable'
property.Fragile           = 'Fragile'

-- bonus properties
property.AttackBonus       = 'AttackBonus'
property.DefenseBonus      = 'DefenseBonus'
property.SpeedBonus        = 'SpeedBonus'
property.HealthBonus       = 'HealthBonus'

-- the structure of valid property
return setmetatable({isproperty = isproperty},
	{__call = function(_, prop) return get(prop) end})
