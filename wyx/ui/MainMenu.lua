local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Button = getClass 'wyx.ui.Button'
local TooltipFactory = getClass 'wyx.ui.TooltipFactory'

local command = require 'wyx.ui.command'
local ui = require 'ui.MainMenu'

local floor = math.floor

-- events
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'

-- MainMenu
-- The interface for the main game.
local MainMenu = Class{name='MainMenu',
	inherits=Frame,
	function(self)
		Frame.construct(self, 0, 0, WIDTH, HEIGHT)

		self._tooltipFactory = TooltipFactory()

		if ui and ui.keys then UISystem:registerKeys(ui.keys) end

		self:_makePanel()
	end
}

-- destructor
function MainMenu:destroy()
	self._tooltipFactory:destroy()
	self._tooltipFactory = nil
	Frame.destroy(self)
end

-- make the panel
function MainMenu:_makePanel()
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
function MainMenu:_makeButtons()
	local x, y = 0, 0
	local num = #ui.buttons
	local dy = floor(ui.innerpanel.h / num)

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
return MainMenu
