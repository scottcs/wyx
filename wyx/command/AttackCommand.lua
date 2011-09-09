local Class = require 'lib.hump.class'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local Command = getClass 'wyx.command.Command'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

-- AttackCommand
--
local AttackCommand = Class{name='AttackCommand',
	inherits=Command,
	function(self, target, targetOpponent)
		verifyClass('wyx.component.ComponentMediator', target, targetOpponent)

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
		damage = damage + (oDefense - attack)
	end

	damage = damage > -1 and -1 or damage

	local name = self._target:getName() or tostring(self._target)
	self._opponent:send(message('COMBAT_DAMAGE'), damage, name)
	GameEvents:push(ConsoleEvent('Combat: %s -> %s (%.1f)',
		name, self._opponent:getName(), damage))

	return Command.execute(self)
end

function AttackCommand:getOpponent() return self._opponent end

-- the class
return AttackCommand
