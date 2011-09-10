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
	borderinset = 4,
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
	self._bottomPanel = nil
	Frame.destroy(self)
end

-- get the width and height of the non-ui view
function InGameUI:getGameSize() return self._viewW, self._viewH end

-- make the bottom panel
function InGameUI:_makeBottomPanel()
	local height = HEIGHT * BOTTOMPANEL_HEIGHT_MULT
	local y = HEIGHT - height
	self._viewH = self._viewH - height

	local f = Frame(0, y, WIDTH, height)
	f:setNormalStyle(panelStyle)

	self:addChild(f)
	self._bottomPanel = f
end

-- set the primary entity (usually the player)
function InGameUI:setPrimeEntity(primeEntity)
	verify('number', primeEntity)
	self._primeEntity = primeEntity

	if self._bottomPanel then
		self._bottomPanel:clear()
	else
		self:_makeBottomPanel()
	end

	self:_makeEntityFrames()
end

-- make all of the frames that depend on the primary entity
function InGameUI:_makeEntityFrames()
	-- make portrait
	-- make name and title
	-- make health bar
	-- make xp bar
	-- make level text
	-- TODO: make status effect icon area
	-- make equipment slots
	-- make inventory slots
	-- make floor slots
end


-- the class
return InGameUI
