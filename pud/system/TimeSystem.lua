local Class = require 'lib.hump.class'
local Deque = getClass 'pud.kit.Deque'
local TimeComponent = getClass 'pud.component.TimeComponent'
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

-- register a component
function TimeSystem:register(comp, debt)
	assert(comp, 'Could not register component: %s', tostring(comp))

	debt = debt or 0
	if debt < 0 then debt = -debt end

	self._timeTravelers:push_back(comp)
	self._actionPoints[comp] = -debt
	if self._commandQueues[comp] then self._commandQueues[comp]:destroy() end
	self._commandQueues[comp] = Deque()
end

-- keep track of commands per object
function TimeSystem:CommandEvent(e)
	local command = e:getCommand()
	local obj = command:getTarget()

	if obj.getComponentsByClass then
		local components = obj:getComponentsByClass(TimeComponent)

		if components then
			-- only register command with one of the time components for this
			-- object, otherwise commands will be duplicated. Besides, there should
			-- only be one TimeComponent per object.
			local comp = components[1]

			if comp and self._commandQueues[comp] then
				self._commandQueues[comp]:push_back(command)
			end
		end
	end
end

-- progresses through deque and update time entity
function TimeSystem:tick()
	local comp = self._timeTravelers:front()

	-- check for exhausted components and remove them
	while comp and comp:isExhausted() do
		self._timeTravelers:pop_front()
		self._actionPoints[comp] = nil
		comp = self._timeTravelers:front()
	end

	if self._timeTravelers:size() > 0 and comp:shouldTick() then
		-- rotate so that the front is now the back and front.right is front
		self._timeTravelers:rotate_forward()

		-- increase action points by the componet's speed
		local ap = self._actionPoints
		local speed = comp:getTotalSpeed()

		ap[comp] = ap[comp] + speed

		-- spend all action points
		if self._commandQueues[comp] then
			repeat
				local nextCommand = self._commandQueues[comp]:pop_front()
				if nextCommand then
					ap[comp] = ap[comp] - nextCommand:execute(ap[comp])
				end
			until nil == nextCommand or self._actionPoints[comp] <= 0
		end

		comp:onTick()
	end
end


-- the class
return TimeSystem
