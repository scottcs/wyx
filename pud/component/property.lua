local property = {}

-- check if a given property is valid
local isproperty = function(prop) return property[prop] ~= nil end

-- get a property from the property table
local get = function(prop)
	assert(isproperty(prop), 'invalid component property: %s', prop)
	return property[prop]
end

-------------------------------------------------
-- the actual properties and sensible defaults --
-------------------------------------------------

-- combat properties
property.Attack            = 1
property.Defense           = 1
property.AttackBonus       = 0
property.DefenseBonus      = 0

-- health properties
property.Health            = 1
property.MaxHealth         = 1
property.HealthBonus       = 0
property.MaxHealthBonus    = 0

-- collision properties
property.Position          = {x=1, y=1}

-- graphics properties
property.TileSet           = 'dungeon'
property.TileCoords        = {x=1, y=1}
property.TileSize          = 32
property.Visibility        = 6

-- time properties
property.DefaultCost       = 1
property.AttackCost        = 1
property.MoveCost          = 1
property.Speed             = 1
property.SpeedBonus        = 0

-- weaknesses
property.CrushWeakness     = 0
property.SliceWeakness     = 0
property.StabWeakness      = 0
property.FireWeakness      = 0

-- resistances
property.CrushResistance   = 0
property.SliceResistance   = 0
property.StabResistance    = 0
property.FireResistance    = 0

-- status effects
property.Combustable       = false


-- check for mistakes when this file is loaded
for p in pairs(property) do
	assert(property[p] == p, 'Property mismatch: %s ~= %s', property[p], p)
end

-- the structure of valid property
return setmetatable({isproperty = isproperty},
	{__call = function(_, prop) return get(prop) end})
