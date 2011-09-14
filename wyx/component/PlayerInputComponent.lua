local Class = require 'lib.hump.class'
local InputComponent = getClass 'wyx.component.InputComponent'
local KeyboardEvent = getClass 'wyx.event.KeyboardEvent'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local message = require 'wyx.component.message'
local property = require 'wyx.component.property'
local command = require 'wyx.ui.command'

local InputEvents = InputEvents
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'

-- PlayerInputComponent
--
local PlayerInputComponent = Class{name='PlayerInputComponent',
	inherits=InputComponent,
	function(self, properties)
		InputComponent.construct(self, properties)
		self:_addMessages('TIME_PRETICK')
		InputEvents:register(self, {KeyboardEvent, InputCommandEvent})
	end
}

-- destructor
function PlayerInputComponent:destroy()
	InputEvents:unregisterAll(self)
	InputComponent.destroy(self)
end

function PlayerInputComponent:_setProperty(prop, data)
	if prop == property('CanOpenDoors') then data = true end
	InputComponent._setProperty(self, prop, data)
end

-- on keyboard input, issue the appropriate command
function PlayerInputComponent:KeyboardEvent(e)
	if PAUSED then return end

	if #(e:getModifiers()) == 0 then
		local key = e:getKey()
		local doTick = false

		if key == '.' or key == 'kp5' or key == ' ' then
			self:_wait()
			doTick = true
		elseif key == 'up' or key == 'k' or key == 'kp8' or key == 'e' then
			self:_attemptMove( 0, -1)
			doTick = true
		elseif key == 'down' or key == 'j' or key == 'kp2' or key == 'd' then
			self:_attemptMove( 0,  1)
			doTick = true
		elseif key == 'left' or key == 'h' or key == 'kp4' or key == 's' then
			self:_attemptMove(-1,  0)
			doTick = true
		elseif key == 'right' or key == 'l' or key == 'kp6' or key == 'f' then
			self:_attemptMove( 1,  0)
			doTick = true
		elseif key == 'y' or key == 'kp7' or key == 'w' then
			self:_attemptMove(-1,  -1)
			doTick = true
		elseif key == 'u' or key == 'kp9' or key == 'r' then
			self:_attemptMove( 1,  -1)
			doTick = true
		elseif key == 'b' or key == 'kp1' or key == 'z' or key == 'x' then
			self:_attemptMove(-1,   1)
			doTick = true
		elseif key == 'n' or key == 'kp3' or key == 'c' or key == 'v' then
			self:_attemptMove( 1,   1)
			doTick = true
			--[[
		elseif key == '>' or key == 'kp+' then
			self:_attemptPortalIn()
			doTick = true
		elseif key == '<' or key == 'kp-' then
			self:_attemptPortalOut()
			doTick = true
		elseif key == 'p' then
			self:_tryToPickup()
			doTick = true
		elseif key == 'd' then
			-- XXX
			local contained = self._mediator:query(property('ContainedEntities'))
			self:_tryToDrop(contained and contained[1] or 1)
			doTick = true
		elseif key == 'e' then
			local contained = self._mediator:query(property('ContainedEntities'))
			local num = contained and #contained or 1
			for i=1,num do
				self:_tryToAttach(contained and contained[i] or 1)
			end
			doTick = true
		elseif key == 'r' then
			local attached = self._mediator:query(property('AttachedEntities'))
			local num = attached and #attached or 1
			for i=1,num do
				self:_tryToDetach(attached and attached[i] or 1)
			end
			doTick = true
			]]--
		elseif key == '-' then
			-- XXX
			local found = false

			local contained = self._mediator:query(property('ContainedEntities'))
			if contained then
				GameEvents:push(ConsoleEvent('Inventory:'))
				found = true
				for i,e in pairs(contained) do
					local entity = EntityRegistry:get(e)
					local equipped = ''
					if entity:query(property('IsAttached')) then
						equipped = ' (equipped)'
					end
					GameEvents:push(ConsoleEvent('   %d - {%08s} %s%s',
						i, e, entity:getName(), equipped))
				end
			end

			if not found then
				GameEvents:push(ConsoleEvent('You have nothing.'))
			end
		elseif key == '=' then
			-- XXX
			local attack = self._mediator:query(property('Attack'))
			local attackBonus = self._mediator:query(property('AttackBonus'))
			attack = attack + attackBonus

			local defense = self._mediator:query(property('Defense'))
			local defenseBonus = self._mediator:query(property('DefenseBonus'))
			defense = defense + defenseBonus

			local speed = self._mediator:query(property('Speed'))
			local speedBonus = self._mediator:query(property('SpeedBonus'))
			speed = speed + speedBonus

			local health = self._mediator:query(property('Health'))
			local healthBonus = self._mediator:query(property('HealthBonus'))
			health = health + healthBonus

			local maxHealth = self._mediator:query(property('MaxHealth'))
			local maxHealthBonus = self._mediator:query(property('MaxHealthBonus'))
			maxHealth = maxHealth + maxHealthBonus

			local visibility = self._mediator:query(property('Visibility'))
			local visibilityBonus = self._mediator:query(property('VisibilityBonus'))
			visibility = visibility + visibilityBonus

			local attackCost = self._mediator:query(property('AttackCost'))
			local attackCostBonus = self._mediator:query(property('AttackCostBonus'))
			attackCost = attackCost + attackCostBonus

			local moveCost = self._mediator:query(property('MoveCost'))
			local moveCostBonus = self._mediator:query(property('MoveCostBonus'))
			moveCost = moveCost + moveCostBonus

			GameEvents:push(ConsoleEvent('Stats:'))
			GameEvents:push(ConsoleEvent('      HP: %d (%+d) / %d (%+d)',
				health, healthBonus, maxHealth, maxHealthBonus))
			GameEvents:push(ConsoleEvent('     Att: %d (%+d)',
				attack, attackBonus))
			GameEvents:push(ConsoleEvent('     Def: %d (%+d)',
				defense, defenseBonus))
			GameEvents:push(ConsoleEvent(
				'     Spd: %d (%+d)  AttCost: %d (%+d)  MovCost: %d (%+d)',
				speed, speedBonus,
				attackCost, attackCostBonus,
				moveCost, moveCostBonus))
			GameEvents:push(ConsoleEvent('     Vis: %d (%+d)',
				visibility, visibilityBonus))
		end

		if doTick then self:_setProperty(property('DoTick'), true) end
	end
