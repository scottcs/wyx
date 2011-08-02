local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'	

-- Traveler
-- assumes the child inheriting this class also inherits Rect
local Traveler = Class{name='Traveler',
	function(self)
	end
}

-- destructor
function Traveler:destroy()
	self._movePosition = nil
end

function Traveler:canMove(node) return node:isAccessible() end

function Traveler:getMovePosition() return self._movePosition end

function Traveler:setMovePosition(v)
	assert(vector.isvector(v),
		'setMovePosition expects a vector (was %s)', type(v))
	self._movePosition = v
end

function Traveler:wantsToMove() return self._movePosition ~= nil end

function Traveler:move()
	self:setPosition(self._movePosition)
	self._movePosition = nil
end

-- the class
return Traveler
