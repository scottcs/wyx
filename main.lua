
         --[[--
     DEBUG/PROFILING
         --]]--

-- debug = nil
is_profile = nil ~= debug
if is_profile then require 'lib.profiler' end
local profiler


         --[[--
    GLOBAL SINGLETONS
         --]]--

Class = require 'lib.hump.class'
Timer = require 'lib.hump.timer'
Gamestate = require 'lib.hump.gamestate'
Camera = require 'lib.hump.camera'


         --[[--
        UTILITIES
         --]]--

-- handy case statement
function case(x)
	return function (of)
		local what = of[x] or of.default
		if type(what) == "function" then
			return what()
		end
		return what
	end
end

-- loaders for resources
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
Music = Proxy(function(k)
	local src = love.audio.newSource(
		love.sound.newSoundData('music/'..k..'.ogg'),
		'stream')
	src:setLooping(true)
	return src
end)

-- float values for colors
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


         --[[--
      SOUND MANAGER
         --]]--

do
	-- will hold the currently playing sources
	local sources = {}

	-- check for sources that finished playing and remove them
	function love.audio.update()
		local remove = {}
		for _,s in pairs(sources) do
			if s:isStopped() then
				remove[#remove + 1] = s
			end
		end

		for i,s in ipairs(remove) do
			sources[s] = nil
		end
	end

	-- overwrite love.audio.play to create and register source if needed
	local play = love.audio.play
	function love.audio.play(what, how, loop)
		local src = what
		if type(what) ~= "userdata" or not what:typeOf("Source") then
			src = love.audio.newSource(what, how)
			src:setLooping(loop or false)
		end

		play(src)
		sources[src] = src
		return src
	end

	-- stops a source
	local stop = love.audio.stop
	function love.audio.stop(src)
		if not src then return end
		stop(src)
		sources[src] = nil
	end
end


         --[[--
       <3 LÖVE <3
         --]]--

function love.load()
	-- start the profiler
	if is_profile then
		profiler = newProfiler()
		profiler:start()
	end

	-- seed and prime the RNG
	math.randomseed(os.time()) math.random() math.random()

	-- save window width and height as globals
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

	-- register all love events with gamestate
	Gamestate.registerEvents()

	-----------------------------------
	-- "The real Pud starts here..." --
	-----------------------------------
	Gamestate.switch(State.play)
	--Gamestate.switch(State.intro)
end

function love.update(dt)
	Timer.update(dt)
	love.audio.update()
end

function love.quit()
	if profiler then
		profiler:stop()
		local outfile = io.open('profile.txt', 'w+')
		profiler:report(outfile)
		outfile:close()
	end
end
