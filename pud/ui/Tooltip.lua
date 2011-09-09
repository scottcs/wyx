local Class = require 'lib.hump.class'
local Frame = getClass 'pud.ui.Frame'
local Text = getClass 'pud.ui.Text'
local Bar = getClass 'pud.ui.Bar'

-- Tooltip
--
local Tooltip = Class{name='Tooltip',
	inherits=Frame,
	function(self, ...)
		Frame.construct(self, ...)
		self:setDepth(5)
		self._margin = 0
		self._show = false
	end
}

-- destructor
function Tooltip:destroy()
	self:clear()
	self._margin = nil
	Frame.destroy(self)
end

-- clear the tooltip
function Tooltip:clear()
	if self._header1 then
		self._header1:destroy()
		self._header1 = nil
	end

	if self._header2 then
		self._header2:destroy()
		self._header2 = nil
	end

	if self._icon then
		self._icon:destroy()
		self._icon = nil
	end

	if self._lines then
		local numLines = #self._lines
		for i=1,numLines do
			self._lines[i]:destroy()
			self._lines[i] = nil
		end
		self._lines = nil
	end
end

-- XXX
-- subclass for entities
-- query entity for icon, name, family, kind, and loop through a list of properties
-- then build tooltip based on these
-- so this class need methods for building the tooltip

--[[
all tooltips have this basic structure:

   -------------------------------
	 | ICON  TEXT (usually Name)   |    }
	 |       TEXT or BLANK SPACE   |    }-  This whole header area is optional
	 | BLANK SPACE                 |    }
	 | TEXT or BAR                 |
	 | TEXT or BAR or BLANK SPACE  |
	 | TEXT or BAR or BLANK SPACE  |
	 | TEXT or BAR or BLANK SPACE  |
	 | ...                         |
	 | TEXT or BAR                 |
	 -------------------------------
]]--

-- set icon
function Tooltip:setIcon(icon)
	verifyClass('pud.ui.Frame', icon)
	if self._icon then self._icon:destroy() end
	self._icon = icon
	self._icon:becomeChild(self, self._depth)
	self:_adjustLayout()
	self:_drawFB()
end

-- set header line 1
function Tooltip:setHeader1(text)
	verifyClass('pud.ui.Text', text)
	if self._header1 then self._header1:destroy() end
	self._header1 = text
	self._header1:becomeChild(self, self._depth)
	self:_adjustLayout()
	self:_drawFB()
end

-- set header line 2
function Tooltip:setHeader2(text)
	verifyClass('pud.ui.Text', text)
	if self._header2 then self._header2:destroy() end
	self._header2 = text
	self._header2:becomeChild(self, self._depth)
	self:_adjustLayout()
	self:_drawFB()
end

-- add a Text
function Tooltip:addText(text)
	verifyClass('pud.ui.Text', text)
	self:_addLine(text)
end

-- add a Bar
function Tooltip:addBar(bar)
	verifyClass('pud.ui.Bar', bar)
	self:_addLine(bar)
end

-- add a blank space
function Tooltip:addSpace()
	local spacing = self:_getSpacing()
	if spacing then
		local space = Frame(0, 0, 0, spacing)
		self:_addLine(space)
	end
end

-- add a line to the tooltip
function Tooltip:_addLine(frame)
	verifyClass('pud.ui.Frame', frame)
	self._lines = self._lines or {}
	self._lines[#self._lines + 1] = frame
	frame:becomeChild(self, self._depth)
	self:_adjustLayout()
	self:_drawFB()
end

-- set the margin between the frame edge and the contents
function Tooltip:setMargin(margin)
	verify('number', margin)
	self._margin = margin
	self:_adjustLayout()
	self:_drawFB()
end

function Tooltip:_adjustLayout()
	local numLines = self._lines and #self._lines or 0

	if self._icon or self._header1 or self._header2 or numLines > 0 then
		local x, y = self._margin, self._margin
		local width, height = 0, 0
		local spacing = self:_getSpacing()

		if spacing then
			local headerW, headerH, iconH = 0, 0, 0

			if self._icon then
				self._icon:setPosition(x, y)

				iconH = self._icon:getHeight()
				width = self._icon:getWidth() + spacing
				x = width
			end

			if self._header1 then
				self._header1:setPosition(x, y)

				headerW = self._header1:getWidth()
				headerH = headerH + spacing
				y = y + spacing
			end

			if self._header2 then
				self._header2:setPosition(x, y)

				local h2width = self._header2:getWidth()
				headerW = headerW > h2width and headerW or h2width
				headerH = headerH + spacing
				y = y + spacing
			end

			width = width + headerW
			height = height + (headerH > iconH and headerH or iconH)

			if numLines > 0 then
				-- set some blank space if any headers exist
				if self._icon or self._header1 or self._header2 then
					height = height + spacing
					y = y + spacing
				end

				x = self._margin

				for i=1,numLines do
					local line = self._lines[i]
					line:setPosition(x, y)

					local lineWidth = line:getWidth()
					width = width > lineWidth and width or lineWidth
					height = height + spacing
					y = y + spacing
				end -- for i=1,num
			end -- if self._lines

			width = width + self._margin*2
			height = height + self._margin*2    -- XXX: might have an extra spacing

			self:setSize(width, height)
			self._ffb, self._bfb = nil, nil
		end -- if spacing
	end -- if self._icon or self._header1 or ...
end

function Tooltip:_getSpacing()
	local spacing
	local normalStyle = self:getNormalStyle()

	if normalStyle then
		local font = normalStyle:getFont()
		if font then spacing = font:getHeight() end
	end

	if nil == spacing then warning('Please set Tooltip normal font style.') end

	return spacing
end


-- draw in the foreground layer
-- draws over any foreground set in the Style. Usually, you just don't want to
-- set a foreground in the Style.
function Tooltip:_drawForeground()
	Frame._drawForeground(self)

	if self._icon then self._icon:draw() end
	if self._header1 then self._header1:draw() end
	if self._header2 then self._header2:draw() end

	local numLines = self._lines and #self._lines or 0
	if numLines > 0 then
		for i=1,numLines do
			local line = self._lines[i]
			line:draw()
		end
	end
end


-- the class
return Tooltip
