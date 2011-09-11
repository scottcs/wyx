local Class = require 'lib.hump.class'
local Tooltip = getClass 'wyx.ui.Tooltip'
local Text = getClass 'wyx.ui.Text'
local Bar = getClass 'wyx.ui.Bar'
local Frame = getClass 'wyx.ui.Frame'
local Style = getClass 'wyx.ui.Style'
local property = require 'wyx.component.property'

local math_ceil = math.ceil
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
	font = GameFont.small,
	fontcolor = colors.WHITE,
})

local header2Style = header1Style:clone({
	fontcolor = colors.GREY90,
})

local textStyle = Style({
	font = GameFont.verysmall,
	fontcolor = colors.GREY80,
})

local iconStyle = Style({
	bordersize = 2,
	bordercolor = colors.GREY60,
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
	function(self)
	end
}

-- destructor
function TooltipFactory:destroy()
end

-- make a tooltip for an entity
function TooltipFactory:makeEntityTooltip(entity)
	local entity = type(id) == 'number' and EntityRegistry:get(id) or id
	verifyClass('wyx.entity.Entity', entity)

	local name = entity:getName()
	local family = entity:getFamily()
	local kind = entity:getKind()
	local description = entity:getDescription()
	local headerW = 0

	-- make the icon
	local icon
	local image = entity:query(property('TileSet'))
	if image then
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
				icon = self:_makeIcon(image, x, y, size, size)
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

	-- make the second header
	local header2
	if family and kind then
		local string = family..' ('..kind..')'
		header2 = self:_makeHeader2(string)

		local width = header2:getWidth()
		headerW = width > headerW and width or headerW
	else
		warning('makeEntityTooltip: missing family or kind for entity %q', name)
	end

	headerW = icon and headerW + icon:getWidth() + MARGIN or headerW
	local width = headerW > MINWIDTH and headerW or MINWIDTH

	-- make the health bar
	local health = entity:query(property('Health'))
	local maxHealth = entity:query(property('MaxHealth'))
	local healthBar
	if health and maxHealth then
		healthBar = Bar(0, 0, width, margin)
		healthBar:setNormalStyle(healthBarStyle)
		healthBar:setLimits(0, maxHealth)
		healthBar:setValue(health)
	end

	-- make the stats frames
	-- TODO

	-- make the description
	local body
	if description then
		body = self:_makeText(description, width)
	else
		warning('makeEntityTooltip: missing description for entity %q', name)
	end

	-- make the tooltip
	local tooltip = Tooltip()
	tooltip:setNormalStyle(tooltipStyle)
	tooltip:setMargin(MARGIN)
	if icon then tooltip:setIcon(icon) end
	if header1 then tooltip:setHeader1(header1) end
	if header2 then tooltip:setHeader2(header2) end
	if healthBar then tooltip:addBar(healthBar) end
	if stats then
		for i=1,numStats do
			local stat = stats[i]
			tooltip:addText(stat)
		end
	end
	if body then
		if stats then tooltip:addSpace() end
		tooltip:addText(body)
	end

	return tooltip
end

-- make a simple generic tooltip with a header and text
function TooltipFactory:makeSimpleTooltip(header, text)
	verify('string', header, text)

	local header1 = self:_makeHeader1(header)
	local headerW = header1:getWidth()
	local width = headerW > MINWIDTH and headerW or MINWIDTH
	local body = self:_makeText(text, width)

	local tooltip = Tooltip()
	tooltip:setNormalStyle(tooltipStyle)
	tooltip:setMargin(MARGIN)
	if header1 then tooltip:setHeader1(header1) end
	if body then tooltip:addText(body) end

	return tooltip
end

-- make an icon frame
function TooltipFactory:_makeIcon(image, x, y, w, h)
	local style = iconStyle:clone({fgimage = image})
	style:setFGQuad(x, y, w, h)

	local icon = Frame(0, 0, w, h)
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
function TooltipFactory:_makeText(text, width)
	local font = textStyle:getFont()
	local fontH = font:getHeight()
	local fontW = font:getWidth(text)
	width = width or fontW
	local numLines = math_ceil(fontW / width)

	local line = Text(0, 0, width, numLines * fontH)
	line:setMaxLines(numLines)
	line:setNormalStyle(textStyle)
	line:setText(text)

	return line
end


-- the class
return TooltipFactory
