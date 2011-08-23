local property = {}

-- check if a given property is valid
local isproperty = function(prop) return property[prop] ~= nil end

-- get a valid property name
local getcache = {}
local get = function(prop)
	local ret = getcache[prop]

	if ret == nil then
		assert(isproperty(prop), 'invalid component property: %s', prop)
		ret = prop
		getcache[prop] = ret
	end

	return ret
end

-- get a property's default value
local defaultcache = setmetatable({}, {__mode = 'v'})
local default = function(prop)
	local ret = defaultcache[prop]

	if ret == nil then
		assert(isproperty(prop), 'invalid component property: %s', prop)
		ret = property[prop]
		defaultcache[prop] = ret
	end

	return ret
end

-------------------------------------------------
-- the actual properties and sensible defaults --
-------------------------------------------------

-- combat properties
property.Attack            = 0
property.Defense           = 0
property.AttackBonus       = 0
property.DefenseBonus      = 0

-- health properties
property.Health            = 0
property.MaxHealth         = 0
property.HealthBonus       = 0
property.MaxHealthBonus    = 0

-- motion properties
property.Position          = {1, 1}
property.CanMove           = true

-- collision properties
property.BlockedBy         = {Wall='ALL', Door='shut'}

-- graphics properties
property.TileSet           = 'dungeon'
property.TileCoords        = {front = {1, 1}}
property.TileSize          = 32
property.Visibility        = 0

-- controller properties
property.CanOpenDoors      = false

-- time properties
property.DefaultCost       = 0
property.AttackCost        = 0
property.MoveCost          = 0
property.WaitCost          = 0
property.Speed             = 0
property.SpeedBonus        = 0
property.IsExhausted       = false
property.DoTick            = true

-- container properties
property.MaxContainerSize  = 0

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
