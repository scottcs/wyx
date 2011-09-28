local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local CheckButton = getClass 'wyx.ui.CheckButton'
local Button = getClass 'wyx.ui.Button'
local Text = getClass 'wyx.ui.Text'
local TextEntry = getClass 'wyx.ui.TextEntry'
local property = require 'wyx.component.property'
local command = require 'wyx.ui.command'
local depths = require 'wyx.system.renderDepths'

local floor = math.floor
local gsub = string.gsub
local match = string.match
local format = string.format

local DEFAULT_NAME = 'Unnamed Adventurer'

-- events
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'

-- CreateCharUI
local CreateCharUI = Class{name='CreateCharUI',
	inherits=Frame,
	function(self, ui)
		verify('table', ui)

		Frame.construct(self, 0, 0, WIDTH, HEIGHT)
		self:setDepth(depths.menu)

		self._name = DEFAULT_NAME

		if ui and ui.keys then
			UISystem:registerKeys(ui.keysID, ui.keys)
			self._uikeys = true
		end
		self._ui = ui

		self:_makePanel()
	end
}

-- destructor
function CreateCharUI:destroy()
	if self._uikeys then
		UISystem:unregisterKeys(self._ui.keysID)
		self._uikeys = nil
	end

	if self._checkButtons then
		for i=1,#self._checkButtons do
			self._checkButtons[i] = nil
		end
		self._checkButtons = nil
	end

	for k in pairs(self._charTable) do self._charTable[k] = nil end
	self._charTable = nil

	self._ui = nil
	self._selectedChar = nil
	self._name = nil
	Frame.destroy(self)
end

-- make the panel
function CreateCharUI:_makePanel()
	local ui = self._ui

	local f = Frame(ui.panel.x, ui.panel.y, ui.panel.w, ui.panel.h)
	f:setNormalStyle(ui.panel.normalStyle)

	self:addChild(f)
	self._panel = f

	f = Frame(ui.innerpanel.x, ui.innerpanel.y,
		ui.innerpanel.w, ui.innerpanel.h)

	self._panel:addChild(f)
	self._innerPanel = f

	self:_makeCharButtons()
	self:_makeButtons()
	self:_makeNamePanel()
end

