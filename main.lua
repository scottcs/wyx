
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

--[[ Profiler Setup ]]--
local profilers = {'pepperfish', 'luatrace', 'luaprofiler'}
local useProfiler = 1
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
EventManager = require 'pud.event.EventManager'
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
		'item',
		'enemy',
		'hero',
		'skill',
		]]--
		'save',
		'morgue',
	}) do _makeADir(dir) end
end

local function _testJSON(enemy)
	local json = require 'lib.dkjson'
	local file = love.filesystem.read('enemy/'..enemy..'.json')
	local skula, nextobj, errmsg = json.decode(file)
	if errmsg then error(errmsg) end
	local inspect = require 'lib.inspect'
	print(inspect(skula))
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

	if doGlobalProfile then profiler.stopAll() end
end
