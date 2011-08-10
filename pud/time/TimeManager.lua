local Class = require 'lib.hump.class'

-- TimeManager

local Deque = getClass('pud.kit.Deque')

-- TimeManager class controls time
local TimeManager = Class{name = 'TimeManager',
	function(self)
		self._timeTravelers = Deque()
		self._actionPoints = {}
	end
}

-- inserts a TimedObject into the deque
-- debt is the amount of action points that the obj needs to "burn off" before
-- accumulating more action points at the object's speed.
function TimeManager:register(obj, debt)
	verifyClass('pud.time.TimedObject', obj)

	debt = debt or 0
	if debt < 0 then debt = -debt end

	self._timeTravelers:push_back(obj)
	self._actionPoints[obj] = -debt
end

-- progresses through deque and update time entity
function TimeManager:tick()
	local obj = self._timeTravelers:front()

	-- check for exhausted objects and remove them
	while obj and obj:isExhausted() do
		self._timeTravelers:pop_front()
		self._actionPoints[obj] = nil
		obj = self._timeTravelers:front()
	end

	if self._timeTravelers:size() > 0 then
		-- rotate so that the front is now the back and front.right is front
		self._timeTravelers:rotate_forward()

		-- increase action points by the object's speed
		local ap = self._actionPoints
		ap[obj] = ap[obj] + obj:getSpeed(ap[obj])

		-- spend all action points
		while self._actionPoints[obj] > 0 do
			ap[obj] = ap[obj] - obj:doAction(ap[obj])
		end
	end

	-- return the object whose turn is next
	return self._timeTravelers:front()
end

-- deconstructor
function TimeManager:destroy()
	self._timeTravelers:destroy()
	for k,v in self._actionPoints do self._actionPoints[k] = nil end
	self._timeTravelers = nil
	self._actionPoints = nil
end

return TimeManager
