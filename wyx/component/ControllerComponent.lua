local Class = require 'lib.hump.class'
local Component = getClass 'wyx.component.Component'
local DoorMapType = getClass 'wyx.map.DoorMapType'
local message = require 'wyx.component.message'
local property = require 'wyx.component.property'

-- events
local CommandEvent = getClass 'wyx.event.CommandEvent'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local DisplayPopupMessageEvent = getClass 'wyx.event.DisplayPopupMessageEvent'

-- commands
local WaitCommand = getClass 'wyx.command.WaitCommand'
local MoveCommand = getClass 'wyx.command.MoveCommand'
local AttackCommand = getClass 'wyx.command.AttackCommand'
local OpenDoorCommand = getClass 'wyx.command.OpenDoorCommand'
local PickupCommand = getClass 'wyx.command.PickupCommand'
local DropCommand = getClass 'wyx.command.DropCommand'
local AttachCommand = getClass 'wyx.command.AttachCommand'
local DetachCommand = getClass 'wyx.command.DetachCommand'

local CommandEvents = CommandEvents
local vec2_equal = vec2.equal

-- ControllerComponent
--
local ControllerComponent = Class{name='ControllerComponent',
	inherits=Component,
	function(self, newProperties)
		Component._addRequiredProperties(self, {'CanOpenDoors'})
		Component.construct(self, newProperties)
		self:_addMessages(
			'TIME_PRETICK',
			'COLLIDE_NONE',
			'COLLIDE_BLOCKED',
			'COLLIDE_ITEM',
			'COLLIDE_ENEMY',
			'COLLIDE_HERO')
	end
}

-- destructor
function ControllerComponent:destroy()
	Component.destroy(self)
end

function ControllerComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if prop == property('CanOpenDoors') then
		verifyAny(data, 'boolean', 'expression')
	end

	Component._setProperty(self, prop, data)
end

-- check for collisions at the given coordinates
function ControllerComponent:_attemptMove(x, y)
	local pos = self._mediator:query(property('Position'))
	local newX, newY = pos[1] + x, pos[2] + y
	CollisionSystem:check(self._mediator, newX, newY)
end

function ControllerComponent:_attemptPortalIn()
	local pos = self._mediator:query(property('Position'))
	CollisionSystem:checkPortal(self._mediator, pos[1], pos[2])
end

function ControllerComponent:_wait()
	self:_sendCommand(WaitCommand(self._mediator))
end

function ControllerComponent:_move(x, y)
	local canMove = self._mediator:query(property('CanMove'))
	
	if canMove then
		self:_sendCommand(MoveCommand(self._mediator, x, y))
	else
		self:_wait()
	end
end

function ControllerComponent:_tryToManipulateMap(node)
	local wait = true

	if node then
		local mapType = node:getMapType()

		if mapType:isType(DoorMapType('shut')) then
			if self._mediator:query(property('CanOpenDoors')) then
				self:_sendCommand(OpenDoorCommand(self._mediator, node))
				wait = false
			end
		end
	end

	if wait then self:_wait() end
end

function ControllerComponent:_attack(isHero, target)
	local etype = self._mediator:getEntityType()
	if isHero or 'hero' == etype then
		self:_sendCommand(
			AttackCommand(self._mediator, EntityRegistry:get(target)))
	else
		self:_wait()
	end
end

function ControllerComponent:_doPickup(id, slot)
	local pIsContained = property('IsContained')
	local pIsAttached = property('IsAttached')
	local pPosition = property('Position')
	local item = EntityRegistry:get(id)

	if not (item:query(pIsContained) or item:query(pIsAttached)) then
		local ipos = item:query(pPosition)
		local mpos = self._mediator:query(pPosition)
		if vec2_equal(ipos[1], ipos[2], mpos[1], mpos[2]) then
			self:_sendCommand(PickupCommand(self._mediator, id, slot))
			return 1
		end
	end

	return 0
end

function ControllerComponent:_doDrop(id)
	self:_sendCommand(DropCommand(self._mediator, id))
end

function ControllerComponent:_doAttach(id)
	local item = EntityRegistry:get(id)
	if not item:query(property('IsAttached')) then
		self:_sendCommand(AttachCommand(self._mediator, id))
	end
end

function ControllerComponent:_doDetach(id)
	self:_sendCommand(DetachCommand(self._mediator, id))
end

function ControllerComponent:_sendCommand(command)
	CommandEvents:notify(CommandEvent(command))
end

function ControllerComponent:getProperty(p, intermediate, ...)
	if p == property('CanOpenDoors') then
		local prop = self:_evaluate(p)
		if nil == intermediate then return prop end
		return (prop or intermediate)
	else
		return Component.getProperty(self, p, intermediate, ...)
	end
end

function ControllerComponent:receive(sender, msg, ...)
	if     msg == message('COLLIDE_NONE') then
		self:_move(...)

	elseif msg == message('COLLIDE_BLOCKED') then
		self:_tryToManipulateMap(...)

	elseif msg == message('COLLIDE_ENEMY') then
		self:_attack(false, ...)

	elseif msg == message('COLLIDE_HERO') then
		self:_attack(true, ...)

	elseif msg == message('COLLIDE_ITEM') then
		if self._mediator:getEntityType() == 'hero' then
			local id = select(1, ...)
			if id then
				local item = EntityRegistry:get(id)
				local name = item:getName()
				GameEvents:push(ConsoleEvent('Item found: %s {%08s}', name, id))
			end
		end

	elseif msg == message('TIME_PRETICK') then
		if sender == self._mediator then self:_wait() end

	else
		Component.receive(self, sender, msg, ...)
	end
end

function ControllerComponent:_printStats()
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

	GameEvents:push(ConsoleEvent('Stats (%s):', self._mediator:getName()))
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

function ControllerComponent:_printInventory()
	local found = false

	local name = self._mediator:getName()
	local contained = self._mediator:query(property('ContainedEntities'))
	local attached = self._mediator:query(property('AttachedEntities'))

	if attached then
		GameEvents:push(ConsoleEvent('Equipment (%s):', name))
		found = true
		for i,e in pairs(attached) do
			local entity = EntityRegistry:get(e)
			GameEvents:push(ConsoleEvent('   {%08s} %s',
				e, entity:getName()))
		end
	end

	if contained then
		GameEvents:push(ConsoleEvent('Inventory (%s):', name))
		found = true
		for i,e in pairs(contained) do
			local entity = EntityRegistry:get(e)
			GameEvents:push(ConsoleEvent('   %d - {%08s} %s',
				i, e, entity:getName()))
		end
	end

	if not found then
		GameEvents:push(ConsoleEvent('%s has empty bags.', name))
	end
end


-- the class
return ControllerComponent
