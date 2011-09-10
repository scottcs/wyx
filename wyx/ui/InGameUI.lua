local Class = require 'lib.hump.class'
local Style = getClass 'wyx.ui.Style'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'
local Button = getClass 'wyx.ui.Button'
local StickyButton = getClass 'wyx.ui.StickyButton'
local TextEntry = getClass 'wyx.ui.TextEntry'
local Bar = getClass 'wyx.ui.Bar'
local Slot = getClass 'wyx.ui.Slot'
local TooltipFactory = getClass 'wyx.ui.TooltipFactory'

local colors = colors

-- constants
local BOTTOMPANEL_HEIGHT_MULT = 0.1146

-- styles
local panelStyle = Style({
	bordersize = 4,
	bordercolor = colors.GREY20,
	bgcolor = colors.GREY10,
})

-- InGameUI
-- The interface for the main game.
local InGameUI = Class{name='InGameUI',
	inherits=Frame,
	function(self)
		Frame.construct(self, 0, 0, WIDTH, HEIGHT)
		self._viewW, self._viewH = WIDTH, HEIGHT
		self:_makeBottomPanel()
	end
}

-- destructor
function InGameUI:destroy()
	self._viewW = nil
	self._viewH = nil
	Frame.destroy(self)
end

function InGameUI:getGameSize() return self._viewW, self._viewH end

function InGameUI:_makeBottomPanel()
	local height = HEIGHT * BOTTOMPANEL_HEIGHT_MULT
	local y = HEIGHT - height
	self._viewH = self._viewH - height

	local f = Frame(0, y, WIDTH, height)
	f:setNormalStyle(panelStyle)

	self:addChild(f)
end


-- the class
return InGameUI
