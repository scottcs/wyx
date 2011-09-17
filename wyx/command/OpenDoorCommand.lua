local Class = require 'lib.hump.class'
local Command = getClass 'wyx.command.Command'
local DoorMapType = getClass 'wyx.map.DoorMapType'

local GameEvents = GameEvents

-- Open Door - fires when a door is opened
local OpenDoorCommand = Class{name='OpenDoorCommand',
	inherits=Command,
	function(self, target, node)
		Command.construct(self, target)

		verifyClass('wyx.map.MapNode', node)

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

	local MapNodeUpdateEvent = getClass 'wyx.event.MapNodeUpdateEvent'
	GameEvents:notify(MapNodeUpdateEvent(self._node))

	return Command.execute(self)
end

function OpenDoorCommand:__tostring()
	return self:_msg('{%08s}, %s',
		self:_getTargetString(), tostring(self._node))
end


-- the class
return OpenDoorCommand
