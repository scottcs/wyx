local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- Game Over - fires when the game is over
-- params:
--   reason - can be 'death', 'quit', 'win'
local GameOverEvent = Class{name='GameOverEvent',
	inherits=Event,
	function(self, reason)
		Event.construct(self, 'Game Over Event')

		verify('string', reason)
		assert(reason == 'death'
			or reason == 'quit'
			or reason == 'win',
			self:_msg('invalid reason "%s"', reason))

		self._reason = reason
	end
}

-- destructor
function GameOverEvent:destroy()
	self._reason = nil
	Event.destroy(self)
end

function GameOverEvent:getReason() return self._reason end

-- the class
return GameOverEvent
