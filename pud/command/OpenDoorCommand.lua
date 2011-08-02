local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local Command = require 'pud.command.Command'
local Map = require 'pud.map.Map'
local MapNode = require 'pud.map.MapNode'

-- Open Door - fires when a door is opened
local OpenDoorCommand = Class{name='OpenDoorCommand',
	inherits=Command,
	function(self, target, pos, map)
		Command.construct(self, target)

		assert(vector.isvector(pos),
			'OpenDoorCommand expects a vector (was %s)', type(pos))
		assert(map and type(map) == 'table' and map.is_a and map:is_a(Map),
			'OpenDoorCommand expects a Map (was %s)', type(map))

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
	local node = self._map:setNodeMapType(MapNode(), 'doorOpen')
	self._map:setLocation(self._pos.x, self._pos.y, node)
end

function OpenDoorCommand:getMapPosition() return self._pos end

-- the class
return OpenDoorCommand
