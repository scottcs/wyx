local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'
local Button = getClass 'wyx.ui.Button'
local StickyButton = getClass 'wyx.ui.StickyButton'
local TextEntry = getClass 'wyx.ui.TextEntry'
local Bar = getClass 'wyx.ui.Bar'
local Slot = getClass 'wyx.ui.Slot'
local TooltipFactory = getClass 'wyx.ui.TooltipFactory'

local property = require 'wyx.component.property'
local ui = require 'ui.InGameUI'

local vec2_equal = vec2.equal
local math_floor = math.floor
local format = string.format
local getMousePos = love.mouse.getPosition

-- events
local PrimeEntityChangedEvent = getClass 'wyx.event.PrimeEntityChangedEvent'
local TurnCountEvent = getClass 'wyx.event.TurnCountEvent'
local EntityPositionEvent = getClass 'wyx.event.EntityPositionEvent'
local EntityDeathEvent = getClass 'wyx.event.EntityDeathEvent'

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
			EntityDeathEvent,
		})

		self._floorSlots = {}
		self._inventorySlots = {}
		self._equipSlots = {}
		self._tooltipFactory = TooltipFactory()
		self._turns = 1

		UISystem:setNonFrameHoverCallback(self, self._hoverTooltip)
	end
}

-- destructor
function InGameUI:destroy()
	GameEvents:unregisterAll(self)

	self:_clearBottomPanel()

	self._primeEntity = nil
	self._turns = nil
	self._bottomPanel = nil

	self._tooltipFactory:destroy()
	self._tooltipFactory = nil

	if self._hoverTooltips then
		for k,v in pairs(self._hoverTooltips) do
			v:destroy()
			self._hoverTooltips[k] = nil
		end
		self._hoverTooltips = nil
	end

	self._curHoverTooltipID = nil

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

		self:_clearFloorSlots()
		if self._floorSlots then
			local num = #self._floorSlots
			for i=1,num do
				self._floorSlots[i] = nil
			end
			self._floorSlots = nil
		end

		self._innerPanel = nil
		self._bottomPanel:clear()
	end
end

-- set the primary entity (usually the player)
function InGameUI:PrimeEntityChangedEvent(e)
	self._primeEntity = e:getEntity()

	if self._bottomPanel then self:_clearBottomPanel() end

	self:_makeBottomPanel()
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

-- if an entity was destroyed then remove the tooltip
function InGameUI:EntityDeathEvent(e)
	local id = e:getEntity()
	if self._hoverTooltips[id] then
		if self._curHoverTooltipID == id then self._curHoverTooltipID = nil end
		self._hoverTooltips[id]:hide()
		self._hoverTooltips[id]:destroy()
		self._hoverTooltips[id] = nil
	end
end

-- override Frame:onTick()
function InGameUI:onTick(dt)
	Frame.onTick(self, dt)
end

-- make the bottom panel
function InGameUI:_makeBottomPanel()
	local f = Frame(ui.panel.x, ui.panel.y, ui.panel.w, ui.panel.h)
	f:setNormalStyle(ui.panel.normalStyle)

	self:addChild(f)
	self._bottomPanel = f

	f = Frame(ui.innerpanel.x, ui.innerpanel.y,
		ui.innerpanel.w, ui.innerpanel.h)

	self._bottomPanel:addChild(f)
	self._innerPanel = f

	self:_makeEquipSlots()
	self:_makeInventorySlots()
	self:_makeFloorSlots()
end

