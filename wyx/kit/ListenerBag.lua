local Class = require 'lib.hump.class'

local pairs = pairs

-- ListenerBag
--
local ListenerBag = Class{name='ListenerBag',
	function(self)
		self._queue = setmetatable({}, {__mode = 'k'})
	end
}

-- destructor
function ListenerBag:destroy()
	self:clear()
	self._queue = nil
end

function ListenerBag:clear()
	for obj in pairs(self._queue) do self:pop(obj) end
end

function ListenerBag:size()
	local size = 0
	for obj in pairs(self._queue) do size = size + 1 end
	return size
end

function ListenerBag:push(obj) self._queue[obj] = true end
function ListenerBag:pop(obj) self._queue[obj] = nil end
function ListenerBag:exists(obj) return self._queue[obj] ~= nil end

-- 'for' iterator (unordered)
-- example: for obj in queue:listeners() do obj:something() end
function ListenerBag:listeners()
	local l = {}
	local n = 1
	for obj in pairs(self._queue) do
		l[n] = obj
		n = n + 1
	end

	local i = 0
	return function() i = i + 1; return l[i] end
end


-- the class
return ListenerBag
