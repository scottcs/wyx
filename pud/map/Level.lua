local Class = require 'lib.hump.class'

local Map = require 'pud.map.Map'
local MapDirector = require 'pud.map.MapDirector'
local FileMapBuilder = require 'pud.map.FileMapBuilder'
local SimpleGridMapBuilder = require 'pud.map.SimpleGridMapBuilder'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'

local _testFiles = {
	'test',
}

-- Level
--
local Level = Class{name='Level',
	function(self)
	end
}

-- destructor
function Level:destroy()
	self._map:destroy()
	self._map = nil
end

function Level:update(dt)
end

function Level:generateFileMap(file)
	file = file or _testFiles[Random(#_testFiles)]
	local builder = FileMapBuilder(file)
	self:_generateMap(builder)
end

function Level:generateSimpleGridMap()
	local builder = SimpleGridMapBuilder(80,80, 10,10, 8,16)
	self:_generateMap(builder)
end

function Level:_generateMap(builder)
	if self._map then self._map:destroy() end
	self._map = MapDirector:generateStandard(builder)
	builder:destroy()
	GameEvents:push(MapUpdateFinishedEvent(self._map))
end

function Level:getStartVector() return self._map:getStartVector() end

-- the class
return Level
