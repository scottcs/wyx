local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local CheckButton = getClass 'wyx.ui.CheckButton'
local Button = getClass 'wyx.ui.Button'
local command = require 'wyx.ui.command'
local depths = require 'wyx.system.renderDepths'

local floor = math.floor
local gsub = string.gsub
local match = string.match
local format = string.format

-- events
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'

-- LoadMenuUI
-- The interface for the main game.
local LoadMenuUI = Class{name='LoadMenuUI',
	inherits=Frame,
	function(self, ui)
		verify('table', ui)

		Frame.construct(self, 0, 0, WIDTH, HEIGHT)
		self:setDepth(depths.menu)

		if ui and ui.keys then
			UISystem:registerKeys(ui.keys)
			self._uikeys = true
		end
		self._ui = ui

		self:_makePanel()
	end
}

-- destructor
function LoadMenuUI:destroy()
	if self._uikeys then
		UISystem:unregisterKeys()
		self._uikeys = nil
	end

	if self._checkButtons then
		for i=1,#self._checkButtons do
			self._checkButtons[i] = nil
		end
		self._checkButtons = nil
	end

	self._fileTable = nil
	self._ui = nil
	self._selectedFile = nil
	Frame.destroy(self)
end

-- make the panel
function LoadMenuUI:_makePanel()
	local ui = self._ui

	local f = Frame(ui.panel.x, ui.panel.y, ui.panel.w, ui.panel.h)
	f:setNormalStyle(ui.panel.normalStyle)

	self:addChild(f)
	self._panel = f

	f = Frame(ui.innerpanel.x, ui.innerpanel.y,
		ui.innerpanel.w, ui.innerpanel.h)

	self._panel:addChild(f)
	self._innerPanel = f

	self:_makeLoadButtons()
	self:_makeButtons()
end

-- make the buttons to choose which file to load
function LoadMenuUI:_makeLoadButtons()
	local ui = self._ui

	self:_loadFileTable()

	if self._fileTable then
		local x, y = 0, 0
		local dx = ui.loadbutton.w + ui.innerpanel.hmargin
		local dy = ui.loadbutton.h + ui.innerpanel.vmargin

		for basename,t in pairs(self._fileTable) do
			local info = t.info
			local sav = t.sav

			if info and sav then
				local btn = CheckButton(x, y, ui.loadbutton.w, ui.loadbutton.h)
				btn:setNormalStyle(ui.loadbutton.normalStyle)
				btn:setHoverStyle(ui.loadbutton.hoverStyle)
				btn:setActiveStyle(ui.loadbutton.activeStyle)
				btn:setMaxLines(2)
				btn:setMargin(ui.loadbutton.margin)
				btn:setText({info.name, format('Turns: %-9d  LV %d',
					info.turns, info.level)})
				btn:setJustifyRight()

				local icon = self:_makeIcon(info)
				if icon then btn:addChild(icon) end

				btn:setCheckedCallback(function(checked)
					if checked then
						self._selectedFile = sav
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
end

function LoadMenuUI:_uncheckAllBut(btn)
	if self._checkButtons then
		local num = #self._checkButtons
		for i=1,num do
			local button = self._checkButtons[i]
			if button ~= btn then button:uncheck() end
		end
	end
end

function LoadMenuUI:_makeIcon(info)
	local ui = self._ui

	local image = Image[info.iconImage]
	local size = info.iconSize
	local coords = info.iconCoords
	local which = coords.item or coords.front or coords.left or coords.right
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

function LoadMenuUI:_loadFileTable()
	local files = love.filesystem.enumerate('save')
	if files then
		self._fileTable = {}
		local num = #files

		for i=1,num do
			local file = files[i]
			local basename = gsub(file, '%.%w%w%w$', '')

			if match(file, '%.wyx$') then
				local info = self:_loadWyx(file)
				if info then
					self._fileTable[basename] = self._fileTable[basename] or {}
					self._fileTable[basename].info = info
				end
			elseif match(file, '%.sav$') then
				self._fileTable[basename] = self._fileTable[basename] or {}
				self._fileTable[basename].sav = file
			end
		end
	end
end

function LoadMenuUI:_loadWyx(wyx)
	local contents = love.filesystem.read('save/'..wyx)
	local ok, err = pcall(loadstring,contents)
	local info

	if ok then
		ok, err = pcall(err)
		if ok then info = err end
	end

	if not ok then
		err = err or ''
		warning(err..' (Wyx file not loaded)')
	end

	return info
end
-- make the buttons
function LoadMenuUI:_makeButtons()
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

-- return the currently selected file
function LoadMenuUI:getSelectedFile()
	local file, wyx

	if self._selectedFile then
		file = format('save/%s', self._selectedFile)
		wyx = gsub(file, '%.sav$', '.wyx')
	end

	return file, wyx
end


-- the class
return LoadMenuUI
