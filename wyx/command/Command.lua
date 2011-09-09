local Class = require 'lib.hump.class'
local property = require 'wyx.component.property'

-- default action point cost for executing a command
-- (used by the TimeSystem for entity commands)
DEFAULT_COST = 0

-- Command class
local Command = Class{name='Command',
	function(self, target)
		self._target = target
	end
}

-- destructor
function Command:destroy()
	self._target = nil
	self._costProp = nil
	self._onComplete = nil
	self._onCompleteArgs = nil
end

-- get the target object of this command
function Command:getTarget() return self._target end

-- set the callback to call when the command is completed
function Command:setOnComplete(func, ...)
	assert(func and type(func) == 'function',
		'onComplete must be a function (was %s)', type(func))
	self._onComplete = func
	self._onCompleteArgs = {...}
end

-- call the stored callback when the command is completed
function Command:_doOnComplete()
	if self._onComplete then
		self._onComplete(unpack(self._onCompleteArgs))
	end
end

-- execute the command
function Command:execute(currAP)
	self:_doOnComplete()
	return self:cost()
end

-- return the cost of executing this command
function Command:cost()
	local cost = DEFAULT_COST
	if self._target and self._target.query then
		local prop = self._costProp or property('DefaultCost')
		cost = self._target:query(prop)

		local propBonus = prop .. 'Bonus'
		if property.isproperty(propBonus) then
			cost = cost + self._target:query(propBonus)
		end
	end
	return cost
end


-- the class
return Command
