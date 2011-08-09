local Class = require 'lib.hump.class'
local match = string.match

-- Traveler
-- assumes the child inheriting this class also inherits Rect
local Traveler = Class{name='Traveler',
	function(self)
	end
}

-- destructor
function Traveler:destroy()
	self._movePosition = nil
	self._zone = nil
end

function Traveler:isBlocked(node)
	local blocked = false
	local mapType = node:getMapType()
	local variant = mapType:getVariant()
	local mt = match(mapType.__class, '^(%w+)MapType')
	if mt then
		blocked = self:query('BlockedBy', function(t)
			for _,p in pairs(t) do
				if p[mt] and (variant == p[mt] or p[mt] == 'ALL') then return true end
			end
			return false
		end)
	end

	return blocked
end

function Traveler:getMovePosition() return self._movePosition end

function Traveler:setMovePosition(v)
	verify('vector', v)
	self._movePosition = v
end

function Traveler:wantsToMove() return self._movePosition ~= nil end

function Traveler:move(pos, node)
	if self:canMove(node) then self:setPosition(pos) end
	self._movePosition = nil
end

-- the class
return Traveler
