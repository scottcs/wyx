local Class = require 'lib.hump.class'
local ListenerBag = getClass 'pud.kit.ListenerBag'
local property = require 'pud.component.property'
local message = require 'pud.component.message'
local match = string.match

-- CollisionSystem
--
local CollisionSystem = Class{name='CollisionSystem',
	function(self, level)
		self._registered = ListenerBag()
		self._level = level
	end
}

-- destructor
function CollisionSystem:destroy()
	self._registered:destroy()
	self._registered = nil
	self._level = nil
end

-- register an object
function CollisionSystem:register(obj)
	self._registered:push(obj)
end

-- unregister an object
function CollisionSystem:unregister(obj)
	self._registered:pop(obj)
end

-- check for collision between the given object and position
function CollisionSystem:check(obj, pos)
	local collision = false
	local oldpos = obj:query(property('Position'))
	local entities = self._level:getEntitiesAtLocation(pos)

	if entities then
		for _,otherEntity in pairs(entities) do
			if otherEntity ~= obj and self._registered:exists(otherEntity) then
				local otherEntityType = otherEntity:getType()
				if otherEntityType == 'enemy' then
					obj:send(message('COLLIDE_ENEMY'), otherEntity)
					collision = true
				elseif otherEntityType == 'hero' then
					obj:sent(message('COLLIDE_HERO'), otherEntity)
					collision = true
				end
			end
		end
	end

	if not collision then
		local node = self._level:getMapNode(pos)
		local blocked = false
		local mapType = node:getMapType()
		local variant = mapType:getVariant()
		local mt = match(tostring(mapType.__class), '^(%w+)MapType')
		if mt then
			blocked = obj:query(property('BlockedBy'), function(t)
				for _,p in pairs(t) do
					if p[mt] and (variant == p[mt] or p[mt] == 'ALL') then
						return true
					end
				end
				return false
			end)
		end
		if blocked then
			obj:send(message('COLLIDE_BLOCKED'), node)
			collision = true
		end
	end

	if not collision then
		obj:send(message('COLLIDE_NONE'), pos, oldpos)
	end

	return collision
end


-- the class
return CollisionSystem
