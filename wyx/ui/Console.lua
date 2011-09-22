local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'
local TextEntry = getClass 'wyx.ui.TextEntry'
local Deque = getClass 'wyx.kit.Deque'
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local command = require 'wyx.ui.command'
local ui = require 'ui.Console'
local depths = require 'wyx.system.renderDepths'

local format, match = string.format, string.match
local gmatch = string.gmatch
local concat = table.concat
local unpack = unpack
local tostring = tostring
local colors = colors

-- Console
-- Provides a feedback and command console for debugging and cheating.
local Console = Class{name='Console',
	inherits=Frame,
	function(self, firstOutput)
		Frame.construct(self, ui.main.x, ui.main.y, ui.main.w, ui.main.h)
		self:setNormalStyle(ui.main.normalStyle)
		self:setDepth(depths.console)

		-- don't call self:hide() here because it will unregister keys
		self._show = false

		self._buffer = Deque()
		self._firstLine = 0

		self:_makeEntry()

		self._filename = 'console.log'
		if love.filesystem.exists(self._filename) then
			love.filesystem.remove(self._filename)
		end
		self._file = love.filesystem.newFile(self._filename)
		if not self._file:open('a') then
			warning('Could not open console log')
			self._file = nil
		end

		UISystem:registerKeys(ui.keysID, ui.keys)
		InputEvents:register(self, InputCommandEvent)

		-- if lines to print or to log were passed in, handle them now
		if firstOutput then
			verify('table', firstOutput)
			local num = #firstOutput
			for i=1,num do
				local toOutput = firstOutput[i]
				for kind,output in pairs(toOutput) do
					if kind == 'print' then
						self:print(unpack(output))
					elseif kind == 'log' then
						self:print(unpack(output))
					else
						warning('Incorrect Console output type: %s', tostring(kind))
					end
				end
			end
		end
	end
}

-- destructor
function Console:destroy()
	self:_closeLog()
	InputEvents:unregisterAll(self)
	UISystem:unregisterKeys(ui.keysOnShowID)
	UISystem:unregisterKeys(ui.keysID)
	self._buffer:destroy()
	self._buffer = nil
	self._prompt = nil
	self._entry = nil
	self._firstLine = nil
	Frame.destroy(self)
end

function Console:InputCommandEvent(e)
	local cmd = e:getCommand()
	--local args = e:getCommandArgs()
	--
	switch(cmd) {
		CONSOLE_TOGGLE = function() self:toggle() end,
		CONSOLE_HIDE = function() self:hide() end,
		CONSOLE_PAGEUP = function() self:pageup() end,
		CONSOLE_PAGEDOWN = function() self:pagedown() end,
		CONSOLE_TOP = function() self:top() end,
		CONSOLE_BOTTOM = function() self:bottom() end,
		CONSOLE_CLEAR = function() self:clearBuffer() end,
		CONSOLE_ENTRY = function() self._commandline:toggleEnterMode(true) end,
	}
end


function Console:_setDrawColor()
	local sb = ui.scrollback
	local color = (self._firstLine == 0) and sb.normalcolor or sb.scrollcolor
	self:setColor(color)
	self._needsUpdate = true
end

function Console:clearBuffer()
	self._buffer:clear()
	self._firstLine = 0
	self:_setDrawColor()
end

function Console:pageup()
	self._firstLine = self._firstLine + ui.scrollback.lines
	local max = 1+(self._buffer:size() - ui.scrollback.lines)
	if self._firstLine > max then self._firstLine = max end
	self:_setDrawColor()
end

function Console:pagedown()
	self._firstLine = self._firstLine - ui.scrollback.lines
	if self._firstLine < 0 then self._firstLine = 0 end
	self:_setDrawColor()
end

function Console:bottom()
	self._firstLine = 0
	self:_setDrawColor()
end

function Console:top()
	self._firstLine = 1+(self._buffer:size() - ui.scrollback.lines)
	self:_setDrawColor()
end

local colorStyles = {}
function Console:print(color, message, ...)
	local style = ui.line.normalStyle

	if type(color) == 'string' and colors[color] then
		color = colors[color]
	end

	if type(color) == 'table' then
		style = colorStyles[color]
		if not style then
			style = ui.line.normalStyle:clone({fontcolor = color})
			colorStyles[color] = style
		end
		self:_print(style, message, ...)
	else
		self:_print(style, color, message, ...)
	end
end

function Console:_print(style, msg, ...)
	if select('#', ...) > 0 then msg = format(msg, ...) end
	local text = self:_makeText(style, msg)
	self:addChild(text)
	self._buffer:push_front(text)

	while self._buffer:size() > ui.scrollback.bufferSize do
		local popped = self._buffer:pop_back()
		self:removeChild(popped)
		popped:destroy()
	end

	if self._firstLine == 0 then
		self._needsUpdate = true
	end

	if self._file then self:log(msg) end
end

function Console:_closeLog()
	if self._file then
		if not self._file:close() then
			warning('Could not close console log')
		end
		self._file = nil
	end
end

-- print to an output file
function Console:log(msg)
	if not self._file:write(format('%s\n', msg)) then
		warning('Could not write to console log')
		self:_closeLog()
	end
end

