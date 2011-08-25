local Class = require 'lib.hump.class'
local ConsoleEvent = getClass 'pud.event.ConsoleEvent'
local Command = getClass 'pud.command.Command'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- AttackCommand
--
local AttackCommand = Class{name='AttackCommand',
	inherits=Command,
	function(self, target, targetOpponent)
		verifyClass('pud.component.ComponentMediator', target, targetOpponent)

		Command.construct(self, target)
		self._costProp = property('AttackCost')
		self._opponent = targetOpponent
	end
}

-- destructor
function AttackCommand:destroy()
	self._x = nil
	self._y = nil
	Command.destroy(self)
end

function AttackCommand:execute(currAP)
	local oDefense = self._opponent:query(property('Defense'))
	oDefense = oDefense + self._opponent:query(property('DefenseBonus'))
	local attack = self._target:query(property('Attack'))
	attack = attack + self._target:query(property('AttackBonus'))
	local damage = self._target:query(property('Damage'))
	damage = damage + self._target:query(property('DamageBonus'))
	damage = -damage
	
	if attack < oDefense then
		damage = damage + oDefense
	end

	local name = self._target:getName() or tostring(self._target)
	self._opponent:send(message('COMBAT_DAMAGE'), damage, name)
	GameEvents:push(ConsoleEvent('Combat: %s -> %s (%.1f)',
		name, self._opponent:getName(), damage))

	return Command.execute(self)
end

function AttackCommand:getOpponent() return self._opponent end

-- the class
return AttackCommand
