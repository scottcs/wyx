local ui = {}

local Style = getClass 'wyx.ui.Style'
local command = require 'wyx.ui.command'

local colors = colors
local floor = math.floor

local font = GameFont.console
local fontH = font:getHeight()
local margin = 8
local entryH = fontH + 2*margin
local panelWidth = WIDTH
local panelHeight = HEIGHT - (entryH + margin)
local lines = floor(panelHeight / fontH) - 2
local startY = floor(panelHeight - (margin + fontH*2))
local bufferSize = 1000

ui.keysID = 'Console'
ui.keys = {
	['`'] = command('CONSOLE_TOGGLE'),
}

ui.keysOnShowID = 'ConsoleShow'
ui.keysOnShow = {
	escape = command('CONSOLE_HIDE'),
	f10 = command('CONSOLE_CLEAR'),
	home = command('CONSOLE_TOP'),
	['end'] = command('CONSOLE_BOTTOM'),
	pageup = command('CONSOLE_PAGEUP'),
	pagedown = command('CONSOLE_PAGEDOWN'),
}

ui.main = {
	x = 0,
	y = 0,
	w = WIDTH,
	h = HEIGHT,
	normalStyle = Style({
		bgcolor = colors.BLACK_A70,
	}),
}

ui.scrollback = {
	x = margin,
	y = margin,
	w = panelWidth,
	h = panelHeight,
	startY = startY,
	lines = lines,
	bufferSize = bufferSize,
	normalcolor = colors.WHITE,
	scrollcolor = colors.LIGHTORANGE,
}

ui.line = {
	w = ui.scrollback.w,
	h = fontH,
	normalStyle = Style({
		font = font,
		fontcolor = colors.GREY80,
	}),
}

ui.entry = {
	x = 0,
	y = ui.scrollback.h + margin,
	w = ui.scrollback.w,
	h = entryH,
	normalStyle = ui.line.normalStyle:clone({fontcolor = colors.WHITE}),
}
ui.entry.activeStyle = ui.entry.normalStyle:clone({bgcolor = colors.GREY20})


return ui
