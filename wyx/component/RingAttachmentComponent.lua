local Class = require 'lib.hump.class'
local AttachmentComponent = getClass 'wyx.component.AttachmentComponent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'


-- RingAttachmentComponent
--
local RingAttachmentComponent = Class{name='RingAttachmentComponent',
	inherits=AttachmentComponent,
	function(self, properties)
		AttachmentComponent.construct(self, properties, 'Ring', 1)
	end
}

-- destructor
function RingAttachmentComponent:destroy()
	AttachmentComponent.destroy(self)
end


-- the class
return RingAttachmentComponent
