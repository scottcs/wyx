local Class = require 'lib.hump.class'
local Node = getClass 'pud.kit.Node'

-- Deque
-- A Deque is a container that allows items to be added and removed from both
-- the front and back, acting as a combination of a Stack and Queue.
-- This implementation uses a doubly-linked list, guaranteeing O(1) complexity
-- for all operations.
--
-- Constructor takes an optional array argument to initialize the Deque.
local Deque = Class{name='Deque',
	function(self, t)
		self._size = 0

		if t then
			assert(type(t) == 'table' and #t > 0,
				'Deque must be initialized with an array or nil')
			for i=1,#t do self:push_back(t[i]) end
		end
	end
}

-- private funtion to clear the Deque when empty.
local _clear = function(self)
	self._front = nil
	self._back = nil
	self._size = 0
end

-- returns the number of objects in the Deque.
function Deque:size() return self._size end

-- adds an object at the back of the Deque
function Deque:push_back(obj)
	local n = Node(obj)

	if self._back then
		n.left = self._back
		self._back.right = n
		self._back = n
	else
		self._front, self._back = n, n
	end

	self._size = self._size + 1
	return obj
end

-- adds an object at the front of the Deque
function Deque:push_front(obj)
	local n = Node(obj)

	if self._front then
		n.right = self._front
		self._front.left = n
		self._front = n
	else
		self._front, self._back = n, n
	end

	self._size = self._size + 1
	return obj
end

-- returns the back object of the Deque and removes it.
function Deque:pop_back()
	if not self._back then return end

	local n = self._back
	local obj = n.obj
	
	if self._size == 1 then
		_clear(self)
		n:destroy()
		return obj
	else
		self._back.left.right = nil
		self._back = self._back.left
		n:destroy()
	end

	self._size = self._size - 1
	return obj
end

-- returns the front object of the Deque and removes it.
function Deque:pop_front()
	if not self._front then return end

	local n = self._front
	local obj = n.obj

	if self._size == 1 then
		_clear(self)
		n:destroy()
		return obj
	else
		self._front.right.left = nil
		self._front = self._front.right
		n:destroy()
	end

	self._size = self._size - 1
	return obj
end

-- returns the back object of the Deque but does not remove it.
function Deque:back()
	return self._back and self._back.obj or nil
end

-- returns the front object of the Deque but does not remove it.
function Deque:front()
	return self._front and self._front.obj or nil
end

-- rotates the front of the Deque to the back.
function Deque:rotate_forward()
	if self._size > 1 then
		self._front.right.left = nil
		self._front.left = self._back
		self._back.right, self._back = self._front, self._front
		self._front, self._front.right = self._front.right, nil
	end
end

-- rotates the back of the Deque to the front.
function Deque:rotate_backward()
	if self._size > 1 then
		self._back.left.right = nil
		self._back.right = self._front
		self._front.left, self._front = self._back, self._back
		self._back, self._back.left = self._back.left, nil
	end
end

-- iterate through the queue
function Deque:iterate()
	local which = {right = self._front}
	return function() which = which.right; return which and which.obj or nil end
end

-- removes all the objects in the Deque.
function Deque:clear()
	for i=1,self._size do self:pop_front() end
	_clear(self)
end

-- deconstructor
function Deque:destroy()
	self:clear()
	self._size = nil
end

return Deque
