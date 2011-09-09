local Class = require 'lib.hump.class'
local ListenerBag = getClass 'wyx.kit.ListenerBag'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'
local match = string.match

-- CollisionSystem
--
local CollisionSystem = Class{name='CollisionSystem',
	function(self, level)
		self._registered = ListenerBag()
		if level then
			self:setLevel(level)
		end
	end
}

-- destructor
function CollisionSystem:destroy()
	self._registered:destroy()
	self._registered = nil
	self._level = nil
end

-- set the level that will be checked for collisions
function CollisionSystem:setLevel(level)
	verifyClass('wyx.map.Level', level)
	self._level = level
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
	local collideHero = message('COLLIDE_HERO')
	local collideEnemy = message('COLLIDE_ENEMY')
	local collideItem = message('COLLIDE_ITEM')


	if entities then
		local numEntities = #entities
		for i=1,numEntities do
			local otherEntityID = entities[i]
			local otherEntity = EntityRegistry:get(otherEntityID)
			if otherEntity ~= obj and self._registered:exists(otherEntity) then
				local otherEntityType = otherEntity:getEntityType()
				if otherEntityType == 'hero' then
					obj:send(collideHero, otherEntityID)
					collision = true
				elseif otherEntityType == 'enemy' then
					obj:send(collideEnemy, otherEntityID)
					collision = true
				elseif otherEntityType == 'item' then
					obj:send(collideItem, otherEntityID)
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
