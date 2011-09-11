local ui = {}

local Style = getClass 'wyx.ui.Style'
local colors = colors

local panelHeight = 0.125 * HEIGHT

ui.panel = {
	x = 0,
	y = HEIGHT - panelHeight,
	w = WIDTH,
	h = panelHeight,
	normalStyle = Style({
		bordersize = 4,
		borderinset = 4,
		bordercolor = colors.GREY20,
		bgcolor = colors.GREY10,
	}),
}

-- positions are relative to parent (panel)
ui.innerpanel = {
	x = 12,
	y = 12,
	w = WIDTH - 24,
	h = ui.panel.h - 24,
	hmargin = 8,  -- horizontal space bewteen child elements
	vmargin = 2,  -- vertical space bewteen child elements
}

-- Note: position and size of everything below this line is determined at run
-- time.

ui.portrait = {
	normalStyle = Style({
		bordersize = 4,
		bordercolor = colors.GREY70,
		bgcolor = colors.GREY10,
		fgcolor = colors.WHITE,
		fgimage = Image.char,
	}),
}

ui.name = {
	normalStyle = Style({
		font = GameFont.verysmall,
		fontcolor = colors.GREY90,
	}),
}

ui.label = {
	normalStyle = Style({
		font = GameFont.verysmall,
		fontcolor = colors.GREY40,
	}),
}

ui.healthbar = {
	w = 100,
	h = 9,
	normalStyle = Style({
		bgcolor = colors.DARKRED,
		fgcolor = colors.RED,
	}),
	hmargin = 0,
	vmargin = 0,
}

ui.xpbar = {
	w = 100,
	h = 4,
	normalStyle = Style({
		bgcolor = colors.DARKYELLOW,
		fgcolor = colors.YELLOW,
	}),
	hmargin = 0,
	vmargin = 4,
}

return ui
