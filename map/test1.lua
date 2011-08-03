local map = {}

map.name = 'Test1'
map.author = 'scx'

--[[
  floor types are (from left to right):
      normal, broken, interior, rug

  wall types are (from left to right):
      normal, broken, torch

	note: broken and torch wall types will only show up on horizontal walls.

	if you fail to provide an entry in this table for a glyph you used in the
	map below, you will receive an error when you try to load the map in-game.
--]]
map.glyphs = {
  empty = ' ',
  floor = {'.', ',', '_', 'x'},
  wall = {'#', '%', '*'},
  doorClosed = '+',
  doorOpen = '-',
  trap = '^',
  stairUp = '<',
  stairDown = '>',
}

--[[
   set to true if you do not want to specify which floor and wall tiles are
   different. the map generator will randomly change some normal map and floor
   tiles to look broken or have torches.

   (note: only normal floor and wall tiles are affected. if you turn this on
   AND also specify some broken or other detailed walls or floors, your
   special walls and floors will not change, but your normal ones will have
   more random broken tiles).
--]]
map.handleDetail = false

--[[
   the map. can be any size. spaces matter, even at the beginning of the line.
   (that is, spaces, even at the beginning of the line, will be looked up in
   your glyph table above and given the appropriate value).

   each row must be exactly the same width. use a character other than space
   for empty tiles if needed.
--]]
map.map = [[
#####%#####%####%#*###%##
#.......##..#.......##..#
#.<...,.*#..#.,.....##..#
#...........-....#++##%+#
#..^.#......#....#______#
#....#......#..,.#______#
#########...#...#########
###*####%..,#...###%#####
#....#......#..,.#......#
#.,..#...^..#....#...^..#
#...........#.xxx.......#
#.....,.##..+.x>x,..##..#
#.......##..#.xxx...##..#
#%##%#*###%######%###*###
]]

return map
