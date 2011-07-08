
         --[[--
       DEMO STATE
          ----
  Developer playground.
         --]]--

local st = Gamestate.new()

local RingBuffer = require 'lib.hump.ringbuffer'
local string_char = string.char

-- set up background music track buffer
local _bgm
local _bgmbuffer = RingBuffer()
local _bgmchar

for i=97,96+NUM_MUSIC do _bgmbuffer:append(i) end
for i=1,math.random(NUM_MUSIC) do _bgmbuffer:next() end

local function _selectBGM(direction)
	local i = case(direction) {
		[-1] = function() return _bgmbuffer:prev() end,
		[1]  = function() return _bgmbuffer:next() end,
		default  = function() return _bgmbuffer:get() end,
	}
	_bgmchar = string_char(i)
end

function st:init()
	_selectBGM(0)
	_bgm = love.audio.play(Music[_bgmchar])
end

function st:draw()
	love.graphics.setFont(GameFont.small)
	love.graphics.setColor(0.6, 0.6, 0.6)
	love.graphics.print(love.timer.getFPS(), 8, 8)
	love.graphics.setColor(0.9, 0.8, 0.6)
	love.graphics.print('[n]ext [p]rev [s]top [g]o', 70, 42)
	love.graphics.setFont(GameFont.big)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(_bgmchar, 8, 40)
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
		s = function() love.audio.stop(_bgm) end,
		g = function() love.audio.play(_bgm) end,
		n = function()
			love.audio.stop(_bgm)
			_selectBGM(1)
			_bgm = love.audio.play(Music[_bgmchar])
		end,
		p = function()
			love.audio.stop(_bgm)
			_selectBGM(-1)
			_bgm = love.audio.play(Music[_bgmchar])
		end,
		d = function() love.audio.play(Sound.pdeath) end,
		default = function() print(key) end,
	}
end

return st
