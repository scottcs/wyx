local ui = {}

local Style = getClass 'wyx.ui.Style'
local command = require 'wyx.ui.command'

local colors = colors
local floor = math.floor

local yOffset = 40
local panelWidth = 0.6 * WIDTH
local panelHeight = 0.75 * HEIGHT

local titleFont = GameFont.bighuge
local titleFontH = titleFont:getHeight()
local titleMargin = 48

ui.title = {
	x = 0,
	y = 0,
	w = WIDTH,
	h = titleFontH + titleMargin*2,
	margin = titleMargin,
	text = '@ Game Menu @',
	normalStyle = Style({
		font = titleFont,
		fontcolor = colors.LIGHTORANGE,
	})
}

ui.keysID = 'PlayMenu'
ui.keys = {
	O = command('MENU_OPTIONS'),
	H = command('MENU_HELP'),
	A = command('DELETE_GAME'),
	S = command('MENU_SAVE_GAME'),
	M = command('MENU_MAIN'),
	escape = command('EXIT_MENU'),
}

ui.screenStyle = Style({
	bgcolor = colors.GREY20,
})

ui.panel = {
	x = floor(WIDTH/2) - floor(panelWidth/2),
	y = HEIGHT - (panelHeight + yOffset),
	w = panelWidth,
	h = panelHeight,
	normalStyle = Style({
		bordersize = 4,
		borderinset = 4,
		bordercolor = colors.GREY30,
		bgcolor = colors.GREY10,
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
	vmargin = 2,  -- vertical space bewteen child elements
}

local font = GameFont.big
local fontH = font:getHeight()

ui.button = {
	w = ui.innerpanel.w,
	h = fontH * 2.5,
	normalStyle = Style({
		bordersize = 4,
		borderinset = 4,
		bordercolor = colors.GREY50,
		bgcolor = colors.GREY30,
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
	{'Options', command('MENU_OPTIONS')},
	{'Help', command('MENU_HELP')},
	{'Abandon Game', command('DELETE_GAME')},
	{'Save and Continue', command('MENU_SAVE_GAME')},
	{'Save and Quit', command('MENU_MAIN')},
}


return ui
