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

-- stat properties
property.Attack            = 'Attack'
property.Defense           = 'Defense'
property.Speed             = 'Speed'
property.Health            = 'Health'
property.MaxHealth         = 'MaxHealth'

-- bonus properties
property.AttackBonus       = 'AttackBonus'
property.DefenseBonus      = 'DefenseBonus'
property.SpeedBonus        = 'SpeedBonus'
property.HealthBonus       = 'HealthBonus'
property.MaxHealthBonus    = 'MaxHealthBonus'

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

-- graphics properties
property.TileSet           = 'TileSet'
property.TileCoords        = 'TileCoords'
property.TileStepSize      = 'TileStepSize'
property.Visibility        = 'Visibility'

-- time properties
property.Default           = 'DefaultCost'
property.AttackCost        = 'AttackCost'
property.MoveCost          = 'MoveCost'


-- the structure of valid property
return setmetatable({isproperty = isproperty},
	{__call = function(_, prop) return get(prop) end})
