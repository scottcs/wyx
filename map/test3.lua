local map = {}

map.name = 'Test3'
map.author = 'scx'

--[[
   set to true if you do not want to specify which floor and wall tiles are
   different. the map generator will randomly change some normal map and floor
   tiles to look worn or have torches.

   (note: only normal floor and wall tiles are affected. if you turn this on
   AND also specify some worn or other detailed walls or floors, your
   special walls and floors will not change, but your normal ones will have
   more random worn tiles).
--]]
map.handleDetail = true

--[[
	note: worn and torch wall types will only show up on horizontal walls.
	vertical walls are created automatically where needed.

  if you fail to provide an entry in this table for a glyph you used in the
  map below, you will receive an error when you try to load the map in-game.

	make sure each line inside the first curly brackets ends with a comma.
--]]
map.glyphs = {
  empty = '0',
  floor = {'.', ',', '_', 'x'},  -- normal, worn, interior, rug
  wall = {'#', '%', '*'},        -- normal, worn, torch
  door = {'+', '-'},             -- shut, open
  stair = {'<', '>'},            -- up, down
  trap = {'^'},                  -- normal (possibly more later)
}

--[[
   the map. can be any size. spaces matter, even at the beginning of the line.
   (that is, spaces, even at the beginning of the line, will be looked up in
   your glyph table above and given the appropriate value).

   each row must be exactly the same width. use a character other than space
   for empty tiles if needed.
--]]
map.map = [[
#################################################00000000000000000000000000
#..^............#.........^...................^.#00000000000000000000000000
#.###.....<.....#...#...#...#...#...#...#...#...#00000000000000000000000000
#.#x#...........#.....^...............^...^.....#000000000000000000000#####
#.#+#############...#...#...#...#...#...#...#...#######################...#
#.........................^.......^.....................................>.#
#.#+#############...#...#...#...#...#...#...#...#######################...#
#.#x#...........#.....^...^...^.................##......##...........######
#.###..########.#.^.#...#...#...#...#...#...#...#...###.....#######.......#
#......#______#.#.......#################.^.....#...#.###....#..#######..##
#......#__xx__#.#.#.######____######____#####.#.#..##..####....^..###...##0
#......#__xx__#.#........#___x+....+x___#.......#.###^..#####...####...##00
#......#__xx__#.#.#.#.##.######....######.###.#.#.......####...###....##000
#......#______#.#...#..#.............^......#...#....####.##..##...####0000
#......###++###.###################################...##...##.#.^.##0000000
#......................................###0##.####....#.....####...###00000
#.....^.........................#####....###.................##......##0000
#.............................###000###.......###..#######............#0000
###############################0000000#########0####00000##############0000
]]

--[[
	if you want to set zones for the map, you have to count the coordinates out
	(top left corner of the map is 1,1), and just define the top left and bottom
	right corners of the zone (the zone includes its borders).

	for example:
	map.zones = {
	  tavern = {14, 9, 20, 12},
	}
	-- the top left corner is (14, 9) and the bottom right is (20, 12).

	make sure each line inside the first curly brackets ends with a comma.
--]]
map.zones = {
	entryhall = {3,6, 17,6},
	exithall = {49,6, 71,6},
	tavern = {9,10, 14,14},
	tavernRug = {11,11, 12,13},
	greathall = {18,2, 48,10},
	chamber1 = {27,11, 30,12},
	chamber2 = {37,11, 40,12},
	something_cool = {62,15, 62,15},
}

return map
