local Class = require 'lib.hump.class'
local AttachmentComponent = getClass 'pud.component.AttachmentComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- ArmorAttachmentComponent
--
local ArmorAttachmentComponent = Class{name='ArmorAttachmentComponent',
	inherits=AttachmentComponent,
	function(self, properties)
		AttachmentComponent.construct(self, properties, 'Armor', 1)
	end
}

-- destructor
function ArmorAttachmentComponent:destroy()
	AttachmentComponent.destroy(self)
end


-- the class
return ArmorAttachmentComponent
