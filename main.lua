-- debug/profiling --
-- debug = nil
is_profile = nil ~= debug
if is_profile then require 'lib.profiler' end
local profiler


-- global singleton (ish) objects
Class = require 'lib.hump.class'
Timer = require 'lib.hump.timer'
Gamestate = require 'lib.hump.gamestate'
Camera = require 'lib.hump.camera'

---------------
-- UTILITIES --
---------------
-- handy case statement --
function case(x)
	return function (of)
		local what = of[x] or of.default
		if type(what) == "function" then
			return what()
		end
		return what
	end
end

-- loaders for resources --
local function Proxy(loader)
	return setmetatable({}, {__index = function(self, k)
		local v = loader(k)
		rawset(self, k, v)
		return v
	end})
end

State = Proxy(function(k)
	return assert(love.filesystem.load('state/'..k..'.lua'))()
end)
Font  = Proxy(function(k)
	return love.graphics.newFont('font/dejavu.ttf', k)
end)
Image = Proxy(function(k)
	return love.graphics.newImage('image/'..k..'.png')
end)
Sound = Proxy(function(k)
	return love.audio.newSource(
		love.sound.newSoundData('sound/'..k..'.ogg'),
		'static')
end)


----------
-- LÖVE --
----------
function love.load()
	-- start the profiler
	if is_profile then
		profiler = newProfiler()
		profiler:start()
	end

	-- seed and prime the RNG
	math.randomseed(os.time()) math.random() math.random()

	WIDTH = love.graphics.getWidth()
	HEIGHT = love.graphics.getHeight()

	-- load normal fonts
	for _,size in ipairs{14, 15, 16, 18, 20, 24} do
		local f = Font[size]
	end

	-- load game fonts
	GameFont = {
		small = love.graphics.newImageFont('font/lofi_small.png',
			'0123456789!@#$%^&*()-=+[]{}:;\'"<>,.?/\\ ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		big = love.graphics.newImageFont('font/lofi_big.png',
			'0123456789!@#$%()-=+,.":;/\\?\' ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
	}

	Gamestate.registerEvents()
	--Gamestate.switch(State.game)
	Gamestate.switch(State.intro)
end

function love.update(dt)
	Timer.update(dt)
end

function love.quit()
	if profiler then
		profiler:stop()
		local outfile = io.open('profile.txt', 'w+')
		profiler:report(outfile)
		outfile:close()
	end
end
