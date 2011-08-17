local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- EntityDeathEvent
--
local EntityDeathEvent = Class{name='EntityDeathEvent',
	inherits=Event,
	function(self, entity, reason)
		verifyClass('pud.entity.Entity', entity)
		verify('string', reason)

		Event.construct(self, 'Entity Death Event')

		self._entity = entity
		self._reason = reason
	end
}

-- destructor
function EntityDeathEvent:destroy()
	self._entity = nil
	self._reason = nil
	Event.destroy(self)
end

function EntityDeathEvent:getEntity() return self._entity end
function EntityDeathEvent:getReason() return self._reason end

-- the class
return EntityDeathEvent
