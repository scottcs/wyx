local map = {}

map.name = 'Test1'
map.author = 'scx'

--[[

  floor types are (from left to right):
      normal, broken, interior, rug

  wall types are (from left to right):
      horizontal normal, horizontal broken, vertical

--]]

map.glyphs = {
  empty = ' ',
  floor = {'.', ',', '_', 'x'},
  wall = {'%', '*', '#'},
  doorClosed = '+',
  doorOpen = '-',
  trap = '^',
  torch = '~',
  stairUp = '<',
  stairDown = '>',
}

map.map = [[
#%%%%*%%%%%*#%%%*%~%%%*%#
#.......##..#.......##..#
#.<...,.~%..#.,.....##..#
#...........-....#++%%*%#
#..^.#......#....#______#
#....#......#..,.#______#
#########...#...#########
#%%~%#%%*..,#...%#%*%%%%#
#....#......#..,.#......#
#.,..%...^..#....%...^..#
#...........#.xxx.......#
#.....,.##..+.x>x,..##..#
#.......##..#.xxx...##..#
%*%%*%~%%%*%%%%%%*%%%~%%%
]]

return map
