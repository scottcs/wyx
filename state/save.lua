
         --[[--
       SAVE STATE
          ----
     Save the game.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.save' end}
setmetatable(st, mt)

require 'lib.serialize'
local property = require 'wyx.component.property'
local warning, tostring = warning, tostring
local format = string.format

function st:init() end

function st:enter(prevState, view, nextState)
	self._view = view
	self:_chooseFile()
	self:_removeFile()
	self:_saveGame()
	RunState.switch(State[nextState])
end

function st:leave()
	if self._file then self._file:close() end
	self._view = nil
	self._file = nil
	self._filename = nil
	self._wyxfilename = nil
end

function st:destroy() end

function st:_chooseFile()
	local place = World:getCurrentPlace()
	local level = place:getCurrentLevel()
	local peID = World:getPrimeEntity()
	local pe = EntityRegistry:get(peID)
	local name = pe:getName()

	self._wyx = {
		name = name,
		iconImage = pe:query(property('TileSet')),
		iconCoords = pe:query(property('TileCoords')),
		iconSize = pe:query(property('TileSize')),
		level = 1, -- pe:query(property('ExperienceLevel')),
		turns = level:getTurns(),
	}

	name = string.gsub(name, '%s+', '_')
	self._filename = format('save/%s.%d.sav', name, GAMESEED)
	self._wyxfilename = format('save/%s.%d.wyx', name, GAMESEED)
end

function st:_removeFile()
	if love.filesystem.exists(self._filename) then
		love.filesystem.remove(self._filename)
	end
	if love.filesystem.exists(self._wyxfilename) then
		love.filesystem.remove(self._wyxfilename)
	end
end

function st:_saveGame()
	self._file = love.filesystem.newFile(self._filename)
	local ok = true

	if not self._file:open('a') then
		warning('Could not open file %q for saving.',
			tostring(self._filename))
		ok = false
	end

	local state = World:getState()
	state.view = self._view:getState()
	state.GAMESEED = GAMESEED
	state.VERSION = VERSION

	ok = ok and self:_write(serialize(state))

	if not self._file:close() then
		warning('Could not close file %q after writing.',
			tostring(self._filename))
	end

	self._file = love.filesystem.newFile(self._wyxfilename)
	ok = true

	if not self._file:open('a') then
		warning('Could not open file %q for saving.',
			tostring(self._wyxfilename))
		ok = false
	end

	ok = ok and self:_write(serialize(self._wyx))

	if not self._file:close() then
		warning('Could not close file %q after writing.',
			tostring(self._wyxfilename))
	end

	for k in pairs(state) do state[k] = nil end

	if Console then Console:print('Game saved to %q', self._filename) end
end

function st:_write(string)
	if not self._file:write(string) then
		warning('Could not write to file %q.', tostring(self._filename))
		return false
	end
	return true
end

function st:update(dt) end

function st:draw() end

function st:keypressed(key, scancode, isrepeat) end

return st
