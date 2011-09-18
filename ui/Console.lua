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

ui.keys = {
	['`'] = command('CONSOLE_TOGGLE'),
}

ui.keysOnShow = {
	up = command('CURSOR_UP'),
	down = command('CURSOR_DOWN'),
	left = command('CURSOR_LEFT'),
	right = command('CURSOR_RIGHT'),

	escape = command('CONSOLE_HIDE'),
	f10 = command('CONSOLE_CLEAR'),
	home = command('CONSOLE_TOP'),
	['end'] = command('CONSOLE_BOTTOM'),
	pageup = command('CONSOLE_PAGEUP'),
	pagedown = command('CONSOLE_PAGEDOWN'),
}

ui.screen = {
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
	normalcolor = colors.WHITE,
	scrollcolor = colors.LIGHTORANGE,
	normalStyle = Style({
		font = font,
		fontcolor = colors.GREY80,
	}),
}

ui.entry = {
	x = 0,
	y = ui.scollback.h + margin,
	w = ui.scrollback.w,
	h = entryH,
	normalStyle = ui.scrollback.normalStyle:clone({fontcolor = colors.WHITE}),
}
ui.entry.activeStyle = ui.entry.normalStyle:clone({bgcolor = colors.GREY20})


return ui
