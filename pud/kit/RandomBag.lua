local Class = require 'lib.hump.class'

-- RandomBag
-- Provides a container for a range of numbers which can be randomly iterated
-- over. Guarantees that every number will be seen once before any number is
-- seen again.
--
-- Taken from vrld's game 'Princess' (and modified).

local table_remove, math_random
    = table.remove, math.random

local RandomBag = Class{name = 'RandomBag', function(self, a,b)
	self._bag = {}
	self._interval = {a,b}
end}

function RandomBag:_refill()
	-- fill the bag with numbers in the range of the interval given
	for i=self._interval[1],self._interval[2] do
		self._bag[#self._bag+1] = i
	end

	-- randomly swap each number in the bag
	for i=#self._bag,1,-1 do
		local k = math_random(1, i)
		self._bag[i],self._bag[k] = self._bag[k],self._bag[i]
	end
end

function RandomBag:next()
	-- _refill an empty bag first
	if #self._bag == 0 then
		self:_refill()
	end

	-- pop the top number off the stack and return it
	self._last = table_remove(self._bag)
	return self._last
end

-- return the last number pulled from the bag
function RandomBag:getLast()
	return self._last
end

function RandomBag:destroy()
	self._bag = nil
	self._interval = nil
end

return RandomBag
