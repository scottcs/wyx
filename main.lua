
-- common utilities used throughout the program
require 'pud.loveutil'
require 'pud.util'
require 'random'


         --[[--
     DEBUG/PROFILING
         --]]--

--debug = nil
doProfile = true
local doGlobalProfile = doProfile and true
local useProfiler = 'pepperfish'
--local useProfiler = 'luatrace'
--local useProfiler = 'luaprofiler'
if doProfile then
	if useProfiler == 'pepperfish' then
		require 'lib.profiler'
		profiler = newProfiler()
	elseif useProfiler == 'luatrace' then
		profiler = require 'luatrace'
	elseif useProfiler == 'luaprofiler' then
		require 'profiler'
	end
end
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
	if doGlobalProfile then
		if useProfiler == 'pepperfish' then
			profiler:start()
		elseif useProfiler == 'luatrace' then
			profiler.tron()
		elseif useProfiler == 'luaprofiler' then
			profiler.start()
		end
	end

	-- set graphics mode
	resizeScreen(1024, 768)

	-- save number of music and sound files as global
	NUM_MUSIC = 8
	NUM_SOUNDS = 11

	-- global tile width and height
	TILEW, TILEH = 32, 32

	-- global random number generator instance
	Random = random.new()

	-- register all love events with gamestate
	GameState.registerEvents()

	-- create global event managers (event "channels")
	GameEvents = EventManager()
	InputEvents = EventManager()
	CommandEvents = EventManager()

	-----------------------------------
	-- "The real Pud starts here..." --
	-----------------------------------
	GameState.switch(State.intro)
end

function love.update(dt)
	if dt > 0 then
		cron.update(dt)
		tween.update(dt)

		GameEvents:flush()
		InputEvents:flush()
		CommandEvents:flush()

		love.audio.update()
	end
end

-- table for quick lookup of specific modifiers to generic modifiers
local _modLookup = {
	numlock = 'numlock',
	capslock = 'capslock',
	scrollock = 'scrollock',
	rshift = 'shift',
	lshift = 'shift',
	rctrl = 'ctrl',
	lctrl = 'ctrl',
	ralt = 'alt',
	lalt = 'alt',
	rmeta = 'meta',
	lmeta = 'meta',
	lsuper = 'super',
	rsuper = 'super',
	mode = 'mode',
	compose = 'compose',
}

local function _getModifiers()
	local mods = {}
	for k,v in pairs(_modLookup) do
		if love.keyboard.isDown(k) then
			mods[k] = true
			mods[v] = true
		end
	end
	return mods
end

local KeyboardEvent = require 'pud.event.KeyboardEvent'

function love.keypressed(key, unicode)
	local mods = _getModifiers()

	-- shift-F1 for debug mode
	if debug and 'f1' == key and mods['shift'] then
		debug.debug()
	else
		InputEvents:push(KeyboardEvent(key, unicode, mods))
	end
end

local MouseEvent = require 'pud.event.MouseEvent'

function love.mousepressed(x, y, button)
	local mods = _getModifiers()
	local btns = _getButtons()
	InputEvents:push(MouseEvent(x, y, button,
		love.mouse.isGrabbed(),
		love.mouse.isVisible(),
		mods))
end

function love.quit()
	tween.stopAll()

	GameEvents:destroy()
	InputEvents:destroy()
	CommandEvents:destroy()

	if doGlobalProfile then
		if useProfiler == 'pepperfish' then
			profiler:stop()
			local filename = 'pepperfish.out'
			local outfile = io.open(filename, 'w+')
			profiler:report(outfile)
			outfile:close()
			print('profile written to '..filename)
		elseif useProfiler == 'luatrace' then
			profiler.troff()
			print('analyze profile with "luatrace.profile"')
		elseif useProfiler == 'luaprofiler' then
			profiler.stop()
			print('analyze profile with '
				..'"lua lib/summary.lua lprof_tmp.0.<stuff>.out"')
		end
	end
end
