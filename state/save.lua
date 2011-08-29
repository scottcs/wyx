
         --[[--
       SAVE STATE
          ----
     Save the game.
         --]]--

local st = GameState.new()

local json = require 'lib.dkjson'
require 'lib.serialize'
local warning, tostring = warning, tostring

function st:init() end

function st:enter(prevState, nextState)
	print('save')
	self:_chooseFile()
	self:_removeFile()
	self:_saveGame()
	GameState.switch(nextState)
end

function st:leave()
	if self._file then self._file:close() end
	self._file = nil
	self._filename = nil
end

function st:destroy() end

function st:_chooseFile()
	self._filename = 'save/save1.json'
end

function st:_removeFile()
	if love.filesystem.exists(self._filename) then
		love.filesystem.remove(self._filename)
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

	local opts = {indent = true}

	for entity in EntityRegistry:iterateEntities() do
		ok = ok and self:_write(json.encode(entity, opts))
		--ok = ok and self:_write(serialize(entity))
	end

	if not self._file:close() then
		warning('Could not close file %q after writing.',
			tostring(self._filename))
	end
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

function st:keypressed(key, unicode) end

return st
