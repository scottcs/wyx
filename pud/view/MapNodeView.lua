local Class = require 'lib.hump.class'
local Rect = getClass('pud.kit.Rect')

-- MapNodeView
-- prototype class for other MapNode view classes
local MapNodeView = Class{name='MapNodeView',
	inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)
		self._constructed = true
	end
}

-- destructor
function MapNodeView:destroy()
	self._constructed = nil
	Rect.destroy(self)
end

-- don't allow resizing
function MapNodeView:setSize(...)
	if self._constructed then
		error('Cannot resize MapNodeView. Please destroy and create a new one.')
	else
		Rect.setSize(self, ...)
	end
end
function MapNodeView:setWidth(...)
	if self._constructed then
		error('Cannot resize MapNodeView. Please destroy and create a new one.')
	else
		Rect.setWidth(self, ...)
	end
end
function MapNodeView:setHeight(...)
	if self._constructed then
		error('Cannot resize MapNodeView. Please destroy and create a new one.')
	else
		Rect.setHeight(self, ...)
	end
end

-- draw the level
function MapNodeView:draw() end

-- register events
function MapNodeView:registerEvents() end

-- handle events
function MapNodeView:onEvent(e, ...) end

-- the class
return MapNodeView
