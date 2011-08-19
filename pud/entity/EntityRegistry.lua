local Class = require 'lib.hump.class'

-- EntityRegistry
--
local EntityRegistry = Class{name='EntityRegistry',
	function(self)
		self._registry = {}
		self._byname = {}
		self._bytype = {}
	end
}

-- destructor
function EntityRegistry:destroy()
	for k in pairs(self._registry) do
		self._registry[k]:destroy()
		self._registry[k] = nil
	end
	self._registry = nil

	for k,v in pairs(self._byname) do
		for j in pairs(v) do v[j] = nil end
		self._byname[k] = nil
	end
	self._byname = nil

	for k,v in pairs(self._bytype) do
		for j in pairs(v) do v[j] = nil end
		self._bytype[k] = nil
	end
	self._bytype = nil
end

function EntityRegistry:register(entity)
	verifyClass('pud.entity.Entity', entity)
	local id = entity:getID()
	local name = entity:getName()
	local etype = entity:getType()
	verify('number', id)
	verify('string', name, etype)

	if nil ~= self._registry[id] then
		warning('Entity registration overwitten: %s (%d)', name, id)
	end

	self._registry[id] = entity

	self._byname[name] = self._byname[name] or {}
	local num = #(self._byname[name])
	self._byname[name][num+1] = id

	self._bytype[etype] = self._bytype[etype] or {}
	num = #(self._bytype[etype])
	self._bytype[etype][num+1] = id
end

local _removeID = function(id, t)
	local num = #t
	local found = false

	for i=1,num do
		local num2 = #(t[i])
		local new = {}
		local newCount = 1

		for j=1,num2 do
			if t[i][j] == id then
				found = true
			else
				new[newCount] = t[i][j]
				newCount = newCount + 1
			end
			t[i][j] = nil
		end

		if #new == 0 then
			t[i] = nil
		else
			t[i] = new
		end

		if found then break end
	end
end

function EntityRegistry:unregister(id)
	local entity = self._registry[id]
	assert(entity, 'No such entity to unregister: %d', id)

	self._registry[id] = nil
	_removeID(id, self._byname)
	_removeID(id, self._bytype)

	return entity
end

function EntityRegistry:exists(id) return self._registry[id] ~= nil end
function EntityRegistry:get(id) return self._registry[id] end
function EntityRegistry:getIDsByName(name) return self._byname[name] end
function EntityRegistry:getIDsByType(etype) return self._bytype[etype] end

-- the class
return EntityRegistry