-- make the equip slot frames
function InGameUI:_makeEquipSlots()
	local slot = Slot(ui.weaponslot.x, ui.weaponslot.y,
		ui.weaponslot.w, ui.weaponslot.h)
	slot:setNormalStyle(ui.weaponslot.normalStyle)
	self._equipSlots[#self._equipSlots + 1] = slot
	self._innerPanel:addChild(slot)

	slot = Slot(ui.armorslot.x, ui.armorslot.y,
		ui.armorslot.w, ui.armorslot.h)
	slot:setNormalStyle(ui.armorslot.normalStyle)
	self._equipSlots[#self._equipSlots + 1] = slot
	self._innerPanel:addChild(slot)

	slot = Slot(ui.ringslot.x, ui.ringslot.y,
		ui.ringslot.w, ui.ringslot.h)
	slot:setNormalStyle(ui.ringslot.normalStyle)
	self._equipSlots[#self._equipSlots + 1] = slot
	self._innerPanel:addChild(slot)
end

-- make the inventory slot frames
function InGameUI:_makeInventorySlots()
	local x, y = ui.invslot.x, ui.invslot.y

	for i=1,10 do
		local slot = Slot(x, y, ui.invslot.w, ui.invslot.h)
		slot:setNormalStyle(ui.invslot.normalStyle)
		self._innerPanel:addChild(slot)
		self._inventorySlots[#self._inventorySlots + 1] = slot
		x = x + ui.invslot.w + 4
	end
end

-- make the floor slot frames
function InGameUI:_makeFloorSlots()
	local f = Frame(ui.floorpanel.x, ui.floorpanel.y,
		ui.floorpanel.w, ui.floorpanel.h)
	f:setNormalStyle(ui.floorpanel.normalStyle)

	local x, y = ui.floorslot.x, ui.floorslot.y
	for i=1,6 do
		local slot = Slot(x, y, ui.floorslot.w, ui.floorslot.h)
		slot:setNormalStyle(ui.floorslot.normalStyle)
		f:addChild(slot)
		self._floorSlots[#self._floorSlots + 1] = slot
		x = x + ui.floorslot.w
	end

	self._innerPanel:addChild(f)
end

-- make all of the frames that depend on the primary entity
function InGameUI:_makeEntityFrames()
	local pe = EntityRegistry:get(self._primeEntity)

	if pe then
		local hmargin = ui.innerpanel.hmargin
		local vmargin = ui.innerpanel.vmargin
		local x, y = 0, 0
		local f

		-- make portrait
		f = self:_makePortrait(pe, x, y)

		-- make name and title
		x = f and x + f:getWidth() + hmargin or x
		f = self:_makeName(pe, x, y)

		-- make health bar
		y = f and y + f:getHeight() + vmargin or y
		f = self:_makeHealthBar(pe, x, y)

		-- make xp bar
		y = f and y + f:getHeight() + vmargin or y
		f = self:_makeXPBar(pe, x, y)

		-- make level text
		x = 0
		f = self:_makeLevelText(pe, x, y)

		-- make turns text
		f = self:_makeTurnsText()
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
				local style = ui.portrait.normalStyle:clone()
				style:setFGQuad(tileX, tileY, size, size)

				local f = Frame(x, y, size, size)
				f:setNormalStyle(style, true)
				self._innerPanel:addChild(f)

				local tooltip = self._tooltipFactory:makeEntityTooltip(pe)
				f:attachTooltip(tooltip)

				return f
			end
		end
	end
end

-- make the name and title frame
function InGameUI:_makeName(pe, x, y)
	local name = pe:getName()
	if name then
		local font = ui.name.normalStyle:getFont()
		local fontH = font:getHeight()
		local fontW = font:getWidth(name)
		local f = Text(x, y, fontW, fontH)

		f:setNormalStyle(ui.name.normalStyle)
		f:setText(name)
		self._innerPanel:addChild(f)

		return f
	end
end

-- make the health bar frame
function InGameUI:_makeHealthBar(pe, x, y)
	local hp = 'HP'
	local font = ui.label.normalStyle:getFont()
	local fontH = font:getHeight()
	local fontW = font:getWidth(hp)

	local barY = math_floor(fontH/2) - math_floor(ui.healthbar.h/2) - 1

	local bar = Bar(0, barY, ui.healthbar.w, ui.healthbar.h)
	bar:setNormalStyle(ui.healthbar.normalStyle)
	bar:setMargins(ui.healthbar.hmargin, ui.healthbar.vmargin)

	local pHealth = property('Health')
	local pHealthB = property('HealthBonus')
	local pMaxHealth = property('MaxHealth')
	local pMaxHealthB = property('MaxHealthBonus')
	local func = function()
		local h = pe:query(pHealth) + pe:query(pHealthB)
		local max = pe:query(pMaxHealth) + pe:query(pMaxHealthB)
		return h, 0, max
	end

	bar:watch(func)

	local text = Text(bar:getWidth() + 4, 0, fontW, fontH)
	text:setNormalStyle(ui.label.normalStyle)
	text:setText(hp)

	local tipfunc = function()
		local h = pe:query(pHealth)
		local hB = pe:query(pHealthB)
		local max = pe:query(pMaxHealth)
		local maxB = pe:query(pMaxHealthB)

		h = h + hB
		max = max + maxB

		return format('%s: %d%s / %d%s', hp,
			h, (hB > 0 and format(' (%+d)', hB) or ''),
			max, (maxB > 0 and format(' (%+d)', maxB) or ''))
	end

	local tooltip = self._tooltipFactory:makeVerySimpleTooltip(tipfunc)
	bar:attachTooltip(tooltip)

	local barH = bar:getHeight() + bar:getY()
	local textH = text:getHeight() + text:getY()
	local h = barH > textH and barH or textH
	local f = Frame(x, y, bar:getWidth() + text:getWidth() + 4, h)

	f:addChild(bar)
	f:addChild(text)

	self._innerPanel:addChild(f)

	return f
end

-- make the xp bar frame
function InGameUI:_makeXPBar(pe, x, y)
	local xp = 'XP'
	local font = ui.label.normalStyle:getFont()
	local fontH = font:getHeight()
	local fontW = font:getWidth(xp)

	local barY = math_floor(fontH/2) - math_floor(ui.xpbar.h/2) - 1

	local bar = Bar(0, barY, ui.xpbar.w, ui.xpbar.h)
	bar:setNormalStyle(ui.xpbar.normalStyle)
	bar:setMargins(ui.xpbar.hmargin, ui.xpbar.vmargin)

	bar:setLimits(0, 100) -- XXX
	bar:setValue(40) -- XXX
	--[[
	local pExperience = property('Experience')
	local pMaxExperience = property('MaxExperience')
	local func = function()
		local x = pe:query(pExperience)
		local max = pe:query(pMaxExperience)
		return x, 0, max
	end

	bar:watch(func)
	--]]

	local text = Text(bar:getWidth() + 4, 0, fontW, fontH)
	text:setNormalStyle(ui.label.normalStyle)
	text:setText(xp)

	local tipfunc = function()
		--[[
		local x = pe:query(pExperience)
		local max = pe:query(pMaxExperience)
		]]--
		local x, max = 40, 100 -- XXX

		return format('%s: %d / %d', xp, x, max)
	end

	local tooltip = self._tooltipFactory:makeVerySimpleTooltip(tipfunc)
	bar:attachTooltip(tooltip)

	local barH = bar:getHeight() + bar:getY()
	local textH = text:getHeight() + text:getY()
	local h = barH > textH and barH or textH
	local f = Frame(x, y, bar:getWidth() + text:getWidth() + 4, h)

	f:addChild(bar)
	f:addChild(text)

	self._innerPanel:addChild(f)

	return f
end

-- make the level text frame
function InGameUI:_makeLevelText(pe, x, y)
	--[[
	local lvl = pe:query(pLevel)
	]]--
	local lvl = 1 -- XXX

	local font = ui.label.normalStyle:getFont()
	local fontH = font:getHeight()
	local string = format('LV %-2d', lvl)
	local fontW = font:getWidth(string)
	local f = Text(x, y, fontW, fontH)

	f:setNormalStyle(ui.label.normalStyle)
	f:setText(string)
	self._innerPanel:addChild(f)

	return f
end

-- make the turns text frame
function InGameUI:_makeTurnsText()
	local font = ui.label.normalStyle:getFont()
	local fontH = font:getHeight()
	local string = format('Turn: %-9d', self._turns)
	local fontW = font:getWidth(string)
	local x = 0
	local y = ui.innerpanel.h - fontH + 2
	local func = function() return format('Turn: %-9d', self._turns) end
	local f = Text(x, y, fontW, fontH)

	f:setNormalStyle(ui.label.normalStyle)
	f:watch(func)
	self._innerPanel:addChild(f)
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
	local num = #self._floorSlots
	for i=1,num do
		local slot = self._floorSlots[i]
		local btn = slot:remove()
		if btn then btn:destroy() end
	end
end

function InGameUI:_findEmptyFloorSlot()
	local num = #self._floorSlots

	for i=1,num do
		local slot = self._floorSlots[i]
		if slot:isEmpty() then return slot end
	end
end

-- add an entity to the next available floor slot
function InGameUI:_addToFloor(item)
	local slot = self:_findEmptyFloorSlot()

	if slot then
		local tilecoords = item:query(property('TileCoords'))
		if tilecoords then
			local coords = tilecoords.item

			if not coords then
				for k in pairs(tilecoords) do coords = tilecoords[k]; break end
			end

			if coords then
				local size = item:query(property('TileSize'))
				if size then
					local x, y = (coords[1]-1) * size, (coords[2]-1) * size
					local normalStyle = ui.itembutton.normalStyle:clone()
					local hoverStyle = ui.itembutton.hoverStyle:clone()

					normalStyle:setBGQuad(x, y, size, size)
					hoverStyle:setBGQuad(x, y, size, size)

					local btn = StickyButton(0, 0, ui.itembutton.w, ui.itembutton.h)
					btn:setNormalStyle(normalStyle, true)
					btn:setHoverStyle(hoverStyle, true)

					local tooltip = self._tooltipFactory:makeEntityTooltip(item)
					btn:attachTooltip(tooltip)

					slot:swap(btn)
				end -- if size
			end -- if coords
		end -- if tilecoords
	end -- if slot
end

-- get the width and height of the non-ui view
function InGameUI:getGameSize()
	local w = WIDTH
	local h = (ui and ui.panel and ui.panel.h) and HEIGHT - ui.panel.h or HEIGHT

	return w, h
end

-- show a tooltip when an entity is hovered
function InGameUI:_hoverTooltip(entityID)
	self._hoverTooltips = self._hoverTooltips or {}

	if self._curHoverTooltipID then
		if self._curHoverTooltipID == entityID then return end

		self._hoverTooltips[self._curHoverTooltipID]:hide()
		self._curHoverTooltipID = nil
	end

	if entityID then
		local f = self._hoverTooltips[entityID]
		if not f then
			local entity = EntityRegistry:get(entityID)
			tooltip = self._tooltipFactory:makeEntityTooltip(entity)

			if tooltip then
				f = Frame(0, 0, 64, 64)
				f:attachTooltip(tooltip)
				self._hoverTooltips[entityID] = f
			end
		end

		if f then
			local x, y = getMousePos()
			f:setPosition(x-32, y-32)
			f:show()
			self._curHoverTooltipID = entityID
		end
	end
end


-- the class
return InGameUI
