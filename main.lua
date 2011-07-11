
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
       <3 LÖVE <3
         --]]--

-- common utilities used throughout the program
require 'pud.util'

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
	GameState.switch(State.intro)
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
