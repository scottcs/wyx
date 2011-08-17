
-- common utilities used throughout the program
require 'pud.util'
require 'random'


         --[[--
     DEBUG/PROFILING
         --]]--

--debug = nil
doProfile = true
local doGlobalProfile = doProfile and false

--[[ Profiler Setup ]]--
local profilers = {'pepperfish', 'luatrace', 'luaprofiler'}
local useProfiler = 3
if doProfile and useProfiler >= 1 and useProfiler <= #profilers then
	local prof = profilers[useProfiler]
	if prof == 'pepperfish' then
		require 'lib.profiler'
		local _profiler = newProfiler()
		profiler = {
			start = function() _profiler:start() end,
			stop = function() _profiler:stop() end,
			stopAll = function()
				_profiler:stop()
				local filename = 'pepperfish.out'
				local outfile = io.open(filename, 'w+')
				_profiler:report(outfile)
				outfile:close()
				print('profile written to '..filename)
			end,
		}
	elseif prof == 'luatrace' then
		local _profiler = require 'luatrace'
		profiler = {
			start = _profiler.tron,
			stop = _profiler.troff,
			stopAll = function()
				_profiler.troff()
				print('analyze profile with "luatrace.profile"')
			end,
		}
	elseif prof == 'luaprofiler' then
		require 'profiler'
		local _profiler = profiler
		profiler = {
			start = _profiler.start,
			stop = _profiler.stop,
			stopAll = function()
				_profiler.stop()
				print('analyze profile with '
					..'"lua lib/summary.lua lprof_tmp.0.<stuff>.out"')
			end,
		}
	end
end


         --[[--
     GLOBAL CLASSES
         --]]--

GameState = require 'lib.hump.gamestate'
EventManager = getClass 'pud.event.EventManager'
cron = require 'lib.cron'
tween = require 'lib.tween'


         --[[--
       <3 LÖVE <3
         --]]--


local function _makeADir(dir)
	if not love.filesystem.mkdir(dir) then
		local savedir = love.filesystem.getSaveDirectory()
		error('Could not create directory: '..savedir..'/'..tostring(dir))
	end
end

local function _makeSaveDirectories()
	for _,dir in ipairs({
		--[[
		'font',
		'music',
		'image',
		'sound',
		'map',
		'entity/item',
		'entity/enemy',
		'entity/hero',
		'skill',
		]]--
		'save',
		'morgue',
	}) do _makeADir(dir) end
end

function love.load()
	-- start the profiler
	if doGlobalProfile then profiler.start() end

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

	-- make sure the save directories are created
	_makeSaveDirectories()

	--_testJSON('GoblinGrunt')

	-----------------------------------
	-- "The real Pud starts here..." --
	-----------------------------------
	GameState.switch(State.intro)
end

function love.update(dt)
	cron.update(dt)
	tween.update(dt)

	GameEvents:flush()
	InputEvents:flush()
	CommandEvents:flush()

	love.audio.update()
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

local KeyboardEvent = getClass 'pud.event.KeyboardEvent'

function love.keypressed(key, unicode)
	local mods = _getModifiers()

	-- shift-F1 for debug mode
	if debug and 'f1' == key and mods['shift'] then
		debug.debug()
	else
		InputEvents:notify(KeyboardEvent(key, unicode, mods))
	end
end

local MouseEvent = getClass 'pud.event.MouseEvent'

function love.mousepressed(x, y, button)
	local mods = _getModifiers()
	local btns = _getButtons()
	InputEvents:notify(MouseEvent(x, y, button,
		love.mouse.isGrabbed(),
		love.mouse.isVisible(),
		mods))
end

function love.quit()
	tween.stopAll()

	GameEvents:destroy()
	InputEvents:destroy()
	CommandEvents:destroy()

	if doGlobalProfile then profiler.stopAll() end
end

local collectgarbage = collectgarbage
local getTime = love.timer.getTime
local sleep = love.timer.sleep
local event = love.event
local poll = love.event.poll
local audio = love.audio
local audiostop = love.audio.stop
local handlers = love.handlers
local clear = love.graphics.clear
local present = love.graphics.present

local function idle(maxTime)
	local start = getTime()
	local time = 0
	while time < maxTime do
		collectgarbage('step', 0)
		collectgarbage('stop')
		time = getTime() - start
	end
end

function love.run()
	if love.load then love.load(arg) end

	local FPS = 60
	local dt = 1/FPS
	local idletime = dt * 0.00005
	local time

	-- disable automatic garbage collector
	collectgarbage('stop')

	-- Main loop time.
	while true do
		local time = getTime()

		-- Process events.
		if event then
			for e,a,b,c in poll() do
				if e == "q" then
					if not love.quit or not love.quit() then
						-- restart garbage collector
						collectgarbage('restart')
						if audio then
							audiostop()
						end
						return
					end
				end
				handlers[e](a,b,c)
			end
		end

		if love.update then love.update(dt) end

		clear()
		if love.draw then love.draw() end
		present()

		-- collect a little garbage manually
		idle(idletime)

		local timeWorked = getTime() - time
		if timeWorked < dt then
			sleep((dt-timeWorked) * 1000)
		end
	end
end
