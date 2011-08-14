local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local MapNode = getClass 'pud.map.MapNode'
local DoorMapType = getClass 'pud.map.DoorMapType'

-- Open Door - fires when a door is opened
local OpenDoorCommand = Class{name='OpenDoorCommand',
	inherits=Command,
	function(self, target, pos, map)
		Command.construct(self, target)

		verify('vector', pos)
		verifyClass('pud.map.Map', map)

		self._pos = pos
		self._map = map
	end
}

-- destructor
function OpenDoorCommand:destroy()
	self._pos = nil
	self._map = nil
	Command.destroy(self)
end

function OpenDoorCommand:execute()
	local node = self._map:getLocation(self._pos.x, self._pos.y)
	local style = node:getMapType():getStyle()
	node:setMapType(DoorMapType('open', style))

	self._cost = self._target:query(property('MoveCost'))
	self._cost = self._cost or self._target:query(property('DefaultCost'))
	Command.execute(self)
end

function OpenDoorCommand:getMapPosition() return self._pos end

-- the class
return OpenDoorCommand
