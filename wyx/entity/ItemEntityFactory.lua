local Class = require 'lib.hump.class'
local EntityFactory = getClass 'wyx.entity.EntityFactory'
local depths = require 'wyx.system.renderDepths'
local property = require 'wyx.component.property'

local match = string.match

-- ItemEntityFactory
-- creates entities based on data files
local ItemEntityFactory = Class{name='ItemEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'item')
		self._renderDepth = depths.gameitem
		self._requiredComponents = {
			getClass 'wyx.component.MotionComponent',
			getClass 'wyx.component.CollisionComponent',
			getClass 'wyx.component.GraphicsComponent',
			getClass 'wyx.component.ControllerComponent',
		}
	end
}

-- destructor
function ItemEntityFactory:destroy()
	EntityFactory.destroy(self)
end

function ItemEntityFactory:_postProcess(entity)
	EntityFactory._postProcess(self, entity)

	-- set default values to 0 for non-bonus properties
	local comps = entity:getComponentsByClass(
		getClass('wyx.component.Component'))

	local num = #comps
	for i=1,num do
		local comp = comps[i]
		if not isClass('wyx.component.TimeComponent', comp) then
			local toZero = {}

			for p in pairs(comp._properties) do
				local normal = match(p, '(.*)Bonus$')
				if normal and property.isproperty(normal) then
					toZero[#toZero+1] = normal
				end
			end

			local num = #toZero
			if num > 0 then
				for i=1,num do
					local p = toZero[i]
					comp:_setProperty(p, 0)
				end
			end
		end
	end
end

-- the class
return ItemEntityFactory
