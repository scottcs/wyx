local ui = {}

local Style = getClass 'wyx.ui.Style'
local command = require 'wyx.ui.command'

local colors = colors
local floor = math.floor

local font = GameFont.console
local fontH = font:getHeight()
local margin = 4
local entryH = fontH + 2*margin
local promptW = font:getWidth('>') + 2*margin
local panelWidth = WIDTH - 2*margin
local panelHeight = HEIGHT - (entryH + 2*margin)
local lines = floor(panelHeight / fontH) - 2
local startY = panelHeight - fontH
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
	x = promptW + margin,
	y = ui.scrollback.h + margin,
	w = ui.scrollback.w - promptW,
	h = entryH,
	margin = margin,
	normalStyle = Style({
		fontcolor = colors.WHITE,
		font = font,
		bgcolor = colors.GREY20,
	}),
}

ui.prompt = {
	x = margin,
	y = ui.entry.y,
	w = promptW,
	h = ui.entry.h,
}


return ui
