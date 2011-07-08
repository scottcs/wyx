
-- RandomBag
-- Provides a container for a range of numbers which can be randomly iterated
-- over. Guarantees that every number will be seen once before any number is
-- seen again.
--
-- Taken from vrld's game 'Princess'.

local table_remove, math_random
    = table.remove, math.random

local RandomBag = Class{name = 'RandomBag', function(self, a,b)
	self.bag = {}
	self.interval = {a,b}
end}

function RandomBag:next()
	-- refill an empty bag first
	if #self.bag == 0 then
		self:refill()
	end

	-- pop the top number off the stack and return it
	return table_remove(self.bag)
end

function RandomBag:refill()
	-- fill the bag with numbers in the range of the interval given
	for i=self.interval[1],self.interval[2] do
		self.bag[#self.bag+1] = i
	end

	-- randomly swap each number in the bag
	for i=#self.bag,1,-1 do
		local k = math_random(1, i)
		self.bag[i],self.bag[k] = self.bag[k],self.bag[i]
	end
end

return RandomBag
