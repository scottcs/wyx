local Class = require 'lib.hump.class'

local table_sort = table.sort
local strhash, dec2hex, hex2dec = strhash, dec2hex, hex2dec

-- EntityRegistry
--
local EntityRegistry = Class{name='EntityRegistry',
	function(self)
		self._registry = {}
		self._byname = {}
		self._bytype = {}
		self._duplicates = {}
		self._duplicatesRev = {}
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

	self._loadstate = nil
	self._duplicates = nil
	self._duplicatesRev = nil
end

local _id_inc = 0
function EntityRegistry:register(entity)
	verifyClass('wyx.entity.Entity', entity)
	local regkey = entity:getRegKey()
	local name = entity:getName()
	local etype = entity:getEntityType()
	verify('string', name, regkey, etype)

	-- not really necessary to wrap around like this in Lua, I guess.
	-- but, just in case.
	_id_inc = _id_inc < 100000000 and _id_inc + 1 or 1
	local key = regkey..tostring(_id_inc)

	local id = dec2hex(strhash(key))
	entity:setID(id)

	if nil ~= self._registry[id] then
		warning('Entity registration overwitten: %s (%s)', regkey, id)
	end

	self._registry[id] = entity

	if debug then
		Console:print('Registered Entity: {%08s} %s [%s]', id, regkey, etype)
	end

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
	if self._duplicates[id] then
		id, self._duplicates[id] = self._duplicates[id], nil
		self._duplicatesRev[id] = nil
	elseif self._duplicatesRev[id] then
		self._duplicates[self._duplicatesRev[id]] = nil
		self._duplicatesRev[id] = nil
	end

	local entity = self._registry[id]
	assert(entity, 'No such entity to unregister: %s', id)

	if debug then
		Console:print('Unregistered Entity: {%08s} %s [%s]',
			id, entity:getName(), entity:getEntityType())
	end

	self._registry[id] = nil
	_removeID(id, self._byname)
	_removeID(id, self._bytype)

	return entity
end

function EntityRegistry:get(id)
	id = self._duplicates[id] or id
	return self._registry[id]
end
function EntityRegistry:exists(id)
	id = self._duplicates[id] or id
	return self._registry[id] ~= nil
end
function EntityRegistry:getIDsByName(name) return self._byname[name] end
function EntityRegistry:getIDsByType(etype) return self._bytype[etype] end

function EntityRegistry:_getIDTable()
	local allIDs = {}
	local count = 0
	if self._registry then
		for k in pairs(self._registry) do
			count = count + 1
			allIDs[count] = k
		end
		table.sort(allIDs)
	end
	return count > 0 and allIDs or nil
end

function EntityRegistry:iterate()
	local allIDs = self:_getIDTable()
	if not allIDs then return nil end
	local i = 0
	return function()
		i = i + 1
		local id = allIDs[i]
		return id, self._registry[id]
	end
end

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

	local hero = self._bytype['hero']
	local enemy = self._bytype['enemy']
	local item = self._bytype['item']

	local num, count = 0, 0
	local heroes, enemies, items

	if hero then heroes = self:_sortEntities(hero) end
	if enemy then enemies = self:_sortEntities(enemy) end
	if item then items = self:_sortEntities(item) end

	if heroes or enemies or items then
		Console:print('Registered Entities:')
		Console:print('  %-11s %4s  %s', 'ID', 'ELVL', 'REGKEY')
		if heroes then self:_printEntitiesToConsole(heroes, 'WHITE') end
		if enemies then self:_printEntitiesToConsole(enemies, 'LIGHTRED') end
		if items then self:_printEntitiesToConsole(items, 'BLUE') end
	else
		Console:print('RED', 'No entities to dump!')
	end
end

function EntityRegistry:_sortEntities(ents)
	local sorted = setmetatable({}, {__mode='kv'})
	local count = 0
	local num = #ents

	for i=1,num do
		local id = ents[i]
		count = count + 1
		sorted[count] = self:get(id)
	end

	if count > 0 then
		table.sort(sorted, _byElevel)
		return sorted
	end
end

function EntityRegistry:_printEntitiesToConsole(ents, color)
	local num = #ents
	color = color or 'GREY50'
	for i=1,num do
		local e = ents[i]
		local id = e:getID() or '?'
		local elevel = e:getELevel() or -1
		local regkey = e:getRegKey() or '?'
		Console:print(color, '  {%08s} %4d  %s', id, elevel, regkey)
	end
end

-- get the state of the registry for serialization
function EntityRegistry:getState()
	local state = {}

	for id,entity in self:iterate() do
		state[id] = entity:getState()
	end

	return state
end

-- set the state of the registry from load
function EntityRegistry:setState(state) self._loadstate = state end

-- return an entity's load state
function EntityRegistry:getEntityLoadState(id)
	if self._loadstate and self._loadstate[id] then
		return self._loadstate[id]
	end
	return nil
end

-- set an id as a duplicate to another id
function EntityRegistry:setDuplicateID(oldID, newID)
	self._duplicates[oldID] = newID
	self._duplicatesRev[newID] = oldID
end

-- get the currently valid duplicate ID
function EntityRegistry:getValidID(id)
	if self._duplicates[id] then return self._duplicates[id] end
	if self._registry[id] then return id end
end


-- the class
return EntityRegistry
