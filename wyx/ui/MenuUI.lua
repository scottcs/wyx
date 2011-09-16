local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Button = getClass 'wyx.ui.Button'
local command = require 'wyx.ui.command'

local floor = math.floor

-- events
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'

-- MenuUI
-- The interface for the main game.
local MenuUI = Class{name='MenuUI',
	inherits=Frame,
	function(self, ui)
		verify('table', ui)

		Frame.construct(self, 0, 0, WIDTH, HEIGHT)

		if ui and ui.keys then UISystem:registerKeys(ui.keys) end
		self._ui = ui

		self:setNormalStyle(ui.screenStyle)
		self:_makePanel()
	end
}

-- destructor
function MenuUI:destroy()
	self._ui = nil
	Frame.destroy(self)
end

-- make the panel
function MenuUI:_makePanel()
	local ui = self._ui

	local f = Frame(ui.panel.x, ui.panel.y, ui.panel.w, ui.panel.h)
	f:setNormalStyle(ui.panel.normalStyle)

	self:addChild(f)
	self._panel = f

	f = Frame(ui.innerpanel.x, ui.innerpanel.y,
		ui.innerpanel.w, ui.innerpanel.h)

	self._panel:addChild(f)
	self._innerPanel = f

	self:_makeButtons()
end

-- make the buttons
function MenuUI:_makeButtons()
	local ui = self._ui

	local x, y = 0, 0
	local num = #ui.buttons
	local dy = floor((ui.innerpanel.h - ui.button.h * num) / (num - 1))
	dy = dy + ui.button.h

	for i=1,num do
		local info = ui.buttons[i]

		local btn = Button(x, y, ui.button.w, ui.button.h)
		btn:setNormalStyle(ui.button.normalStyle)
		btn:setHoverStyle(ui.button.hoverStyle)
		btn:setActiveStyle(ui.button.activeStyle)
		btn:setText(info[1])
		btn:setCallback('l', function(...)
			InputEvents:notify(InputCommandEvent(info[2]))
		end)

		self._innerPanel:addChild(btn)

		y = y + dy
	end
end


-- the class
return MenuUI
