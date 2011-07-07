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


-- override love's color functions to enable use of float values --
do
	local sc = love.graphics.setColor
	local sbg = love.graphics.setBackgroundColor

	local function color(r, g, b, a)
		if    r <= 1 and r > 0
			and g <= 1 and g > 0
			and b <= 1 and b > 0
		then
			r, g, b, a = 255*r, 255*g, 255*b, 255*(a or 1)
		end
		return r, g, b, a
	end

	function love.graphics.setColor(r,g,b,a) sc(color(r,g,b,a)) end
	function love.graphics.setBackgroundColor(r,g,b,a) sbg(color(r,g,b,a)) end
end


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
