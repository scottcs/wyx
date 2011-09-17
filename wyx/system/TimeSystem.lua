local Class = require 'lib.hump.class'
local Deque = getClass 'wyx.kit.Deque'
local TimeComponent = getClass 'wyx.component.TimeComponent'
local CommandEvent = getClass 'wyx.event.CommandEvent'
local Command = getClass 'wyx.command.Command'
local TimeSystemCycleEvent = getClass 'wyx.event.TimeSystemCycleEvent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

local CommandEvents = CommandEvents
local table_sort = table.sort

-- TimeSystem
--
local TimeSystem = Class{name='TimeSystem',
	function(self)
		self._timeTravelers = Deque()
		self._cycle = false
		self._rotate = true
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
	self._cycle = nil
	self._rotate = nil
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

-- set the first traveler (for determining when a cycle ends)
function TimeSystem:setFirst(component)
	self._firstTraveler = component
	local comp = self._timeTravelers:front()
	while comp and comp ~= self._firstTraveler do
		self._timeTravelers:rotate_forward()
		comp = self._timeTravelers:front()
	end
end

-- execute a single command
function TimeSystem:_executeCommand(command, comp)
	local ap = self._actionPoints
	comp:onPreExecute(ap[comp])
	ap[comp] = ap[comp] - command:execute(ap[comp])
	comp:onPostExecute(ap[comp])
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

	if self._firstTraveler
		and self._timeTravelers:size() > 0
		and comp:shouldTick()
	then
		-- increase action points by the componet's speed
		local ap = self._actionPoints
		local speed = comp:getTotalSpeed()

		if self._rotate then
			ap[comp] = ap[comp] + speed
			self._rotate = false
		end

		comp:onPreTick(ap[comp])

		-- spend all action points
		if self._commandQueues[comp] then
			local queue = self._commandQueues[comp]
			local sentinel = Command()
			queue:push_back(sentinel)

			-- first execute all commands with 0 cost
			repeat
				local command = queue:front()
				if command and command:cost() == 0 then
					queue:pop_front()
					self:_executeCommand(command, comp)
				else
					queue:rotate_forward()
				end
			until nil == command or command == sentinel

			-- now execute remaining commands as long as there are available AP
			repeat
				local nextCommand = queue:front()
				if nextCommand then
					queue:pop_front()
					self:_executeCommand(nextCommand, comp)
				end
			until nil == nextCommand or ap[comp] <= 0
		end

		if ap[comp] <= 0 then
			self._commandQueues[comp]:clear()

			-- rotate the deque so the next traveler gets a turn
			self._timeTravelers:rotate_forward()

			self._rotate = true
			self._cycle = true
		end

		comp:onPostTick(ap[comp])

		if self._cycle and self._timeTravelers:front() == self._firstTraveler then
			GameEvents:notify(TimeSystemCycleEvent())
			self._cycle = false
		end
	end
end


-- the class
return TimeSystem
