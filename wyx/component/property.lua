local property = {}

local warning = warning
local depths = require 'wyx.system.renderDepths'

-- check if a given property is valid
local isproperty = function(prop) return property[prop] ~= nil end

-- get a valid property name
local getcache = {}
local get = function(prop)
	local ret = getcache[prop]

	if ret == nil then
		if not isproperty(prop) then
			warning('invalid component property: %q', prop)
		else
			ret = prop
			getcache[prop] = ret
		end
	end

	return ret
end

-- get a property's default value
local defaultcache = setmetatable({}, {__mode = 'v'})
local default = function(prop)
	local ret = defaultcache[prop]

	if ret == nil then
		if not isproperty(prop) then
			warning('invalid component property: %q', prop)
		else
			local Expression = getClass 'wyx.component.Expression'

			ret = property[prop].default
			if Expression.isExpression(ret) then
				ret = Expression.makeExpression(ret)
			end

			defaultcache[prop] = ret
		end
	end

	return ret
end

-- get a property's ELevel weight
local weightcache = setmetatable({}, {__mode = 'v'})
local weight = function(prop)
	local ret = weightcache[prop]

	if ret == nil then
		if not isproperty(prop) then
			warning('invalid component property: %q', prop)
		else
			ret = property[prop].weight or 0
			weightcache[prop] = ret
		end
	end

	return ret
end


-------------------------------------------------
-- the actual properties and sensible defaults --
-------------------------------------------------

-- combat properties
property.Attack            = {default = 0,
                               weight = 0.6}
property.Defense           = {default = 0,
                               weight = 0.6}
property.Damage            = {default = 0,
                               weight = 0.6}
property.AttackBonus       = {default = 0,
                               weight = 0.9}
property.DefenseBonus      = {default = 0,
                               weight = 0.9}
property.DamageBonus       = {default = 0,
                               weight = 0.9}
property._DamageMin        = {default = 0,
                               weight = 0.0}
property._DamageMax        = {default = 0,
                               weight = 0.0}

-- health properties
property.Health            = {default = '=$MaxHealth',
                               weight = 0.2}
property.MaxHealth         = {default = 0,
                               weight = 0.2}
property.HealthBonus       = {default = 0,
                               weight = 1.1}
property.MaxHealthBonus    = {default = 0,
                               weight = 1.1}

-- motion properties
property.Position          = {default = {1, 1},
                               weight = 0.0}
property.CanMove           = {default = true,
                               weight = 10.0}
property.IsContained       = {default = false,
                               weight = 0.0}
property.IsAttached        = {default = false,
                               weight = 0.0}

-- collision properties
property.BlockedBy         = {default = {Wall='ALL', Door='shut'},
                               weight = 0.0}

-- graphics properties
property.TileSet           = {default = 'dungeon',
                               weight = 0.0}
property.TileCoords        = {default = {front = {1, 1}},
                               weight = 0.0}
property.TileSize          = {default = 32,
                               weight = 0.0}
property.RenderDepth       = {default = depths.game,
                               weight = 0.0}
property.Visibility        = {default = 0,
                               weight = 1.3}
property.VisibilityBonus   = {default = 0,
                               weight = 1.3}

-- controller properties
property.CanOpenDoors      = {default = false,
                               weight = 10.0}

-- time properties
property.DefaultCost       = {default = 0,
                               weight = 0.01}
property.AttackCost        = {default = 100,
                               weight = 0.01}
property.AttackCostBonus   = {default = 0,
                               weight = 0.01}
property.MoveCost          = {default = 100,
                               weight = 0.01}
property.MoveCostBonus     = {default = 0,
                               weight = 0.01}
property.WaitCost          = {default = '!$Speed',
                               weight = 0.01}
property.WaitCostBonus     = {default = 0,
                               weight = 0.01}
property.Speed             = {default = 100,
                               weight = 0.01}
property.SpeedBonus        = {default = 0,
                               weight = 0.01}
property.IsExhausted       = {default = false,
                               weight = 0.0}
property.DoTick            = {default = true,
                               weight = 0.0}

-- container properties
property.MaxContainerSize  = {default = 0,
                               weight = 0.0}
property.ContainedEntities = {default = {},
                               weight = 0.0}

-- attachment properties
property.AttachedEntities  = {default = {},
                               weight = 0.0}


-- the structure of valid property
return setmetatable({isproperty=isproperty, default=default, weight=weight},
	{__call = function(_, prop) return get(prop) end})
