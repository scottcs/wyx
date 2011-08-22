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
function CollisionSystem:register(comp)
	local obj = comp:getMediator()
	assert(obj, 'Could not register component: %s', tostring(comp))
	self._registered:push(obj)
end

-- unregister an object
function CollisionSystem:unregister(comp)
	local obj = comp:getMediator()
	self._registered:pop(obj)
end

-- check for collision between the given object and position
function CollisionSystem:check(obj, x, y)
	local collision = false
	local oldpos = obj:query(property('Position'))
	local entities = self._level:getEntitiesAtLocation(x, y)
	local collideEnemy = message('COLLIDE_ENEMY')
	local collideHero = message('COLLIDE_HERO')


	if entities then
		local numEntities = #entities
		for i=1,numEntities do
			local otherEntityID = entities[i]
			local otherEntity = EntityRegistry:get(otherEntityID)
			if otherEntity ~= obj and self._registered:exists(otherEntity) then
				local otherEntityType = otherEntity:getEntityType()
				if otherEntityType == 'enemy' then
					obj:send(collideEnemy, otherEntityID)
					collision = true
				elseif otherEntityType == 'hero' then
					obj:send(collideHero, otherEntityID)
					collision = true
				end
			end
		end
	end

	if not collision then
		local node = self._level:getMapNode(x, y)
		if obj:query(property('BlockedBy'), node) then
			obj:send(message('COLLIDE_BLOCKED'), node, x, y)
			collision = true
		end
	end

	if not collision then
		obj:send(message('COLLIDE_NONE'), x, y)
	end

	return collision
end


-- the class
return CollisionSystem
