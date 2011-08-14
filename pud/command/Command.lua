local Class = require 'lib.hump.class'

-- default action point cost for executing a command
-- (used by the TimeSystem for entity commands)
DEFAULT_COST = 1

-- Command class
local Command = Class{name='Command',
	function(self, target)
		self._target = target
	end
}

-- destructor
function Command:destroy()
	self._target = nil
	self._cost = nil
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
	return self._cost or DEFAULT_COST
end


-- the class
return Command
