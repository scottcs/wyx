local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local DoorMapType = getClass 'pud.map.DoorMapType'
local property = require 'pud.component.property'

local GameEvents = GameEvents

-- Open Door - fires when a door is opened
local OpenDoorCommand = Class{name='OpenDoorCommand',
	inherits=Command,
	function(self, target, node)
		Command.construct(self, target)

		verifyClass('pud.map.MapNode', node)

		self._node = node
	end
}

-- destructor
function OpenDoorCommand:destroy()
	self._node = nil
	Command.destroy(self)
end

function OpenDoorCommand:execute()
	local style = self._node:getMapType():getStyle()
	self._node:setMapType(DoorMapType('open', style))

	local MapNodeUpdateEvent = getClass 'pud.event.MapNodeUpdateEvent'
	GameEvents:notify(MapNodeUpdateEvent(self._node))

	self._cost = 0
	return Command.execute(self)
end

-- the class
return OpenDoorCommand
