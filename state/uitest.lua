
         --[[--
      UI TEST STATE
          ----
  Display some UI stuff.
         --]]--

local st = RunState.new()

local Frame = getClass 'pud.ui.Frame'
local Text = getClass 'pud.ui.Text'
local Button = getClass 'pud.ui.Button'
local TextEntry = getClass 'pud.ui.TextEntry'
local Bar = getClass 'pud.ui.Bar'
local Style = getClass 'pud.ui.Style'

local n1Style = Style({font=GameFont.big, fgcolor=colors.WHITE, bgcolor=colors.DARKRED})
local h1Style = Style({font=GameFont.big, fgcolor=colors.WHITE, bgcolor=colors.LIGHTRED})
local a1Style = Style({font=GameFont.big, fgcolor=colors.WHITE, bgcolor=colors.RED})
local n2Style = Style({font=GameFont.small, fgcolor=colors.WHITE, bgcolor=colors.DARKORANGE})
local h2Style = Style({font=GameFont.small, fgcolor=colors.WHITE, bgcolor=colors.LIGHTORANGE})
local a2Style = Style({font=GameFont.small, fgcolor=colors.WHITE, bgcolor=colors.ORANGE})
local n3Style = Style({font=GameFont.small, fgcolor=colors.WHITE, bgcolor=colors.DARKYELLOW})
local h3Style = Style({font=GameFont.small, fgcolor=colors.WHITE, bgcolor=colors.LIGHTYELLOW})
local a3Style = Style({font=GameFont.small, fgcolor=colors.WHITE, bgcolor=colors.YELLOW})
local n4Style = Style({font=GameFont.verysmall, fgcolor=colors.WHITE, bgcolor=colors.DARKPURPLE})
local h4Style = Style({font=GameFont.verysmall, fgcolor=colors.WHITE, bgcolor=colors.LIGHTPURPLE})
local a4Style = Style({font=GameFont.verysmall, fgcolor=colors.WHITE, bgcolor=colors.PURPLE})

function st:init() end

function st:enter(prevState, nextState, ...)
	self._testFrame = Frame(20, 20, 600, 400)
	self._testFrame:setNormalStyle(n1Style)
	self._testFrame:setHoverStyle(h1Style)
	self._testFrame:setActiveStyle(a1Style)

	local frame2 = Text(20, 20, 560, 360)
	frame2:setNormalStyle(n2Style)
	frame2:setHoverStyle(h2Style)
	frame2:setActiveStyle(a2Style)
	frame2:setMargin(10)
	frame2:setMaxLines(10)
	frame2:setJustifyRight()
	frame2:setAlignCenter()
	frame2:setText({'UI TEST', 'Written by scx', 'for PUD'})

	self._responseText = Text(20, 450, WIDTH-40, n1Style:getFont():getHeight() + 8)
	self._responseText:setNormalStyle(n1Style)
	self._responseText:setMargin(4)

	local button1 = Button(10, 10, 100, n4Style:getFont():getHeight() + 8)
	button1:setNormalStyle(n4Style)
	button1:setHoverStyle(h4Style)
	button1:setActiveStyle(a4Style)
	button1:setText('Button 1')
	button1:setCallback('l', function(mods)
		if mods.shift then self._responseText:setText('shift yeah!')
		elseif mods.ctrl then self._responseText:setText('ctrl woo!')
		else self._responseText:setText('yay!')
		end
	end)

	local button2 = Button(10, 110, 100, n4Style:getFont():getHeight() + 8)
	button2:setNormalStyle(n4Style)
	button2:setHoverStyle(h4Style)
	button2:setActiveStyle(a4Style)
	button2:setText('Button 2')
	button2:setCallback('l', function(mods)
		if mods.shift then self._responseText:setText('it\'s-a-shift-a!')
		elseif mods.ctrl then self._responseText:setText('ctrllllllllll!')
		else self._responseText:setText('click!')
		end
	end)

	local entry1 = TextEntry(10, 300, 200, n3Style:getFont():getHeight() + 8)
	entry1:setNormalStyle(n3Style)
	entry1:setHoverStyle(h3Style)
	entry1:setActiveStyle(a3Style)
	entry1:setMargin(4)
	entry1:setText('ChangeMe')

	frame2:addChild(button1)
	frame2:addChild(button2)
	frame2:addChild(entry1)

	self._testFrame:addChild(frame2)
end

function st:leave() end

function st:destroy() end

function st:update(dt)
	if self._testFrame then self._testFrame:update(dt) end
	if self._responseText then self._responseText:update(dt) end
end

function st:draw()
	if self._testFrame then self._testFrame:draw() end
	if self._responseText then self._responseText:draw() end
end

function st:keypressed(key, unicode)
	if key == 'q' then love.event.push('q') end
end

return st
