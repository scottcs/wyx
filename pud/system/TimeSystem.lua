local Class = require 'lib.hump.class'
local ListenerBag = getClass 'pud.kit.ListenerBag'
local CommandEvent = getClass 'pud.event.CommandEvent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

local table_sort = table.sort

-- TimeSystem
--
local TimeSystem = Class{name='TimeSystem',
	function(self)
		self._timeTravelers = Deque()
		self._actionPoints = {}
		self._commandQueues = {}
		CommandEvents:register(self, CommandEvent)
	end
}

-- destructor
function TimeSystem:destroy()
	CommandEvents:unregisterAll(self)
	self._timeTravelers:destroy()
	for k,v in pairs(self._actionPoints) do self._actionPoints[k] = nil end
	for k,v in pairs(self._commandQueues) do
		self._commandQueues[k]:destroy()
		self._commandQueues[k] = nil
	end
	self._timeTravelers = nil
	self._actionPoints = nil
end

-- register an object
function TimeSystem:register(obj, debt)
	debt = debt or 0
	if debt < 0 then debt = -debt end

	self._timeTravelers:push_back(obj)
	self._actionPoints[obj] = -debt
	if self._commandQueues[obj] then self._commandQueues[obj]:destroy() end
	self._commandQueues[obj] = Deque()
end

-- keep track of commands per object
function TimeSystem:CommandEvent(e)
	local command = e:getCommand()
	local obj = command:getTarget()

	if obj and self._commandQueues[obj] then
		self._commandQueues[obj]:push_back(command)
	end
end

-- progresses through deque and update time entity
function TimeSystem:tick()
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
		local speed = obj:query(property('Speed'))
		speed = speed + obj:query(property('SpeedBonus'))
			
		ap[obj] = ap[obj] + speed

		-- spend all action points
		if self._commandQueues[obj] then
			repeat
				local nextCommand = self._commandQueues[obj]:pop_front()
				if nextCommand then
					ap[obj] = ap[obj] - nextCommand:execute(ap[obj])
				end
			until self._actionPoints[obj] <= 0
	end

	-- return the object whose turn is next
	return self._timeTravelers:front()
end


-- the class
return TimeSystem
