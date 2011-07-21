local map = {}

map.name = 'Test1'
map.author = 'scx'

map.glyphs = {
	empty = ' ',
	floor = '.',
	wall = '#',
	doorClosed = '+',
	doorOpen = '-',
	trap = '^',
	torch = '~',
	stairUp = '<',
	stairDown = '>',
}

map.map = [[
#############
#.......##..#
#.<.....~#..#
#...........#
#....#......#
#....-......#
#########...#
#########...#
#....#......#
#....#...^..#
#...........#
#.>.....~#..+
#.......##..#
#############
]]

return map