-- make the buttons to choose the char
function CreateCharUI:_makeCharButtons()
	local ui = self._ui

	self:_loadCharTable()

	if self._charTable then
		local x, y = 0, 0
		local dx = ui.charbutton.w + ui.innerpanel.hmargin
		local dy = ui.charbutton.h + ui.innerpanel.vmargin

		local num = #self._charTable
		for i=1,num do
			local info = self._charTable[i]
			local btn = CheckButton(x, y, ui.charbutton.w, ui.charbutton.h)
			btn:setNormalStyle(ui.charbutton.normalStyle)
			btn:setHoverStyle(ui.charbutton.hoverStyle)
			btn:setActiveStyle(ui.charbutton.activeStyle)
			btn:setMaxLines(2)
			btn:setMargin(ui.charbutton.margin)
			local gender = info.variation == 1 and 'Male' or 'Female'
			btn:setText({info.name, gender})
			btn:setJustifyRight()

			local icon = self:_makeIcon(info)
			if icon then btn:addChild(icon) end

			btn:setCheckedCallback(function(checked)
				if checked then
					self._selectedChar = info
					self:_uncheckAllBut(btn)
				end
			end)

			self._innerPanel:addChild(btn)
			self._checkButtons = self._checkButtons or {}
			self._checkButtons[#self._checkButtons + 1] = btn

			x = x + dx
			if x + dx > ui.innerpanel.w  then
				x = 0
				y = y + dy
			end
		end
	end
end

function CreateCharUI:_uncheckAllBut(btn)
	if self._checkButtons then
		local num = #self._checkButtons
		for i=1,num do
			local button = self._checkButtons[i]
			if button ~= btn then button:uncheck() end
		end
	end
end

function CreateCharUI:_makeIcon(info)
	if not (info.components and info.components.GraphicsComponent) then
		return nil
	end
	local ui = self._ui
	local gc = info.components.GraphicsComponent

	local tileset = gc[property('TileSet')] or property.default('TileSet')
	local image = Image[tileset]
	local size = gc[property('TileSize')] or property.default('TileSize')
	local coords = gc[property('TileCoords')] or property.default('TileCoords')
	local which = coords.front or coords.left or coords.right
	if not which then
		for k in pairs(coords) do
			which = coords[k]
			break
		end
	end

	if which then
		local x, y = (which[1] - 1)*size, (which[2] - 1)*size

		local icon = Frame(ui.icon.x, ui.icon.y, ui.icon.w, ui.icon.h)
		local normalStyle = ui.icon.normalStyle:clone({fgimage = image})
		normalStyle:setFGQuad(x, y, size, size)
		icon:setNormalStyle(normalStyle)

		return icon
	end
end

function CreateCharUI:_loadCharTable()
	self._charTable = {}
	local count = 0

	for char,info in HeroDB:iterate() do
		count = count + 1
		self._charTable[count] = info
	end

	table.sort(self._charTable, function(a, b)
		if a == nil then return true end
		if b == nil then return false end
		if a.name == nil then return true end
		if b.name == nil then return false end
		if a.name == b.name then return a.variation < b.variation end
		return a.name < b.name
	end)
end

-- make the buttons
function CreateCharUI:_makeButtons()
	local ui = self._ui

	local num = #ui.buttons

	local x = floor(ui.innerpanel.w/2)
	x = x - floor((ui.button.w + floor(ui.innerpanel.hmargin/2)) * num/2)
	local y = ui.innerpanel.h - (ui.button.h + ui.innerpanel.vmargin)
	local dx = ui.button.w + ui.innerpanel.hmargin

	for i=1,num do
		local info = ui.buttons[i]

		local btn = Button(x, y, ui.button.w, ui.button.h)
		btn:setNormalStyle(ui.button.normalStyle)
		btn:setHoverStyle(ui.button.hoverStyle)
		btn:setActiveStyle(ui.button.activeStyle)
		btn:setText(info[1])
		btn:setCallback('l', function()
			InputEvents:notify(InputCommandEvent(info[2]))
		end)

		self._innerPanel:addChild(btn)

		x = x + dx
	end
end

function CreateCharUI:_makeNamePanel()
	local ui = self._ui

	local x = floor(ui.innerpanel.w/2)
	x = x - (floor(ui.namepanel.w/2) + floor(ui.innerpanel.hmargin/2))
	local y = ui.innerpanel.h
	y = y - (ui.button.h + ui.innerpanel.vmargin*5 + ui.nameentry.h)

	local namePanel = Frame(x, y, ui.namepanel.w, ui.namepanel.h)
	namePanel:setNormalStyle(ui.namepanel.normalStyle)
	namePanel:setHoverStyle(ui.namepanel.hoverStyle)
	namePanel:hoverWithChildren(true)

	local f = Text(ui.innerpanel.hmargin, ui.innerpanel.vmargin,
		ui.namelabel.w, ui.namelabel.h)
	f:setNormalStyle(ui.namelabel.normalStyle)
	f:setText(ui.namelabel.label)
	f:setJustifyRight()
	f:setAlignCenter()
	namePanel:addChild(f)

	f = TextEntry(ui.innerpanel.hmargin + ui.namelabel.w, ui.innerpanel.vmargin,
		ui.nameentry.w, ui.nameentry.h)
	f:setNormalStyle(ui.nameentry.normalStyle)
	f:setHoverStyle(ui.nameentry.hoverStyle)
	f:setActiveStyle(ui.nameentry.activeStyle)
	f:setDefaultText(self._name)
	f:setJustifyLeft()
	f:setAlignCenter()

	f:setCallback(function()
		local text = f:getText()
		self._name = text and text[1]
	end)

	namePanel:addChild(f)

	self._innerPanel:addChild(namePanel)
end

-- return the currently selected character
function CreateCharUI:getChar()
	local info = self._selectedChar
	if info then info.name = self._name end
	return info
end


-- the class
return CreateCharUI
