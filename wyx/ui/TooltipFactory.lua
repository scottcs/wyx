local Class = require 'lib.hump.class'
local Tooltip = getClass 'wyx.ui.Tooltip'
local Text = getClass 'wyx.ui.Text'
local Bar = getClass 'wyx.ui.Bar'
local Frame = getClass 'wyx.ui.Frame'
local Style = getClass 'wyx.ui.Style'
local property = require 'wyx.component.property'
local depths = require 'wyx.system.renderDepths'

local format = string.format
local math_ceil = math.ceil
local math_floor = math.floor
local colors = colors

-- some constants
local MARGIN = 16
local MINWIDTH = 300

-- Common styles for tooltips
local tooltipStyle = Style({
	bgcolor = colors.BLACK_A85,
	bordersize = 4,
	borderinset = 4,
	bordercolor = colors.GREY30,
})

local header1Style = Style({
	font = GameFont.bigsmall,
	fontcolor = colors.WHITE,
})

local textStyle = Style({
	font = GameFont.verysmall,
	fontcolor = colors.GREY60,
})

local numberStyle = Style({
	font = GameFont.verysmall,
	fontcolor = colors.WHITE,
})

local descriptionStyle = Style({
	font = GameFont.verysmall,
	fontcolor = colors.DARKORANGE,
})

local debugStyle = Style({
	font = GameFont.console,
	fontcolor = colors.PURPLE,
})

local iconStyle = Style({
	bordersize = 4,
	bordercolor = colors.GREY70,
	bgcolor = colors.GREY10,
	fgcolor = colors.WHITE,
})

local healthBarStyle = Style({
	fgcolor = colors.RED,
	bgcolor = colors.DARKRED,
})

-- TooltipFactory
--
local TooltipFactory = Class{name='TooltipFactory',
	function(self, defaultDepth)
		self._defaultDepth = defaultDepth or depths.uitooltip
	end
}

-- destructor
function TooltipFactory:destroy()
	self._defaultDepth = nil
end

