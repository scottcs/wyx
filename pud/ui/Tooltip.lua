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
	end
}

-- destructor
function Tooltip:destroy()
	self:clear()
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

-- set header line 1
function Tooltip:setHeader1(text)
	verifyClass('pud.ui.Text', text)
	if self._header1 then self._header1:destroy() end
	self._header1 = text
end

-- set header line 2
function Tooltip:setHeader2(text)
	verifyClass('pud.ui.Text', text)
	if self._header2 then self._header2:destroy() end
	self._header2 = text
end

-- set icon
function Tooltip:setIcon(icon)
	verifyClass('pud.ui.Frame', icon)
	if self._icon then self._icon:destroy() end
	self._icon = icon
end

-- add a Text
function Tooltip:addText(text)
end

-- add a Bar
function Tooltip:addBar(bar)
end

-- add a blank space
function Tooltip:addSpace()
	local normalStyle = self:getNormalStyle()
	if not normalStyle then
		warning('Please set Style for Tooltip before adding lines.')
		return
	end

	local font = normalStyle:getFont()
	if not font then
		warning('Please set Tooltip font style before adding lines.')
		return
	end

	local h = font:getHeight()
	local space = Frame(0, 0, 0, h)
	self:_addLine(space)
end

function Tooltip:_addLine(frame)
	verifyClass('pud.ui.Frame', frame)
	self._lines = self._lines or {}
	self._lines[#self._lines + 1] = frame
end

-- draw to framebuffer


-- the class
return Tooltip
