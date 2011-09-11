local ui = {}

local Style = getClass 'wyx.ui.Style'
local colors = colors
local floor = math.floor

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

ui.weaponslot = {
	x = 196,
	y = floor(ui.innerpanel.h / 2) - 20,
	w = 40,
	h = 40,
	normalStyle = Style({
		bgimage = Image.interface,
		bgcolor = colors.WHITE,
		fgimage = Image.interface,
		fgcolor = colors.WHITE,
	}),
}
ui.weaponslot.normalStyle:setBGQuad(40, 288, ui.weaponslot.w, ui.weaponslot.h)
ui.weaponslot.normalStyle:setFGQuad(112, 292, 32, 32)

ui.armorslot = {
	x = ui.weaponslot.x + ui.weaponslot.w + 4,
	y = ui.weaponslot.y,
	w = ui.weaponslot.w,
	h = ui.weaponslot.h,
	normalStyle = ui.weaponslot.normalStyle:clone(),
}
ui.armorslot.normalStyle:setFGQuad(144, 292, 32, 32)

ui.ringslot = {
	x = ui.armorslot.x + ui.armorslot.w + 4,
	y = ui.weaponslot.y,
	w = ui.weaponslot.w,
	h = ui.weaponslot.h,
	normalStyle = ui.weaponslot.normalStyle:clone(),
}
ui.ringslot.normalStyle:setFGQuad(176, 292, 32, 32)

ui.invslot = {
	x = ui.ringslot.x + ui.ringslot.w + 18,
	y = ui.weaponslot.y,
	w = ui.weaponslot.w,
	h = ui.weaponslot.h,
	normalStyle = ui.weaponslot.normalStyle:clone(),
}
ui.invslot.normalStyle:setBGQuad(0, 288, ui.invslot.w, ui.invslot.h)
ui.invslot.normalStyle:setFGQuad(80, 292, 32, 32)

ui.floorpanel = {
	x = ui.innerpanel.w - 200,
	y = ui.weaponslot.y,
	w = 200,
	h = ui.weaponslot.h,
	normalStyle = Style({
		bgimage = Image.interface,
		bgcolor = colors.WHITE,
	}),
}
ui.floorpanel.normalStyle:setBGQuad(240, 288,
	ui.floorpanel.w, ui.floorpanel.h)

ui.floorslot = {
	x = 4,
	y = 4,
	w = 32,
	h = 32,
	normalStyle = Style({
		bgimage = Image.interface,
		bgcolor = colors.WHITE,
	}),
}
ui.floorslot.normalStyle:setBGQuad(208, 292, ui.floorslot.w, ui.floorslot.h)

ui.itembutton = {
	w = 32,
	h = 32,
	normalStyle = Style({
		bgimage = Image.item,
		bgcolor = colors.GREY90,
	})
}
ui.itembutton.hoverStyle = ui.itembutton.normalStyle:clone({
	bgcolor = colors.WHITE,
})

return ui
