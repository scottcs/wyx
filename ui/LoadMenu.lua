local ui = {}

local Style = getClass 'wyx.ui.Style'
local command = require 'wyx.ui.command'

local colors = colors
local floor = math.floor

local panelWidth = WIDTH
local panelHeight = HEIGHT

ui.keys = {
	up = command('CURSOR_UP'),
	down = command('CURSOR_DOWN'),
	left = command('CURSOR_LEFT'),
	right = command('CURSOR_RIGHT'),
	escape = {command('EXIT_MENU'), command('CONSOLE_HIDE')},

	['`'] = command('CONSOLE_TOGGLE'),
	f10 = command('CONSOLE_CLEAR'),
	home = command('CONSOLE_TOP'),
	['end'] = command('CONSOLE_BOTTOM'),
	pageup = command('CONSOLE_PAGEUP'),
	pagedown = command('CONSOLE_PAGEDOWN'),
}

ui.panel = {
	x = 0,
	y = 0,
	w = panelWidth,
	h = panelHeight,
	normalStyle = Style({
		bordersize = 4,
		borderinset = 4,
		bordercolor = colors.GREY40,
		bgcolor = colors.GREY20,
	}),
}

-- positions are relative to parent (panel)
local INNERMARGIN = 24
ui.innerpanel = {
	x = INNERMARGIN,
	y = INNERMARGIN,
	w = ui.panel.w - INNERMARGIN*2,
	h = ui.panel.h - INNERMARGIN*2,
	hmargin = 8,  -- horizontal space bewteen child elements
	vmargin = 8,  -- vertical space bewteen child elements
}

local font = GameFont.big

ui.button = {
	w = 220,
	h = font:getHeight() * 2.5,
	normalStyle = Style({
		bordersize = 4,
		bordercolor = colors.GREY60,
		bgcolor = colors.GREY40,
		fontcolor = colors.GREY80,
		font = font,
	}),
}
ui.button.hoverStyle = ui.button.normalStyle:clone({
	fontcolor = colors.ORANGE,
	bordercolor = colors.LIGHTORANGE,
})
ui.button.activeStyle = ui.button.hoverStyle:clone({
	bgcolor = colors.DARKORANGE,
})

ui.buttons = {
	{'Back', command('EXIT_MENU')},
	{'Delete', command('DELETE_GAME')},
	{'Load', command('LOAD_GAME')},
}

ui.loadbutton = {
	w = 236,
	h = 48,
	margin = 8,
	normalStyle = ui.button.normalStyle:clone({font = GameFont.verysmall}),
	hoverStyle = ui.button.hoverStyle:clone({font = GameFont.verysmall}),
	activeStyle = ui.button.activeStyle:clone({font = GameFont.verysmall}),
}

ui.icon = {
	x = 4,
	y = 4,
	w = 40,
	h = 40,
	normalStyle = Style({
		bordersize = 4,
		bordercolor = colors.GREY10,
		bgcolor = colors.BLACK,
		fgcolor = colors.WHITE,
	}),
}


return ui
