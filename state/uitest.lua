
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
local n3Style = Style({font=GameFont.small, fgcolor=colors.BLACK, bgcolor=colors.DARKYELLOW})
local h3Style = Style({font=GameFont.small, fgcolor=colors.BLACK, bgcolor=colors.LIGHTYELLOW})
local a3Style = Style({font=GameFont.small, fgcolor=colors.BLACK, bgcolor=colors.YELLOW})
local n4Style = Style({font=GameFont.verysmall, fgcolor=colors.WHITE, bgcolor=colors.DARKPURPLE})
local h4Style = Style({font=GameFont.verysmall, fgcolor=colors.WHITE, bgcolor=colors.LIGHTPURPLE})
local a4Style = Style({font=GameFont.verysmall, fgcolor=colors.WHITE, bgcolor=colors.PURPLE})
local nBarStyle = Style({font=GameFont.verysmall, fgcolor=colors.BLUE, bgcolor=colors.DARKBLUE})
local hBarStyle = Style({font=GameFont.verysmall, fgcolor=colors.LIGHTBLUE, bgcolor=colors.DARKBLUE})

function st:init() end

function st:enter(prevState, nextState, ...)
	self._testFrame = Frame(20, 20, 600, 400)
	self._testFrame:setNormalStyle(n1Style)
	self._testFrame:setHoverStyle(h1Style)
	self._testFrame:setActiveStyle(a1Style)

	self._testFrame2 = Frame(20, 450, WIDTH-40, 60)

	self._responseText = Text(20, 600, WIDTH-40, n1Style:getFont():getHeight() + 8)
	self._responseText:setNormalStyle(n1Style)
	self._responseText:setMargin(4)

	local text1 = Text(20, 20, 560, 360)
	text1:setNormalStyle(n2Style)
	text1:setHoverStyle(h2Style)
	text1:setActiveStyle(a2Style)
	text1:setMargin(10)
	text1:setMaxLines(10)
	text1:setJustifyRight()
	text1:setAlignCenter()
	text1:setText({'UI TEST', 'Written by scx', 'for PUD'})

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

	local button2 = Button(10, 60, 100, n4Style:getFont():getHeight() + 8)
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

	local entry1 = TextEntry(10, 300, 300, n3Style:getFont():getHeight() + 8)
	entry1:setNormalStyle(n3Style)
	entry1:setHoverStyle(h3Style)
	entry1:setActiveStyle(a3Style)
	entry1:setMargin(4)
	entry1:setText('EditBox')

	local someval = 100
	local text2 = Text(10, 120, 300, n4Style:getFont():getHeight() + 8)
	text2:setNormalStyle(n4Style)
	text2:setMargin(4)
	text2:watch(function(s)
		local text = entry1:getText() or {}
		text[1] = (s or '')..(text[1] or '')
		return text
	end, 'Watched: ')

	local bar1 = Bar(10, 180, 200, 20)
	bar1:setNormalStyle(nBarStyle)
	bar1:setHoverStyle(hBarStyle)
	bar1:setLimits(0, 100)
	bar1:setValue(someval)
	bar1:watch(function()
		someval = someval >= 0 and someval - 0.5 or 100
		return someval
	end)

	text1:addChild(button1)
	text1:addChild(button2)
	text1:addChild(text2)
	text1:addChild(entry1)
	text1:addChild(bar1)
	self._testFrame:addChild(text1)


	local cwidth = n3Style:getFont():getWidth('>') + 8
	local cheight = n3Style:getFont():getHeight() + 8
	local commandPrompt = Text(0, 0, cwidth, cheight)
	commandPrompt:setNormalStyle(n3Style)
	commandPrompt:setHoverStyle(h3Style)
	commandPrompt:setActiveStyle(a3Style)
	commandPrompt:setMargin(4)
	commandPrompt:setText('>')

	local commandEntry = TextEntry(cwidth, 0, WIDTH-(40+cwidth), cheight)
	commandEntry:setNormalStyle(n3Style)
	commandEntry:setHoverStyle(h3Style)
	commandEntry:setActiveStyle(a3Style)
	commandEntry:setMargin(4)
	commandEntry:setCallback(function(e)
		self._responseText:setText(table.concat(e:getText(), ' '))
		e:clear()
	end, commandEntry)

	self._testFrame2:addChild(commandPrompt)
	self._testFrame2:addChild(commandEntry)
end

function st:leave() end

function st:destroy() end

function st:update(dt)
	if self._testFrame then self._testFrame:update(dt) end
	if self._responseText then self._responseText:update(dt) end
	if self._testFrame2 then self._testFrame2:update(dt) end
end

function st:draw()
	if self._testFrame then self._testFrame:draw() end
	if self._responseText then self._responseText:draw() end
	if self._testFrame2 then self._testFrame2:draw() end
end

function st:keypressed(key, unicode)
	if key == 'q' then love.event.push('q') end
end

return st
