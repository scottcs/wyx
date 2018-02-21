
-- common utilities used throughout the program
require 'wyx.util'
local versionFile = love.filesystem.read('VERSION')
VERSION = string.match(versionFile, '.*VERSION=([%d%.]+)') or "UNKNOWN"
GAMENAME = 'Wyx'
LOAD_DELAY = 0.025


         --[[--
     DEBUG/PROFILING
         --]]--

--debug = nil
debugGameEvents = debug and nil
debugCommandEvents = debug and nil
debugInputEvents = debug and nil
debugTooltips = debug and true
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

RunState = require 'lib.hump.gamestate'
cron = require 'lib.cron'
tween = require 'lib.tween'
inspect = require 'lib.inspect'


         --[[--
       <3 LÖVE <3
         --]]--


local function _makeADir(dir)
	if not love.filesystem.createDirectory(dir) then
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

local function _setIcon()
	local icon = love.graphics.newImage('icon.png')
	love.window.setIcon(icon:getData())
end

function love.load()
	-- create fake Console to store Console:print and :log lines until actual
	-- console is created
	Console = {
		print = function(self, ...)
			self._output = self._output or {}
			self._output[#self._output+1] = {print = {...}}
		end,
		log = function(self, ...)
			self._output = self._output or {}
			self._output[#self._output+1] = {log = {...}}
		end,
	}

	Console:print(colors.GREEN, '%s v%s', GAMENAME, VERSION)

	-- start the profiler
	if doGlobalProfile then globalProfiler.start() end

	-- set graphics mode
	resizeScreen(1024, 768)

	-- set the program icon
	_setIcon()

	-- set window title
	love.window.setTitle(GAMENAME..' v'..VERSION)

	-- set key repeat
	love.keyboard.setKeyRepeat(true)

	-- save number of music and sound files as global
	NUM_MUSIC = 8
	NUM_SOUNDS = 11

	-- global tile width and height
	TILEW, TILEH = 32, 32

	-- define game fonts
	GameFont = {
		bighuge = love.graphics.newImageFont('font/lofi_bighuge.png',
			'0123456789!@#$%()-=+,.":;/\\?\' ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		big = love.graphics.newImageFont('font/lofi_big.png',
			'0123456789!@#$%()-=+,.":;/\\?\' ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		bigsmall = love.graphics.newImageFont('font/lofi_bigsmall.png',
			'0123456789!@#$%()-=+,.":;/\\?\' ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		small = love.graphics.newImageFont('font/lofi_small.png',
			'0123456789!@#$%^&*()-=+[]{}:;\'"<>,.?/\\ ' ..
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

	-- register all love events with run state
	RunState.registerEvents()

	-- create global event managers (event "channels")
	local EventManager = getClass 'wyx.event.EventManager'
	GameEvents = EventManager('GameEvents')
	InputEvents = EventManager('InputEvents')
	CommandEvents = EventManager('CommandEvents')

	if debugGameEvents then GameEvents:debug(debugGameEvents) end
	if debugInputEvents then InputEvents:debug(debugInputEvents) end
	if debugCommandEvents then CommandEvents:debug(debugCommandEvents) end

	-- create global ui system
	UISystem = getClass('wyx.system.UISystem')()

	-- create global console
	Console = getClass('wyx.ui.Console')(Console._output)

	-- make sure the save directories are created
	_makeSaveDirectories()

	-----------------------------------
	-- "The real Wyx starts here..." --
	-----------------------------------
	RunState.switch(State.intro)
end

function love.update(dt)
	cron.update(dt)
	tween.update(dt)

	GameEvents:flush()
	InputEvents:flush()
	CommandEvents:flush()

	love.audio.update()

	UISystem:update(dt)
end

local _postdraw = function() UISystem:draw() end

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

local KeyboardEvent = getClass 'wyx.event.KeyboardEvent'

function love.keypressed(key, scancode, isrepeat)
	local mods = _getModifiers()

	-- shift-F1 for debug mode
	if debug and 'f1' == key and mods['shift'] then
		debug.debug()
	else
		InputEvents:notify(KeyboardEvent(key, scancode, isrepeat, mods))
	end
end

local MousePressedEvent = getClass 'wyx.event.MousePressedEvent'
local MouseReleasedEvent = getClass 'wyx.event.MouseReleasedEvent'

function love.mousepressed(x, y, button, istouch)
	local mods = _getModifiers()
	InputEvents:notify(MousePressedEvent(x, y, button,
		love.mouse.isGrabbed(),
		love.mouse.isVisible(),
    istouch,
		mods))
end

function love.mousereleased(x, y, button, istouch)
	local mods = _getModifiers()
	InputEvents:notify(MouseReleasedEvent(x, y, button,
		love.mouse.isGrabbed(),
		love.mouse.isVisible(),
    istouch,
		mods))
end

function love.quit()
	tween.stopAll()

	Console:destroy()
	UISystem:destroy()

	GameEvents:destroy()
	InputEvents:destroy()
	CommandEvents:destroy()

	if doGlobalProfile then globalProfiler.stop() end
end

local getTime = love.timer.getTime
local sleep = love.timer.sleep
local event = love.event
local audio = love.audio
local audiostop = love.audio.stop
local handlers = love.handlers
local clear = love.graphics.clear
local present = love.graphics.present

function love.run()
	if love.load then love.load(arg) end

  if love.timer then love.timer.step() end

  local dt = 0

	-- Main loop time.
	while true do
		-- Process events.
		if event then
      event.pump()
			for name, a,b,c,d,e,f in event.poll() do
        io.write(name..'\n')
				if name == "quit" then
					if not love.quit or not love.quit() then
						if audio then
							audiostop()
						end
						return a
					end
				end
				handlers[name](a,b,c,d,e,f)
			end
		end

    if love.timer then
      love.timer.step()
      dt = love.timer.getDelta()
    end

    if love.update then love.update(dt) end

		clear()
		if love.draw then
			love.draw()
			_postdraw()
		end
		present()
	end

  if love.timer then love.timer.sleep(0.001) end
end
