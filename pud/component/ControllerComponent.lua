local Class = require 'lib.hump.class'
local Component = getClass 'pud.component.Component'
local CommandEvent = getClass 'pud.event.CommandEvent'
local ConsoleEvent = getClass 'pud.event.ConsoleEvent'
local DisplayPopupMessageEvent = getClass 'pud.event.DisplayPopupMessageEvent'
local WaitCommand = getClass 'pud.command.WaitCommand'
local MoveCommand = getClass 'pud.command.MoveCommand'
local AttackCommand = getClass 'pud.command.AttackCommand'
local OpenDoorCommand = getClass 'pud.command.OpenDoorCommand'
local PickupCommand = getClass 'pud.command.PickupCommand'
local DropCommand = getClass 'pud.command.DropCommand'
local AttachCommand = getClass 'pud.command.AttachCommand'
local DetachCommand = getClass 'pud.command.DetachCommand'
local DoorMapType = getClass 'pud.map.DoorMapType'
local message = require 'pud.component.message'
local property = require 'pud.component.property'

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
	if nil == data then data = property.default(prop) end

	if prop == property('CanOpenDoors') then
		verify('boolean', data)
	end

	Component._setProperty(self, prop, data)
end

-- check for collisions at the given coordinates
function ControllerComponent:_attemptMove(x, y)
	local pos = self._mediator:query(property('Position'))
	local newX, newY = pos[1] + x, pos[2] + y
	CollisionSystem:check(self._mediator, newX, newY)
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

function ControllerComponent:_tryToPickup()
	local items = EntityRegistry:getIDsByType('item')
	local count = 0
	local pIsContained = property('IsContained')
	local pPosition = property('Position')

	if items then
		local num = #items
		for i=1,num do
			local id = items[i]
			local item = EntityRegistry:get(id)
			if not item:query(pIsContained) then
				local ipos = item:query(pPosition)
				local mpos = self._mediator:query(pPosition)
				if vec2_equal(ipos[1], ipos[2], mpos[1], mpos[2]) then
					self:_sendCommand(PickupCommand(self._mediator, id))
					count = count + 1
				end
			end
		end
	end

	if count == 0 then
		GameEvents:push(DisplayPopupMessageEvent('Nothing to pick up!'))
	end
end

function ControllerComponent:_tryToDrop(id)
	local contained = self._mediator:query(property('ContainedEntities'))
	if contained then
		local found = false
		local num = #contained

		for i=1,num do
			if contained[i] == id then
				found = true
				break
			end
		end

		if found then
			local item = EntityRegistry:get(id)
			self:_sendCommand(DropCommand(self._mediator, id))
		else
			GameEvents:push(DisplayPopupMessageEvent('You can\'t drop that!'))
		end
	else
		GameEvents:push(DisplayPopupMessageEvent('Nothing to drop!'))
	end
end

function ControllerComponent:_tryToAttach(id)
	local contained = self._mediator:query(property('ContainedEntities'))
	local attached = false

	if contained then
		local num = #contained
		local found = false

		for i=1,num do
			if contained[i] == id then
				found = true
				break
			end
		end

		if found then
			local item = EntityRegistry:get(id)
			if not item:query(property('IsAttached')) then
				self:_sendCommand(AttachCommand(self._mediator, id))
				attached = true
			end
		else
			GameEvents:push(DisplayPopupMessageEvent('You can\'t equip that!'))
		end
	end

	if not attached then
		print('not attached')
		GameEvents:push(DisplayPopupMessageEvent('Nothing to equip!'))
	end
end

function ControllerComponent:_tryToDetach(id)
	local attached = self._mediator:query(property('AttachedEntities'))
	if attached then
		local found = false
		local num = #attached

		for i=1,num do
			if attached[i] == id then
				found = true
				break
			end
		end

		if found then
			local item = EntityRegistry:get(id)
			self:_sendCommand(DetachCommand(self._mediator, id))
		else
			GameEvents:push(
				DisplayPopupMessageEvent('You don\'t have that equipped!'))
		end
	else
		GameEvents:push(DisplayPopupMessageEvent('Nothing to unequip!'))
	end
end

function ControllerComponent:_sendCommand(command)
	CommandEvents:notify(CommandEvent(command))
end

function ControllerComponent:receive(msg, ...)
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
				local elevel = item:getELevel()
				GameEvents:push(ConsoleEvent('Item found: %s (%d)', name, elevel))
			end
		end
	else
		Component.receive(self, msg, ...)
	end
end


-- the class
return ControllerComponent