-- make a tooltip for an entity
function TooltipFactory:makeEntityTooltip(id, depth)
	local entity
	if type(id) == 'string' then
		EntityRegistry:get(id)
	else
		entity = id
		id = entity:getID()
	end
	verifyClass('wyx.entity.Entity', entity)

	local name = entity:getName()
	local family = entity:getFamily()
	local kind = entity:getKind()
	local etype = entity:getEntityType()
	local description = entity:getDescription()
	local headerW = 0

	-- make the tooltip
	local tooltip = Tooltip()
	tooltip:setDepth(depth or self._defaultDepth)
	tooltip:setNormalStyle(tooltipStyle)
	tooltip:setMargin(MARGIN)

	-- make the icon
	local icon
	local tileset = entity:query(property('TileSet'))
	if tileset then
		local image = Image[tileset]
		local allcoords = entity:query(property('TileCoords'))
		local coords
		local coords = allcoords.item
			or allcoords.front
			or allcoords.right
			or allcoords.left

		if not coords then
			for k in pairs(allcoords) do coords = allcoords[k]; break end
		end

		if coords then
			local size = entity:query(property('TileSize'))
			if size then
				local x, y = (coords[1]-1) * size, (coords[2]-1) * size
				icon = self:_makeIcon(image, x, y, size, size, size+8, size+8)
			else
				warning('makeEntityTooltip: bad TileSize property in entity %q', name)
			end
		else
			warning('makeEntityTooltip: bad TileCoords property in entity %q', name)
		end
	else
		warning('makeEntityTooltip: bad TileSet property in entity %q', name)
	end

	-- make the first header
	local header1
	if name then
		header1 = self:_makeHeader1(name)
		headerW = header1:getWidth()
	else
		warning('makeEntityTooltip: bad Name for entity %q', tostring(entity))
	end

	-- make the family and kind line
	local famLine
	if family and kind then
		local string = family..' ('..kind..')'
		famLine = self:_makeText(string)
		local w = famLine:getWidth()
		headerW = w > headerW and w or headerW
	else
		warning('makeEntityTooltip: missing family or kind for entity %q', name)
	end

	headerW = icon and headerW + icon:getWidth() + MARGIN or headerW
	local width = headerW > MINWIDTH and headerW or MINWIDTH

	-- show id and position if debugging
	local debugLine
	if debugTooltips then
		local pos = entity:query(property('Position'))
		local x, y = -1, -1
		x = (pos and pos[1]) and pos[1] or x
		y = (pos and pos[2]) and pos[2] or y
		local string = format('{%08s} (%d,%d)', id, x, y)
		debugLine = self:_makeText(string, width, debugStyle)
	end

	-- make the health bar
	local pHealth = property('Health')
	local pHealthB = property('HealthBonus')
	local pMaxHealth = property('MaxHealth')
	local pMaxHealthB = property('MaxHealthBonus')
	local health = entity:query(pHealth)
	local maxHealth = entity:query(pMaxHealth)
	local healthBar

	if health and maxHealth and etype ~= 'item' then
		healthBar = Bar(0, 0, width, 9)
		healthBar:setNormalStyle(healthBarStyle)

		local func = function()
			local h = entity:query(pHealth) + entity:query(pHealthB)
			local max = entity:query(pMaxHealth) + entity:query(pMaxHealthB)
			return h, 0, max
		end

		healthBar:watch(func)
	end

	-- make the stats frames
	local stats = {}
	local baseline = etype == 'item' and 0 or nil
	local spdBaseline = etype == 'item' and 100 or nil

	if etype == 'item' then
		f = self:_makeStatText('Health', entity, width, baseline)
		if f then stats[#stats+1] = f end

		f = self:_makeStatText('MaxHealth', entity, width, baseline)
		if f then stats[#stats+1] = f end
	end

	local f = self:_makeStatText('Attack', entity, width, baseline)
	if f then stats[#stats+1] = f end

	f = self:_makeStatText('Defense', entity, width, baseline)
	if f then stats[#stats+1] = f end

	f = self:_makeDamageText(entity, width)
	if f then stats[#stats+1] = f end

	f = self:_makeStatText('Visibility', entity, width, baseline)
	if f then stats[#stats+1] = f end

	f = self:_makeStatText('Speed', entity, width, spdBaseline)
	if f then stats[#stats+1] = f end

	f = self:_makeStatText('AttackCost', entity, width, spdBaseline)
	if f then stats[#stats+1] = f end

	f = self:_makeStatText('MoveCost', entity, width, spdBaseline)
	if f then stats[#stats+1] = f end

	-- make the description
	local body
	if description then
		body = self:_makeText(description, width, descriptionStyle)
	else
		warning('makeEntityTooltip: missing description for entity %q', name)
	end

	if icon then tooltip:setIcon(icon) end
	if header1 then tooltip:setHeader1(header1) end
	if famLine then tooltip:setHeader2(famLine) end
	if healthBar then
		tooltip:addBar(healthBar)
		tooltip:addSpace()
	end
	if stats then
		tooltip:addSpace()
		local numStats = #stats
		for i=1,numStats do
			local stat = stats[i]
			tooltip:addText(stat)
		end
	end
	if body then
		if stats then tooltip:addSpace() end
		tooltip:addText(body)
	end
	if debugLine then
		tooltip:addSpace()
		tooltip:addText(debugLine)
	end

	return tooltip
end

-- make a simple generic tooltip with text
function TooltipFactory:makeVerySimpleTooltip(text, depth)
	verifyAny(text, 'string', 'function')

	local body = self:_makeText(text)

	local tooltip = Tooltip()
	tooltip:setDepth(depth or self._defaultDepth)
	tooltip:setNormalStyle(tooltipStyle)
	tooltip:setMargin(MARGIN)
	if body then tooltip:addText(body) end

	return tooltip
end

-- make a simple generic tooltip with a header and text
function TooltipFactory:makeSimpleTooltip(header, text, depth)
	verify('string', header)
	verifyAny(text, 'string', 'function')

	local header1 = self:_makeHeader1(header)
	local headerW = header1:getWidth()
	local width = headerW > MINWIDTH and headerW or MINWIDTH
	local body = self:_makeText(text, width)

	local tooltip = Tooltip()
	tooltip:setDepth(depth or self._defaultDepth)
	tooltip:setNormalStyle(tooltipStyle)
	tooltip:setMargin(MARGIN)
	if header1 then tooltip:setHeader1(header1) end
	if body then tooltip:addText(body) end

	return tooltip
end

-- make an icon frame
function TooltipFactory:_makeIcon(image, x, y, w, h, fw, fh)
	local style = iconStyle:clone({fgimage = image})
	style:setFGQuad(x, y, w, h)

	fw = fw or w
	fh = fh or h

	local icon = Frame(0, 0, fw, fh)
	icon:setNormalStyle(style, true)

	return icon
end

-- make a header1 Text frame
function TooltipFactory:_makeHeader1(text)
	local font = header1Style:getFont()
	local fontH = font:getHeight()
	local width = font:getWidth(text)

	local header1 = Text(0, 0, width, fontH)
	header1:setNormalStyle(header1Style)
	header1:setText(text)

	return header1
end

-- make a header2 Text frame
function TooltipFactory:_makeHeader2(text)
	local font = header2Style:getFont()
	local fontH = font:getHeight()
	local width = font:getWidth(text)

	local header2 = Text(0, 0, width, fontH)
	header2:setNormalStyle(header2Style)
	header2:setText(text)

	return header2
end

-- make a generic Text frame
function TooltipFactory:_makeText(text, width, style)
	local isString = type(text) == 'string'

	local font = textStyle:getFont()
	local fontH = font:getHeight()
	local fontW = isString and font:getWidth(text) or font:getWidth(text())*2
	width = width or fontW
	local numLines = math_ceil(fontW / width)

	local line = Text(0, 0, width, numLines * fontH)
	line:setMaxLines(numLines)
	if numLines == 1 then line:setJustifyCenter() end
	style = style or textStyle
	line:setNormalStyle(style)

	if isString then line:setText(text) else line:watch(text) end

	return line
end

function TooltipFactory:_makeStatText(prop, entity, width, baseline)
	local pMin = property(prop)
	local bonus = prop..'Bonus'
	local pMax = property.isproperty(bonus) and bonus or nil
	local stat = entity:query(pMin)
	local statB = pMax and entity:query(pMax) or nil
	local text

	if (stat and stat ~= baseline) or (statB and statB ~= 0) then
		local func = function()
			local s = entity:query(pMin)
			local sB = pMax and entity:query(pMax) or nil

			s = (s and s ~= baseline) and s or nil
			sB = (sB and sB ~= 0) and sB or nil

			if s and sB then
				s = s + sB
				return format('%d (%+d)', s, sB)
			elseif sB then
				return format('%+d', sB)
			elseif s then
				return format('%d', s)
			else
				return format('huh?')
			end
		end

		local halfWidth = math_floor(width * 0.48)

		local nameText = self:_makeText(prop..':', halfWidth)
		nameText:setJustifyRight()
		nameText:setPosition(0,0)

		local statText = self:_makeText(func, halfWidth, numberStyle)
		statText:setJustifyLeft()
		statText:setPosition(nameText:getWidth()+4,0)

		text = Text(0, 0, width, nameText:getHeight())
		text:addChild(nameText)
		text:addChild(statText)
	end

	return text
end

function TooltipFactory:_makeDamageText(entity, width)
	local pMin = property('_DamageMin')
	local pMax = property('_DamageMax')
	local min = entity:query(pMin)
	local max = entity:query(pMax)
	local text

	if min ~= 0 and max ~= 0 or entity:getEntityType() ~= 'item' then
		local func = function()
			local min = entity:query(pMin)
			local max = entity:query(pMax)

			min = min or 1
			max = max or 1
			min = min < 1 and 1 or min
			max = max > min and max or min

			if min == max then
				return format('%.1f', min)
			else
				return format('%.1f - %.1f', min, max)
			end
		end

		local halfWidth = math_floor(width * 0.48)

		local nameText = self:_makeText('Damage:', halfWidth)
		nameText:setJustifyRight()
		nameText:setPosition(0,0)

		local damageText = self:_makeText(func, halfWidth, numberStyle)
		damageText:setJustifyLeft()
		damageText:setPosition(nameText:getWidth()+4,0)

		text = Text(0, 0, width, nameText:getHeight())
		text:addChild(nameText)
		text:addChild(damageText)
	end

	return text
end


-- the class
return TooltipFactory
