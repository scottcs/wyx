local property = {}

-- check if a given property is valid
local isproperty = function(prop) return property[prop] ~= nil end

-- get a valid property name
local get = function(prop)
	assert(isproperty(prop), 'invalid component property: %s', prop)
	return prop
end

-- get a property's default value
local default = function(prop)
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

-- motion properties
property.Position          = {x=1, y=1}

-- collision properties
property.BlockedBy         = {Wall='ALL', Door='shut'}
property.CanMove           = true

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


-- the structure of valid property
return setmetatable({isproperty=isproperty, default=default},
	{__call = function(_, prop) return get(prop) end})
