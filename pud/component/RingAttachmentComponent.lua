local Class = require 'lib.hump.class'
local AttachmentComponent = getClass 'pud.component.AttachmentComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


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
