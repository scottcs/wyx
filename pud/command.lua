-- Command class
local Command = Class{name='Command',
	function(self)
	end
}

-- set the callback to call when the command is completed
function Command:setOnComplete(func)
	assert(func and type(func) == 'function',
		'onComplete must be a function (was %s)', type(func))
	self._onComplete = func
end

-- call the stored callback when the command is completed
function Command:onComplete()
	if self._onComplete then self._onComplete() end
end

-- execute the command
function Command:execute()
end

-- destructor
function Command:destroy()
	self._onComplete = nil
end

-- the class
return Command
