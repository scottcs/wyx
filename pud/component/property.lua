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

-- combat properties
property.Attack            = 'Attack'
property.Defense           = 'Defense'
property.AttackBonus       = 'AttackBonus'
property.DefenseBonus      = 'DefenseBonus'

-- health properties
property.Health            = 'Health'
property.MaxHealth         = 'MaxHealth'
property.HealthBonus       = 'HealthBonus'
property.MaxHealthBonus    = 'MaxHealthBonus'

-- collision properties
property.Position          = 'Position'

-- graphics properties
property.TileSet           = 'TileSet'
property.TileCoords        = 'TileCoords'
property.TileSize          = 'TileSize'
property.Visibility        = 'Visibility'

-- time properties
property.DefaultCost       = 'DefaultCost'
property.AttackCost        = 'AttackCost'
property.MoveCost          = 'MoveCost'
property.Speed             = 'Speed'
property.SpeedBonus        = 'SpeedBonus'

-- weaknesses
property.CrushWeakness     = 'CrushWeakness'
property.SliceWeakness     = 'SliceWeakness'
property.StabWeakness      = 'StabWeakness'
property.FireWeakness      = 'FireWeakness'

-- resistances
property.CrushResistance   = 'CrushResistance'
property.SliceResistance   = 'SliceResistance'
property.StabResistance    = 'StabResistance'
property.FireResistance    = 'FireResistance'

-- status effects
property.Combustable       = 'Combustable'


-- check for mistakes when this file is loaded
for p in pairs(property) do
	assert(property[p] == p, 'Property mismatch: %s ~= %s', property[p], p)
end

-- the structure of valid property
return setmetatable({isproperty = isproperty},
	{__call = function(_, prop) return get(prop) end})
