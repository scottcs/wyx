-- TimeManager

-- TimedEntity class represents a single entity within the Time Manager
local TimedEntity = Class{name = 'Time',
	function(self, initial, target, rateFunc, costFunc)
		self.cur = initial or 0
		self.target = target or 0
		self.rateFunc = rateFunc or NOFUNC
		self.costFunc = costFunc or NOFUNC
		self.next = self
		self.prev = self
	end
}

-- destructor
function TimedEntity:destroy()
	self.cur = nil
	self.target = nil
	self.rateFunc = nil
	self.costFunc = nil
	self.next = nil
	self.prev = nil
end

-- TimeManager class controls time
local TimeManager = Class{name = 'TimeManager',
	function(self)
		self._sentinel = TimedEntity()
	end
}

-- allocates and initializes a timed entity
-- and inserts it into the circular list
function TimeManager:registerTimedEntity(initial, target, rateFunc, costFunc)
	local te = TimedEntity(-initial, target, rateFunc, costFunc)

	te.prev, te.next = self._sentinel, self._sentinel.next
	te.next.prev, self._sentinel.next = te, te
end

-- remove _sentinel:next() from circular list and store for later deallocation
function TimeManager:releaseTimedEntity()
	self._releaseTE = self._sentinel.next
	self._sentinel.next = self._releaseTE.next
	self._sentinel.next.prev = self._sentinel
end

-- travels the sentinel through the circular list
-- deallocates a released time entity if necessary
function TimeManager:progressTimeSentinel()
	if self._releaseTE then
		self._releaseTE:destroy()
		self._releaseTE = nil
	elseif self._sentinel.next.next ~= self._sentinel then
		-- travel _sentinel one step forward
		local s = self._sentinel
		s.next, s.prev, s.next.next, s.next.prev, s.prev.next, s.next.next.prev =
			s.next.next, s.next, s, s.prev, s.next, s
	end
end

-- progresses through circular list and update time entity
function TimeManager:progressTime(dt)
	if self._sentinel.next ~= self._sentinel then
		local te = self._sentinel.next

		-- update the current time value based on entity speed/rate
		te.cur = te.cur + (te.rateFunc(te.target)*(dt*100))

		-- while sufficient energy is present, perform actions
		while te.cur >= 0 do
			te.cur = te.cur - (te.costFunc(te.target)*(dt*100))
		end

		self:progressTimeSentinel()
	end
end

-- deconstructor
function TimeManager:destroy()
	while self._sentinel.next ~= self._sentinel do
		local s = self._sentinel
		local te = s.next
		s.next, s.next.next.prev = s.next.next, s
		te:destroy()
	end
	self._sentinel:destroy()
	self._sentinel = nil
end

return TimeManager
