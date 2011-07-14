-- table of valid map types
local mt = {
	__index = function(t, k) error('invalid map type '..k) end,
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

return setmetatable(MapType, mt)
