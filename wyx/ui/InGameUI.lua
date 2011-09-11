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
local property = require 'wyx.component.property'

-- events
local PrimeEntityChangedEvent = getClass 'wyx.event.PrimeEntityChangedEvent'
local TurnCountEvent = getClass 'wyx.event.TurnCountEvent'

local colors = colors
local vec2_equal = vec2.equal

-- constants
local BOTTOMPANEL_HEIGHT_MULT = 0.125
local BOTTOMPANEL_MARGIN = 12

-- styles
local panelStyle = Style({
	bordersize = 4,
	borderinset = 4,
	bordercolor = colors.GREY20,
	bgcolor = colors.GREY10,
})

local portraitStyle = Style({
	bordersize = 4,
	bordercolor = colors.GREY70,
	bgcolor = colors.GREY10,
	fgcolor = colors.WHITE,
	fgimage = Image.char,
})

local nameStyle = Style({
	font = GameFont.verysmall,
	fontcolor = colors.GREY90,
})


-- InGameUI
-- The interface for the main game.
local InGameUI = Class{name='InGameUI',
	inherits=Frame,
	function(self)
		Frame.construct(self, 0, 0, WIDTH, HEIGHT)
		GameEvents:register(self, {
			PrimeEntityChangedEvent,
			TurnCountEvent,
			EntityPositionEvent,
		})

		self._turns = 0
		self._viewW, self._viewH = WIDTH, HEIGHT
		self:_makeBottomPanel()
	end
}

-- destructor
function InGameUI:destroy()
	GameEvents:unregisterAll(self)

	self:_clearBottomPanel()

	self._primeEntity = nil
	self._turns = nil
	self._viewW = nil
	self._viewH = nil
	self._bottomPanel = nil
	Frame.destroy(self)
end

function InGameUI:_clearBottomPanel()
	if self._bottomPanel then
		-- Note: all of bottomPanel's children will be destroyed with clear()
		-- at the bottom of this method

		if self._equipSlots then
			local num = #self._equipSlots
			for i=1,num do
				self._equipSlots[i] = nil
			end
			self._equipSlots = nil
		end

		if self._inventorySlots then
			local num = #self._inventorySlots
			for i=1,num do
				self._inventorySlots[i] = nil
			end
			self._inventorySlots = nil
		end

		if self._floorSlots then
			local num = #self._floorSlots
			for i=1,num do
				self._floorSlots[i] = nil
			end
			self._floorSlots = nil
		end

		self._peLevel = nil
		self._peHealth = nil
		self._peXP = nil

		self._bottomPanel:clear()
	end
end

-- set the primary entity (usually the player)
function InGameUI:PrimeEntityChangedEvent(e)
	self._primeEntity = e:getEntity()

	if self._bottomPanel then
		self._bottomPanel:clear()
	else
		self:_makeBottomPanel()
	end

	self:_makeEntityFrames()
end

-- set the turn count
function InGameUI:TurnCountEvent(e)
	self._turns = e:getTurnCount()
end

-- if our prime entity moved, update the floor slots
function InGameUI:EntityPositionEvent(e)
	local id = e:getEntity()
	if id ~= self._primeEntity then return end
	self:_updateFloorSlots()
end

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

-- make the equip slot frames
function InGameUI:_makeEquipSlots()
	-- TODO
end

-- make the inventory slot frames
function InGameUI:_makeInventorySlots()
	-- TODO
end

-- make the floor slot frames
function InGameUI:_makeFloorSlots()
	-- TODO
end

-- make all of the frames that depend on the primary entity
function InGameUI:_makeEntityFrames()
	local pe = EntityRegistry:get(self._primeEntity)

	if pe then
		local innermargin = 8
		local x, y = BOTTOMPANEL_MARGIN, BOTTOMPANEL_MARGIN
		local f

		-- make portrait
		f = self:_makePortrait(pe, x, y)

		-- make name and title
		x = f and x + f:getWidth() + innermargin or x
		f = self:_makeName(pe, x, y)

		-- make health bar
		y = f and y + f:getHeight() + innermargin or y
		f = self:_makeHealthBar(pe, x, y)

		-- make xp bar
		y = f and y + f:getHeight() + innermargin or y
		f = self:_makeXPBar(pe, x, y)

		-- make level text
		x = BOTTOMPANEL_MARGIN
		f = self:_makeLevelText(pe, x, y)

		-- TODO: make status effect icon area

		-- fill equip slots

		-- fill inventory slots

		-- make tooltips

	end
end

-- make the portrait frame
function InGameUI:_makePortrait(pe, x, y)
	local tilecoords = pe:query(property('TileCoords'))
	if tilecoords then
		local coords = tilecoords.front or tilecoords.right or tilecoords.left
		if not coords then
			for k in pairs(tilecoords) do coords = tilecoords[k]; break end
		end

		if coords then
			local size = pe:query(property('TileSize'))
			if size then
				local tileX = ((coords[1] - 1) * size) - 4
				local tileY = ((coords[2] - 1) * size) - 4
				local style = portraitStyle:clone()
				style:setFGQuad(tileX, tileY, size, size)

				local f = Frame(x, y, size, size)
				f:setNormalStyle(style, true)
				self._bottomPanel:addChild(f)

				return f
			end
		end
	end
end

-- make the name and title frame
function InGameUI:_makeName(pe, x, y)
	local name = pe:getName()
	if name then
		local font = nameStyle:getFont()
		local fontH = font:getHeight()
		local fontW = font:getWidth(name)
		local f = Text(x, y, fontW, fontH)

		f:setNormalStyle(nameStyle)
		f:setText(name)
		self._bottomPanel:addChild(f)

		return f
	end
end

-- make the health bar frame
function InGameUI:_makeHealthBar(pe, x, y)
	-- TODO
end

-- make the xp bar frame
function InGameUI:_makeXPBar(pe, x, y)
	-- TODO
end

-- make the level text frame
function InGameUI:_makeLevelText(pe, x, y)
	-- TODO
end

-- check for items at the primeEntity's feet and load them into floor slots
function InGameUI:_updateFloorSlots()
	local items = EntityRegistry:getIDsByType('item')
	local pIsContained = property('IsContained')
	local pPosition = property('Position')

	if items then
		self:_clearFloorSlots()
		local primeEntity = EntityRegistry:get(self._primeEntity)
		local num = #items

		for i=1,num do
			local id = items[i]
			local item = EntityRegistry:get(id)

			if not item:query(pIsContained) then
				local ipos = item:query(pPosition)
				local epos = primeEntity:query(pPosition)

				if vec2_equal(ipos[1], ipos[2], epos[1], epos[2]) then
					self:_addToFloor(item)
				end
			end
		end
	end
end

-- clear all the floor slots
function InGameUI:_clearFloorSlots()
	-- TODO
end

-- add an entity to the next available floor slot
function InGameUI:_addToFloor(item)
	-- TODO
end

-- get the width and height of the non-ui view
function InGameUI:getGameSize() return self._viewW, self._viewH end


-- the class
return InGameUI
