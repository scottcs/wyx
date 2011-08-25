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
	local etype = entity:getEntityType()
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
	local found = false

	for k,v in pairs(t) do
		local num = #v
		local new = {}
		local newCount = 1

		for i=1,num do
			if v[i] == id then
				found = true
			else
				new[newCount] = v[i]
				newCount = newCount + 1
			end
			v[i] = nil
		end

		if #new == 0 then
			t[k] = nil
		else
			t[k] = new
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

local _byElevel = function(a, b)
	if nil == a then return false end
	if nil == b then return true end
	local al = a:getELevel()
	local bl = b:getELevel()
	if nil == al then return false end
	if nil == bl then return true end
	return al < bl
end

-- debug function to print all entities to console by elevel
function EntityRegistry:dumpEntities()

	local ents = setmetatable({}, {__mode='kv'})
	local hero = self._bytype['hero']
	local enemy = self._bytype['enemy']
	local item = self._bytype['item']

	local num, count = 0, 0

	num = #hero
	for i=1,num do
		local id = hero[i]
		count = count + 1
		ents[count] = self:get(id)
	end

	num = #enemy
	for i=1,num do
		local id = enemy[i]
		count = count + 1
		ents[count] = self:get(id)
	end

	num = #item
	for i=1,num do
		local id = item[i]
		count = count + 1
		ents[count] = self:get(id)
	end

	if count > 0 then
		table.sort(ents, _byElevel)
		Console:print('Registered Entities:')
		Console:print('  ID     ELVL  NAME')
		for i=1,count do
			local e = ents[i]
			local id = e:getID() or -1
			local elevel = e:getELevel() or -1
			local name = e:getName() or '?'
			Console:print('  {%04d} %4d  %s', id, elevel, name)
		end
	else
		Console:print('RED', 'No entities to dump!')
	end
end


-- the class
return EntityRegistry
