local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'
local Bar = getClass 'wyx.ui.Bar'

-- Tooltip
--
local Tooltip = Class{name='Tooltip',
	inherits=Frame,
	function(self, ...)
		Frame.construct(self, ...)
		self._margin = 0

		self:setDepth(5)
		self:hide()
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
	verifyClass('wyx.ui.Frame', icon)
	if self._icon then self._icon:destroy() end
	self._icon = icon
	self._icon:becomeChild(self, self._depth)
	self:_adjustLayout()
	self:_drawFB()
end

-- set header line 1
function Tooltip:setHeader1(text)
	verifyClass('wyx.ui.Text', text)
	if self._header1 then self._header1:destroy() end
	self._header1 = text
	self._header1:becomeChild(self, self._depth)
	self:_adjustLayout()
	self:_drawFB()
end

-- set header line 2
function Tooltip:setHeader2(text)
	verifyClass('wyx.ui.Text', text)
	if self._header2 then self._header2:destroy() end
	self._header2 = text
	self._header2:becomeChild(self, self._depth)
	self:_adjustLayout()
	self:_drawFB()
end

-- add a Text
function Tooltip:addText(text)
	verifyClass('wyx.ui.Text', text)
	self:_addLine(text)
end

-- add a Bar
function Tooltip:addBar(bar)
	verifyClass('wyx.ui.Bar', bar)
	self:_addLine(bar)
end

-- add a blank space
function Tooltip:addSpace(size)
	if nil == size then
		size = self._lines and self._lines[1]:getHeight() or self._margin
	end
	verify('number', size)

	local space = Frame(0, 0, 0, size)
	self:_addLine(space)
end

-- add a line to the tooltip
function Tooltip:_addLine(frame)
	verifyClass('wyx.ui.Frame', frame)
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
		local headerW, headerH, iconH = 0, 0, 0

		if self._icon then
			self._icon:setPosition(x, y)

			iconH = self._icon:getHeight()
			width = self._icon:getWidth() + self._margin
			x = x + width
		end

		if self._header1 then
			self._header1:setPosition(x, y)

			headerW = self._header1:getWidth()
			headerH = self._header1:getHeight()
			y = y + headerH
		end

		if self._header2 then
			self._header2:setPosition(x, y)

			local h2width, h2height = self._header2:getSize()
			headerW = headerW > h2width and headerW or h2width
			headerH = headerH + h2height
			y = y + h2height
		end

		width = width + headerW
		height = height + (headerH > iconH and headerH or iconH)

		if numLines > 0 then
			-- set some blank space if any headers exist
			if self._icon or self._header1 or self._header2 then
				local blankspace = self._lines[1]:getHeight()
				height = height + blankspace
				y = self._margin + height
			end

			x = self._margin

			for i=1,numLines do
				local line = self._lines[i]
				line:setPosition(x, y)

				local lineWidth, lineHeight = line:getSize()
				width = width > lineWidth and width or lineWidth
				height = height + lineHeight
				y = y + lineHeight
			end -- for i=1,num
		end -- if self._lines

		width = width + self._margin*2
		height = height + self._margin*2

		self:setSize(width, height)
		self._ffb, self._bfb = nil, nil
	end -- if self._icon or self._header1 or ...
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
