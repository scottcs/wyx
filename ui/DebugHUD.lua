local ui = {}

local Style = getClass 'wyx.ui.Style'
local command = require 'wyx.ui.command'

local colors = colors
local floor = math.floor

local FONT = GameFont.console
local FONTH = FONT:getHeight()
local MARGIN = 8
local INNERMARGIN = 6

ui.keysID = 'DebugHUD'
ui.keys = {
	['shift-f3'] = command('DEBUG_PANEL_TOGGLE'),
	['shift-f4'] = command('DEBUG_PANEL_RESET'),
	['shift-f5'] = command('COLLECT_GARBAGE'),
}

ui.panel = {
	x = MARGIN,
	y = MARGIN,
	w = WIDTH - 2*MARGIN,
	h = 4*FONTH + 2*MARGIN,
	normalStyle = Style({
		bgcolor = colors.BLUE_A70,
		bordercolor = colors.LIGHTBLUE,
		bordersize = 2,
	}),
}

ui.sideheader = {
	x = INNERMARGIN,
	y = INNERMARGIN,
	w = FONT:getWidth('O')*3,
	h = FONTH,
}

ui.innerpanel = {
	x = ui.sideheader.w + INNERMARGIN*2,
	y = INNERMARGIN,
	w = ui.panel.w - INNERMARGIN*2,
	h = ui.panel.h - INNERMARGIN*2,
	hmargin = 4,  -- horizontal space bewteen child elements
	vmargin = 0,  -- vertical space bewteen child elements
}

ui.text = {
	w = floor(ui.innerpanel.w / 4) - ui.innerpanel.hmargin - ui.sideheader.w,
	h = FONTH,
	normalStyle = Style({
		font = FONT,
		fontcolor = colors.GREY80,
	})
}
ui.text.headerStyle = ui.text.normalStyle:clone({fontcolor = colors.WHITE})
ui.text.goodStyle = ui.text.normalStyle:clone({fontcolor = colors.GREEN})
ui.text.warn1Style = ui.text.normalStyle:clone({fontcolor = colors.YELLOW})
ui.text.warn2Style = ui.text.normalStyle:clone({fontcolor = colors.RED})

ui.headers = {'current', 'warning', 'best', 'worst'}


return ui
