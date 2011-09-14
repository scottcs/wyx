local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

local select, assert, unpack = select, assert, unpack

-- MouseIntersectResponse
--
local MouseIntersectResponse = Class{name='MouseIntersectResponse',
	inherits=Event,
	function(self, ids, ...)
		if nil ~= ids then verify('table', ids) end
		Event.construct(self, 'Mouse Intersect Event')

		self._ids = ids
		self._args = (select('#', ...) > 0) and {...} or nil
	end
}

-- destructor
function MouseIntersectResponse:destroy()
	self._args = nil
	Event.destroy(self)
end

function MouseIntersectResponse:getIDs() return self._ids end
function MouseIntersectResponse:getArgsTable() return self._args end
function MouseIntersectResponse:getArgs()
	return self._args and unpack(self._args) or nil
end

local concat = table.concat
function MouseIntersectResponse:__tostring()
	local idstr, argstr = '', ''
	if self._ids then idstr = concat(self._ids, ', ') end
	if self._args then argstr = concat(self._args, ', ') end
	return self:_msg('%s | %s', idstr, argstr)
end

-- the class
return MouseIntersectResponse
