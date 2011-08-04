local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local Event = require 'pud.event.Event'
local Entity = require 'pud.entity.Entity'

-- EntityPositionEvent
--
local EntityPositionEvent = Class{name='EntityPositionEvent',
	inherits=Event,
	function(self, entity, from, to)
		assert(entity and type(entity) == 'table'
			and entity.is_a and entity:is_a(Entity),
			'entity expected (was %s)', type(entity))
		assert(vector.isvector(from) and vector.isvector(to),
			'vectors expected for "from" and "to" (were %s and %s)',
			type(from), type(to))

		Event.construct(self, 'Entity Position Event')

		self._entity = entity
		self._from = from
		self._to = to
	end
}

-- destructor
function EntityPositionEvent:destroy()
	self._entity = nil
	self._from = nil
	self._to = nil
	Event.destroy(self)
end

function EntityPositionEvent:getEntity() return self._entity end
function EntityPositionEvent:getOrigin() return self._from:clone() end
function EntityPositionEvent:getDestination() return self._to:clone() end

-- the class
return EntityPositionEvent
