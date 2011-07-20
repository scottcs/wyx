-- table of valid map types
local mt = {
	__index = function(t, k)
		k = k or 'nil'
		error('invalid map type ['..k..']')
	end,
	__newindex = function(t, k, v)
		error('attempt to add maptype '..k..' at runtime')
	end,
}

local MapType = {
	empty = ' ',
	wall = '#',
	floor = '.',
	doorC = '+',
	doorO = '-',
	stairU = '<',
	stairD = '>',
}

-- add glyph as index to itself
-- for ease of use in conditions
local t = {}
for k,v in pairs(MapType) do t[v] = v end
for k,v in pairs(t) do MapType[k] = v end

return setmetatable(MapType, mt)