function Console:_updateForeground()
	local count = ui.scrollback.lines
	local drawY = ui.scrollback.startY
	local skip = 1

	for t in self._buffer:iterate() do
		if skip >= self._firstLine and count > 0 then
			drawY = drawY - ui.line.h
			t:setPosition(ui.scrollback.x, drawY)
			t:show()
			count = count - 1
		else
			t:hide()
		end
		skip = skip + 1
	end
end

-- override Frame:show and hide to register/unregister keys
function Console:show()
	UISystem:registerKeys(ui.keysOnShowID, ui.keysOnShow)
	Frame.show(self)
end
function Console:hide()
	self._commandline:toggleEnterMode(false)
	Frame.hide(self)
	UISystem:unregisterKeys(ui.keysOnShowID)
end

-- make a text line
function Console:_makeText(style, text)
	local f = Text(0, 0, ui.line.w, ui.line.h)
	f:setNormalStyle(style)
	f:setText(text)
	f:hide()

	return f
end

-- callback called when command line is entered
local _commandCB = function(self)
	local cl = self._commandline
	local command, args = self:_parse(concat(cl:getText(), ' '))
	if not command then return end

	cl:clearText()
	cl:toggleEnterMode(true)

	if self:_validateCommand(command) then self:_runCommand(command, args) end
end

-- make the entry line
function Console:_makeEntry()
	self._prompt = Text(ui.prompt.x, ui.prompt.y, ui.prompt.w, ui.prompt.h)
	self._prompt:setNormalStyle(ui.entry.normalStyle)
	self._prompt:setJustifyRight()
	self._prompt:setAlignCenter()
	self._prompt:setMargin(ui.entry.margin)
	self._prompt:setText('>')
	self:addChild(self._prompt)

	self._commandline = TextEntry(ui.entry.x, ui.entry.y, ui.entry.w, ui.entry.h)
	self._commandline:setNormalStyle(ui.entry.normalStyle)
	self._commandline:setAlignCenter()
	self._commandline:setMargin(ui.entry.margin)
	self._commandline:setCallback(_commandCB, self)
	self:addChild(self._commandline)
end

function Console:_parse(command)
	local cmd, args

	for word in gmatch(command, '%s*(%S+)') do
		if cmd then
			args = args or {}
			args[#args+1] = word
		else
			cmd = word
		end
	end

	return cmd, args
end

local sortedCmds = {}
local cmds
cmds = {
	test = {
		run = function(self, ...) self:print('This is a test') end,
	},
	dump = {
		help = 'Dump all entities to console',
		run = function(self, ...)
			InputEvents:notify(InputCommandEvent(command('DUMP_ENTITIES')))
		end,
	},
	stats = {
		help = 'Print stats for an entity (player if no entity given)',
		run = function(self, ...)
			InputEvents:notify(InputCommandEvent(command('PRINT_STATS')))
		end,
	},
	inv = {
		help = 'Print inventory for an entity (player if no entity given)',
		run = function(self, ...)
			InputEvents:notify(InputCommandEvent(command('PRINT_INVENTORY')))
		end,
	},
	quit = {
		help = 'Quit the current game (without saving) and go to the Main Menu',
		run = function(self, ...)
			self:hide()
			InputEvents:notify(InputCommandEvent(command('CONSOLE_CMD_QUIT')))
		end,
	},
	--[[
	['load'] = {
		help = 'Quit the current game (without saving) and load the given file or go to the Load Menu',
		run = function(self, ...)
			self:hide()
			if select('#', ...) > 0 then
				InputEvents:notify(InputCommandEvent(command('CONSOLE_CMD_LOAD'), ...))
			else
				InputEvents:notify(InputCommandEvent(command('MENU_LOAD_GAME')))
			end
		end,
	},
	save = {
		help = 'Save the current game to the given filename, or default filename if none is given',
		run = function(self, ...)
			if select('#', ...) > 0 then
				InputEvents:notify(InputCommandEvent(command('CONSOLE_CMD_SAVE'), ...))
			else
				InputEvents:notify(InputCommandEvent(command('MENU_SAVE_GAME')))
			end
		end,
	},
	]]--
	help = {
		help = 'Show available commands (this list)',
		run = function(self, ...)
			self:print('Commands:')
			local num = #sortedCmds
			for i=1,num do
				local name = sortedCmds[i]
				if name ~= 'help' then self:_printCommandHelp(name) end
			end
			self:_printCommandHelp('help')
		end,
	},
}

for k in pairs(cmds) do
	sortedCmds[#sortedCmds+1] = k
end
table.sort(sortedCmds)


-- print a line of command help
function Console:_printCommandHelp(cmd)
	local help = cmds[cmd].help or ''
	self:print('  %-14s %s', cmd, help)
end

-- validate a command
function Console:_validateCommand(command)
	if command and cmds[command] then return true end
	self:print(colors.RED, 'Unknown command: %s', tostring(command))
end

-- run a command
function Console:_runCommand(command, args)
	local a = args and concat(args, ', ') or 'no args'
	local run = cmds[command].run
	if run then
		run(self, args and unpack(args))
	else
		self:print(colors.RED, 'Command %q has no run method defined!', command)
	end
end


-- the class
return Console
