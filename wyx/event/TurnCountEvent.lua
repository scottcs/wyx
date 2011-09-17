local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- TurnCountEvent
--
local TurnCountEvent = Class{name='TurnCountEvent',
	inherits=Event,
	function(self, turnCount)
		verify('number', turnCount)
		Event.construct(self, 'Turn Count Event')
		self._turnCount = turnCount
	end
}

-- destructor
function TurnCountEvent:destroy()
	self._turnCount = nil
	Event.destroy(self)
end

function TurnCountEvent:getTurnCount() return self._turnCount end

function TurnCountEvent:__tostring()
	return self:_msg('%d', self._turnCount)
end


-- the class
return TurnCountEvent
