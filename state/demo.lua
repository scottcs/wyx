
         --[[--
       DEMO STATE
          ----
  Developer playground.
         --]]--

local st = GameState.new()

local math_max, math_min, math_floor, string_char
		= math.max, math.min, math.floor, string.char
local PI2 = math.pi * 2

local RandomBag = getClass 'pud.kit.RandomBag'
local RingBuffer = require 'lib.hump.ringbuffer'
local Camera = require 'lib.hump.camera'
local vector = require 'lib.hump.vector'

-- camera
local _cam
local CAM_TRANSLATE = 16
local CAM_ROTATE = 1/72
local CAM_ZOOM = 3
local CAM_ZOOMIN = 0.9
local CAM_ZOOMOUT = 1.1

-- set up frame buffers
local _hudFB, _bgFB

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
for i=1,Random(NUM_MUSIC) do _bgmbuffer:next() end

local function _selectBGM(direction)
	local i = switch(direction) {
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

local function _drawWorldFB()
	love.graphics.setColor(1,1,1,1)
	love.graphics.setBlendMode('alpha')
	love.graphics.draw(Image.demobg, 0, 0)
end

local function _drawWorld()
	love.graphics.draw(_bgFB)
end

local function _correctCam()
	local wmin = math_floor((WIDTH/2)/_cam.zoom + 0.5)
	local wmax = Image.demobg:getWidth() - wmin
	if _cam.pos.x < wmin then _cam.pos.x = wmin end
	if _cam.pos.x > wmax then _cam.pos.x = wmax end

	local hmin = math_floor((HEIGHT/2)/_cam.zoom + 0.5)
	local hmax = Image.demobg:getHeight() - hmin
	if _cam.pos.y < hmin then _cam.pos.y = hmin end
	if _cam.pos.y > hmax then _cam.pos.y = hmax end
end

local function _drawHUDFB()
	local bt = HEIGHT-164
	love.graphics.setColor(0, 0, 0.4, 0.8)
	love.graphics.rectangle('fill', 4, 4, 612, 160)
	love.graphics.rectangle('fill', 4, bt, 612, 160)
	love.graphics.setBlendMode('alpha')

	love.graphics.setFont(GameFont.small)
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.print('fps: '..tostring(love.timer.getFPS()), 8, 8)

	local c = 'cam: '
	local h = GameFont.small:getHeight()
	local x, y = _cam.pos:unpack()
	x, y = math_floor(x*100)/100, math_floor(y*100)/100
	c = c..'('..x..','..y..')'
	local r = math_floor(_cam.rot * 100) / 100
	local z = math_floor(_cam.zoom * 100) / 100
	love.graphics.print(c..', '..tostring(r)..', '..tostring(z), 8, bt+8)

	love.graphics.setColor(0.9, 0.8, 0.6)
	love.graphics.print('[n]ext [p]rev [s]top [g]o', 210, 8+(4+h))
	love.graphics.print('[+][-] volume', 210, 8+(4+h)*2)
	love.graphics.print('[d]emo a sound', 210, 8+(4+h)*3)

	love.graphics.print('[arrow keys] pan', 8, bt+8+(4+h))
	love.graphics.print('[pgup][pgdn] zoom  [home] reset', 8, bt+8+(4+h)*2)
	love.graphics.print('[,][.] rotate', 8, bt+8+(4+h)*3)

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

local function _drawHUD()
	love.graphics.draw(_hudFB)
end

function st:init()
	local w = math_floor(Image.demobg:getWidth()/2)
	local h = math_floor(Image.demobg:getHeight()/2)
	_cam = Camera(vector(w, h), CAM_ZOOM)
	local hudsize = nearestPO2(math.max(WIDTH, HEIGHT))
	local bgsize = nearestPO2(math.max(w*2, h*2))
	_hudFB = love.graphics.newFramebuffer(hudsize, hudsize)
	_bgFB = love.graphics.newFramebuffer(bgsize, bgsize)
end

local _keyDelay, _keyInterval, _accum
function st:enter()
	_keyDelay, _keyInterval = love.keyboard.getKeyRepeat()
	love.keyboard.setKeyRepeat(200, 25)
	_selectBGM(0)
	_bgFB:renderTo(_drawWorldFB)
	_hudFB:renderTo(_drawHUDFB)
	_accum = 0
end

function st:draw()
	_cam:draw(_drawWorld)
	_drawHUD()
end

function st:update(dt)
	_accum = _accum + dt
	if _accum >= 0.05 then
		_accum = 0
		_hudFB:renderTo(_drawHUDFB)
	end
end

function st:keypressed(key, unicode)
	switch(key) {
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

		-- camera
		left = function()
			local amt = vector(-CAM_TRANSLATE/_cam.zoom, 0)
			_cam:translate(amt)
			_correctCam()
		end,
		right = function()
			local amt = vector(CAM_TRANSLATE/_cam.zoom, 0)
			_cam:translate(amt)
			_correctCam()
		end,
		up = function()
			local amt = vector(0, -CAM_TRANSLATE/_cam.zoom)
			_cam:translate(amt)
			_correctCam()
		end,
		down = function()
			local amt = vector(0, CAM_TRANSLATE/_cam.zoom)
			_cam:translate(amt)
			_correctCam()
		end,
		[','] = function() _cam:rotate(CAM_ROTATE*PI2) end,
		['.'] = function() _cam:rotate(-CAM_ROTATE*PI2) end,
		pageup = function()
			_cam.zoom = math_max(1, _cam.zoom * CAM_ZOOMIN)
			_correctCam()
		end,
		pagedown = function() 
			_cam.zoom = math_min(10, _cam.zoom * CAM_ZOOMOUT)
			_correctCam()
		end,
		home = function()
			_cam.rot = 0
			_cam.zoom = CAM_ZOOM
			local w = math_floor(Image.demobg:getWidth()/2)
			local h = math_floor(Image.demobg:getHeight()/2)
			_cam.pos = vector(w,h)
			_correctCam()
		end,
	}
end

function st:leave()
	love.keyboard.setKeyRepeat(_keyDelay, _keyInterval)
end

return st
