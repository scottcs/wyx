
         --[[--
     DEBUG/PROFILING
         --]]--

-- debug = nil
is_profile = nil ~= debug
if is_profile then require 'lib.profiler' end
local profiler
NOFUNC = function() end
inspect = nil ~= debug and require 'lib.inspect' or NOFUNC


         --[[--
    GLOBAL SINGLETONS
         --]]--

Class = require 'lib.hump.class'
GameState = require 'lib.hump.gamestate'
cron = require 'lib.cron'
tween = require 'lib.tween'


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

-- float values for colors
do
	local sc = love.graphics.setColor
	local sbg = love.graphics.setBackgroundColor

	local function color(r, g, b, a)
		if type(r) == 'table' then r,g,b,a = r[1],r[2],r[3],r[4] end

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

function resizeScreen(width, height)
	local modes = love.graphics.getModes()
	local w, h
	for i=1,#modes do
		w = modes[i].width
		h = modes[i].height
		if w <= width and h <= height then break end
	end

	if w ~= love.graphics.getWidth() and h ~= love.graphics.getHeight() then
		assert(love.graphics.setMode(w, h))
	end

	-- global screen width/height
	WIDTH, HEIGHT = love.graphics.getWidth(), love.graphics.getHeight()
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

	-- set graphics mode
	resizeScreen(1024, 768)

	-- seed and prime the RNG
	math.randomseed(os.time()) math.random() math.random()

	-- save number of music and sound files as global
	NUM_MUSIC = 8
	NUM_SOUNDS = 11

	-- register all love events with gamestate
	GameState.registerEvents()

	-----------------------------------
	-- "The real Pud starts here..." --
	-----------------------------------
	GameState.switch(State.load)
end

function love.update(dt)
	if dt > 0 then
		cron.update(dt)
		tween.update(dt)
		love.audio.update()
	end
end

function love.keypressed(key, unicode)
	-- shift-F1 for debug mode
	if debug 
		and key == 'f1'
		and love.keyboard.isDown('lshift', 'rshift')
	then
		debug.debug()
	end
end

function love.quit()
	tween.stopAll()

	if profiler then
		profiler:stop()
		local outfile = io.open('profile.txt', 'w+')
		profiler:report(outfile)
		outfile:close()
	end
end
