local Class = require 'lib.hump.class'
local Deque = getClass 'pud.kit.Deque'
local TimeComponent = getClass 'pud.component.TimeComponent'
local CommandEvent = getClass 'pud.event.CommandEvent'
local TimeSystemCycleEvent = getClass 'pud.event.TimeSystemCycleEvent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

local CommandEvents = CommandEvents
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
	self._firstTraveler = nil
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

	-- check for exhausted or destroyed components and remove them
	while comp and (not comp._properties or comp:isExhausted()) do
		self._timeTravelers:pop_front()
		self._actionPoints[comp] = nil
		if comp == self._firstTraveler then self._firstTraveler = nil end
		comp = self._timeTravelers:front()
	end

	self._firstTraveler = self._firstTraveler or comp
	if comp == self._firstTraveler then
		GameEvents:notify(TimeSystemCycleEvent())
	end

	if self._timeTravelers:size() > 0 and comp:shouldTick() then
		-- rotate the deque
		self._timeTravelers:rotate_forward()

		-- increase action points by the componet's speed
		local ap = self._actionPoints
		local speed = comp:getTotalSpeed()

		ap[comp] = ap[comp] + speed
		comp:onPreTick(ap[comp])

		-- spend all action points
		if self._commandQueues[comp] then
			repeat
				local nextCommand = self._commandQueues[comp]:front()
				if nextCommand and nextCommand:cost() <= ap[comp] then
					self._commandQueues[comp]:pop_front()
					comp:onPreExecute(ap[comp])
					ap[comp] = ap[comp] - nextCommand:execute(ap[comp])
					comp:onPostExecute(ap[comp])
				else
					nextCommand = nil
				end
			until nil == nextCommand or ap[comp] < 0
		end

		comp:onPostTick(ap[comp])
	end
end


-- the class
return TimeSystem
