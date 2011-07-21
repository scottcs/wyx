
-- common utilities used throughout the program
require 'pud.loveutil'
require 'pud.util'


         --[[--
     DEBUG/PROFILING
         --]]--

--debug = nil
is_profile = nil ~= debug
if is_profile then require 'lib.profiler' end
local profiler
NOFUNC = function(...) return ... end
inspect = nil ~= debug and require 'lib.inspect' or NOFUNC
assert = nil ~= debug and assert or NOFUNC


         --[[--
    GLOBAL SINGLETONS
         --]]--

GameState = require 'lib.hump.gamestate'
EventManager = require 'pud.event.EventManager'
cron = require 'lib.cron'
tween = require 'lib.tween'


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

	-- create an event manager for the entire game
	GameEvent = EventManager()

	-----------------------------------
	-- "The real Pud starts here..." --
	-----------------------------------
	GameState.switch(State.intro)
end

function love.update(dt)
	if dt > 0 then
		cron.update(dt)
		tween.update(dt)

		GameEvent:flush()

		love.audio.update()
	end
end

function love.keypressed(key, unicode)
	-- shift-F1 for debug mode
	if debug
		and 'f1' == key
		and love.keyboard.isDown('lshift', 'rshift')
	then
		debug.debug()
	end
end

function love.quit()
	tween.stopAll()

	GameEvent:destroy()

	if profiler then
		profiler:stop()
		local outfile = io.open('profile.txt', 'w+')
		profiler:report(outfile)
		outfile:close()
	end
end
