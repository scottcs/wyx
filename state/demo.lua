
         --[[--
       DEMO STATE
          ----
  Developer playground.
         --]]--

local st = GameState.new()

local math_max, math_min, math_random, string_char
		= math.max, math.min, math.random, string.char

local RandomBag = require 'lib.pud.randombag'
local RingBuffer = require 'lib.hump.ringbuffer'

-- set up background music track buffer
local _bgm
local _bgmbuffer = RingBuffer()
local _bgmchar
local _bgmvolume = 1.0

-- set up sound bag
local _sounds = {
	'door',
	'hit',
	'mdeath',
	'miss',
	'mouch',
	'pdeath',
	'pouch',
	'quaff',
	'stairs',
	'trap',
	'use',
}
local _sbag = RandomBag(1,#_sounds)
local _sound

for i=97,96+NUM_MUSIC do _bgmbuffer:append(i) end
for i=1,math_random(NUM_MUSIC) do _bgmbuffer:next() end

local function _selectBGM(direction)
	local i = case(direction) {
		[-1] = function() return _bgmbuffer:prev() end,
		[1]  = function() return _bgmbuffer:next() end,
		default  = function() return _bgmbuffer:get() end,
	}
	_bgmchar = string_char(i)
end

local function _adjustBGMVolume(amt)
	_bgmvolume = math_max(0, math_min(1, _bgmvolume + amt))
	_bgm:setVolume(_bgmvolume)
end

local function _playMusic()
	if _bgm and not _bgm:isStopped() then return end
	_bgm = love.audio.play('music/'.._bgmchar..'.ogg', 'stream', true)
	_bgm:setVolume(_bgmvolume)
end

local function _playRandomSound()
	local sound = _sounds[_sbag:next()]
	_sound = love.audio.play(Sound[sound])
	_sound:setVolume(_bgmvolume)
end

function st:enter()
	_selectBGM(0)
end

function st:draw()
	love.graphics.setFont(GameFont.small)
	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.print('fps: '..tostring(love.timer.getFPS()), 8, 8)

	love.graphics.setColor(0.9, 0.8, 0.6)
	love.graphics.print('[n]ext [p]rev [s]top [g]o', 210, 46)
	love.graphics.print('[+][-] volume', 210, 88)
	love.graphics.print('[d]emo a sound', 210, 130)

	love.graphics.setFont(GameFont.big)
	local clr = {.1, .8, .1}
	if not _bgm or _bgm:isStopped() then clr = {.8, .1, .1} end
	love.graphics.setColor(clr)
	love.graphics.print(_bgmchar, 8, 44)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(_bgmvolume, 8, 84)
	if _sound and not _sound:isStopped() then
		love.graphics.print(_sounds[_sbag:getLast()], 8, 124)
	end
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
		s = function() love.audio.stop(_bgm) end,
		g = function() _playMusic() end,
		n = function()
			love.audio.stop(_bgm)
			_selectBGM(1)
			_playMusic()
		end,
		p = function()
			love.audio.stop(_bgm)
			_selectBGM(-1)
			_playMusic()
		end,
		d = function() _playRandomSound() end,
		['-']   = function() _adjustBGMVolume(-0.05) end,
		['kp-'] = function() _adjustBGMVolume(-0.05) end,
		['+']   = function() _adjustBGMVolume(0.05) end,
		['kp+'] = function() _adjustBGMVolume(0.05) end,
	}
end

return st
