local Class = require 'lib.hump.class'
local AttachmentComponent = getClass 'pud.component.AttachmentComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- WeaponAttachmentComponent
--
local WeaponAttachmentComponent = Class{name='WeaponAttachmentComponent',
	inherits=AttachmentComponent,
	function(self, properties)
		AttachmentComponent.construct(self, properties, 'Weapon', 1)
	end
}

-- destructor
function WeaponAttachmentComponent:destroy()
	AttachmentComponent.destroy(self)
end


-- the class
return WeaponAttachmentComponent