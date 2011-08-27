
-- common utilities used throughout the program
require 'pud.util'
require 'random'
local versionFile = love.filesystem.read('VERSION')
VERSION = string.match(versionFile, '.*VERSION=([%d%.]+)') or "UNKNOWN"
GAMENAME = 'Pud'


         --[[--
     DEBUG/PROFILING
         --]]--

--debug = nil
debugEvents = false
doProfile = false
local doGlobalProfile = doProfile and false

--[[ Profiler Setup ]]--
local globalProfiler
if doGlobalProfile then
	require 'lib.profiler'
	local _profiler = newProfiler()
	globalProfiler = {
		start = function() _profiler:start() end,
		stop = function()
			_profiler:stop()
			local filename = 'pepperfish.out'
			local outfile = io.open(filename, 'w+')
			_profiler:report(outfile)
			outfile:close()
			print('profile written to '..filename)
		end,
	}
end
if doProfile then
	require 'profiler'
	print('analyze profile with '
		..'"lua lib/summary.lua lprof_tmp.0.<stuff>.out"')
else
	local dummy = function() end
	profiler = {
		start = dummy,
		stop = dummy
	}
end


         --[[--
     GLOBAL CLASSES
         --]]--

GameState = require 'lib.hump.gamestate'
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
	if doGlobalProfile then globalProfiler.start() end

	-- set graphics mode
	resizeScreen(1024, 768)

	-- set window title
	love.graphics.setCaption(GAMENAME..' v'..VERSION)

	-- save number of music and sound files as global
	NUM_MUSIC = 8
	NUM_SOUNDS = 11

	-- global tile width and height
	TILEW, TILEH = 32, 32

	-- global random number generator instance
	Random = random.new()

	-- define game fonts
	GameFont = {
		small = love.graphics.newImageFont('font/lofi_small.png',
			'0123456789!@#$%^&*()-=+[]{}:;\'"<>,.?/\\ ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		big = love.graphics.newImageFont('font/lofi_big.png',
			'0123456789!@#$%()-=+,.":;/\\?\' ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		verysmall = love.graphics.newImageFont('font/lofi_verysmall.png',
			'0123456789!@#$%^&*()-=+[]{}:;\'"<>,.?/\\ ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		console = love.graphics.newImageFont('font/grafx2.png',
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'0123456789`~!@#$%^&*()_+-={}[]\\/|<>,.;:\'" '),
	}

	-- register all love events with gamestate
	GameState.registerEvents()

	-- create global event managers (event "channels")
	local EventManager = getClass 'pud.event.EventManager'
	GameEvents = EventManager()
	InputEvents = EventManager()
	CommandEvents = EventManager()

	-- create global console
	Console = getClass('pud.debug.Console')()
	Console:print(colors.GREEN, '%s v%s', GAMENAME, VERSION)

	-- create global entity registry
  EntityRegistry = getClass('pud.entity.EntityRegistry')()

	-- make sure the save directories are created
	_makeSaveDirectories()

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
		InputEvents:push(KeyboardEvent(key, unicode, mods))
	end
end

local MouseEvent = getClass 'pud.event.MouseEvent'

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

	Console:destroy()

	EntityRegistry:destroy()

	GameEvents:destroy()
	InputEvents:destroy()
	CommandEvents:destroy()

	if doGlobalProfile then globalProfiler.stop() end
end

local collectgarbage = collectgarbage
local getMicroTime = love.timer.getMicroTime
local getDelta = love.timer.getDelta
local sleep = love.timer.sleep
local step = love.timer.step
local event = love.event
local poll = love.event.poll
local audio = love.audio
local audiostop = love.audio.stop
local handlers = love.handlers
local clear = love.graphics.clear
local present = love.graphics.present

local function rungb(maxTime)
	local start = getMicroTime()
	local time = 0
	while time < maxTime do
		collectgarbage('step', 0)
		collectgarbage('stop')
		time = getMicroTime() - start
	end
end

function love.run()
	if love.load then love.load(arg) end

	local Hz60 = 1/60
	local dt = 0.01
	local currentTime = getMicroTime()
	local accumulator = 0.0
	local gbcount = 0

	-- disable automatic garbage collector
	collectgarbage('stop')

	-- Main loop time.
	while true do
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

		local newTime = getMicroTime()
		local frameTime = newTime - currentTime
		frameTime = frameTime > 0.25 and 0.25 or frameTime
		currentTime = newTime

		accumulator = accumulator + frameTime

		if frameTime < Hz60 then
			gbcount = gbcount + 1
			local idletime = (Hz60 - frameTime) * 0.99

			-- every once in a while, collect some garbage instead of sleeping
			if gbcount > 10 then
				rungb(idletime)
				gbcount = 0
			else
				sleep(idletime*1000)
			end
		end

		while accumulator >= dt do
			if love.update then love.update(dt) end
			accumulator = accumulator - dt
		end

		clear()
		if love.draw then love.draw() end
		present()
	end
end