end

-- on InputCommandEvent, call the correlating function
function PlayerInputComponent:InputCommandEvent(e)
	local cmd = e:getCommand()
	local args = e:getCommandArgs()
	local doTick = false

	if cmd == command('ATTACH_ENTITY') then
		assert(args and #args == 2,
			'Invalid args for InputCommand ATTACH_ENTITY')
		local id, to = unpack(args)
		if to == self._mediator:getID() then self:_doAttach(id) end
		doTick = true

	elseif cmd == command('DETACH_ENTITY') then
		assert(args and #args == 2,
			'Invalid args for InputCommand DETACH_ENTITY')
		local id, to = unpack(args)
		if to == self._mediator:getID() then self:_doDetach(id) end
		doTick = true

	elseif cmd == command('PICKUP_ENTITY') then
		assert(args and #args == 2,
			'Invalid args for InputCommand PICKUP_ENTITY')
		local id, to = unpack(args)
		if to == self._mediator:getID() then self:_doPickup(id) end
		doTick = true

	elseif cmd == command('DROP_ENTITY') then
		assert(args and #args == 2,
			'Invalid args for InputCommand DROP_ENTITY')
		local id, to = unpack(args)
		if to == self._mediator:getID() then self:_doDrop(id) end
		doTick = true

	end

	if doTick then self:_setProperty(property('DoTick'), true) end
end

function PlayerInputComponent:receive(sender, msg, ...)
	if msg == message('TIME_PRETICK') and sender == self._mediator then
		self:_setProperty(property('DoTick'), false)
	else
		InputComponent.receive(self, sender, msg, ...)
	end
end


-- the class
return PlayerInputComponent
