local Class = require 'lib.hump.class'
local Expression = getClass 'wyx.component.Expression'
local property = require 'wyx.component.property'

local json = require 'lib.dkjson'

local format, match, tostring = string.format, string.match, tostring
local gsub = string.gsub
local warning, error, pairs, verify = warning, error, pairs, verify
local setmetatable = setmetatable
local math_floor = math.floor
local _round = function(x) return math_floor(x+0.5) end
local enumerate = love.filesystem.enumerate
local read = love.filesystem.read

local _mt = {__mode = 'v'}

-- EntityDB
--
local EntityDB = Class{name='EntityDB',
	function(self, etype)
		self._etype = etype or "UNKNOWN"
		self._byFilename = setmetatable({}, _mt)
		self._byName = {}
		self._byELevel = {}
		self._byFam = {}
		self._byFamK = {}
		self._byFamKV = setmetatable({}, _mt)
	end
}

-- destructor
function EntityDB:destroy()
	self:clear()
	self._etype = nil
	self._byFilename = nil
	self._byELevel = nil
	self._byFam = nil
	self._byFamK = nil
	self._byFamKV = nil
	self._byName = nil
end

-- clear all loaded data
function EntityDB:clear()
	for i=1,#self._byFilename do self._byFilename[i] = nil end

	for k,v in pairs(self._byELevel) do
		for j in pairs(v) do v[j] = nil end
		self._byELevel[k] = nil
	end

	for k,v in pairs(self._byFam) do
		for j in pairs(v) do v[j] = nil end
		self._byFam[k] = nil
	end

	for k,v in pairs(self._byFamK) do
		for j in pairs(v) do v[j] = nil end
		self._byFamK[k] = nil
	end

	for i=1,#self._byFamKV do self._byFamKV[i] = nil end

	for i=1,#self._byName do self._byName[i] = nil end
end

-- load all entity files of self._etype
function EntityDB:load()
	local path = 'entity/'..self._etype
	local entityFiles = enumerate(path)
	local numFiles = #entityFiles

	if Console then Console:print('Loading %q Entities...', self._etype) end

	self:clear()

	for i=1,numFiles do
		local filename = entityFiles[i]
		if Console then Console:print('  %s', filename) end


		local contents, size = read(path..'/'..filename)

		-- these files should be at mininmum 27 bytes
		if size < 27 then
			error('File does not appear to be an entity definition: '..filename)
		end

		local info, pos, err = json.decode(contents)
		if err then error(err) end

		filename = match(filename, "(%w+).json") or filename
		info.filename = filename

		local added = false
		if self:_processEntityInfo(info) then
			if self:_evaluateEntityInfo(info) then
				if self:_postProcessEntityInfo(info) then
					self:_addToDB(info)
					added = true
				end
			end
		end

		if not added then
			warning('Entity was not loaded: %s', filename)
		end
	end
end

function EntityDB:_addToDB(info)
	self._byFilename[info.filename] = info
	self._byName[info.name] = info

	local size, key

	key = info.family
	self._byFam[key] = self._byFam[key] or setmetatable({}, _mt)
	size = #(self._byFam[key])
	self._byFam[key][size+1] = info

	key = format("%s-%s", key, info.kind)
	self._byFamK[key] = self._byFamK[key] or setmetatable({}, _mt)
	size = #(self._byFamK[key])
	self._byFamK[key][size+1] = info

	key = format("%s-%s", key, tostring(info.variation))
	self._byFamKV[key] = info
end

-- process information read from entity file and store for easy retrieval
function EntityDB:_processEntityInfo(info)
	if not info.family then
		warning('No family defined for %s', info.filename)
		return false
	end

	if not info.kind then
		warning('No kind defined for %s', info.filename)
		return false
	end

	info.variation = info.variation or 1
	info.name = info.name or format("%s %s %d",
		info.family, info.kind, info.variation)

	return true
end

-- evaluate strings in top level fields in the info table, and turn them into
-- valid lua functions if necessary
function EntityDB:_evaluateEntityInfo(info)
	if info.components then
		for comp,props in pairs(info.components) do
			for p,data in pairs(props) do
				p = property(p)
				if nil == p then return false end
				if type(data) == 'function' then return false end
				-- check if it's an expression to evaluate
				if Expression.isExpression(data) then
					local expr, err = Expression.makeExpression(data)

					if nil == expr then
						warning('Invalid expression: %s', data)
						if err then warning('  (%s)', err) end
						props[p] = nil
					else
						props[p] = expr
					end -- if nil == expr
				end -- if Expression
			end -- for p,data
		end -- for comp,props
	end -- if info.components

	return true
end

-- perform any data cleanup needed after processing and evaluation
function EntityDB:_postProcessEntityInfo(info)
	if info.components then
		local warned = {}
		for comp,props in pairs(info.components) do
			for p,data in pairs(props) do
				p = property(p)
				if nil == p then return false end
				if self._etype == 'item' then
					-- with item entities, for properties with *Bonus counterparts, move
					-- the data to the Bonus property if it doesn't exist, otherwise
					-- just remove it.
					local bonus = p..'Bonus'
					if property.isproperty(bonus) then
						if props[bonus] and not warned[bonus] then
							warning('Please do not use *Bonus properties in entity files;')
							warning('  %q not used (%q exists) in %s.',
								p, bonus, info.filename)
						else
							props[bonus] = data
							warned[bonus] = true
						end
						props[p] = nil
					else
						local normal = match(p, '(.*)Bonus')
						if normal and not warned[p] then
							warning('Please do not use *Bonus properties in entity files.')
							warning('  %q should be specified as %q in %s',
								p, normal, info.filename)
						end
					end -- if property.isproperty...
				else
					-- with non-item entities, for properties with *Bonus counterparts,
					-- move the Bonus property to the non-Bonus data if it doesn't
					-- exist, otherwise just remove it.
					local normal = match(p, '(.*)Bonus')
					if normal and property.isproperty(normal) then
						warning('Please do not use *Bonus properties in entity files;')
						if props[normal] then
							warning('  %q not used (%q exists) in %s.',
								p, normal, info.filename)
						else
							warning('  %q moved to %q in %s.',
								p, normal, info.filename)
							props[normal] = data
						end
						props[p] = nil
					end -- if normal and ...
				end -- if self._etype == 'item
			end -- for p,data in props
		end -- for comp,props in info.components
	end -- if info.components

	info.elevel = self:_calculateELevel(info)
	if info.elevel then
		key = info.elevel
		self._byELevel[key] = self._byELevel[key] or setmetatable({}, _mt)
		size = #(self._byELevel[key])
		self._byELevel[key][size+1] = info
	end

	return true
end

-- get the predefined weights for properties, to calculate ELevel.
-- this is the main reason to subclass this class.
function EntityDB:_getPropertyWeights() return nil end

-- calculate the elevel of this entity based on relevant properties.
-- TODO: Entity.evaluate(expression) 100 times and take average.
function EntityDB:_calculateELevel(info)
	local props = self:_getPropertyWeights()
	local found = {}

	if info.components and props then
		for comp,cprops in pairs(info.components) do
			for p,t in pairs(props) do
				local prop = t.name
				if cprops[prop] then
					found[p] = {weight = t.weight, value = cprops[prop]}
				end
			end
		end
	end

	local elevel = 0.1
	local tempEntity
	if self._factory then
		local id = self._factory:createEntity(info)
		tempEntity = EntityRegistry:get(id)
	end

	for p,t in pairs(found) do
		local weight, value = t.weight, t.value
		if type(value) == 'boolean' then value = value and 1 or 0 end
		if Expression.isCreatedExpression(value) then
			if tempEntity then
				local func = value.onCreate or value.onAccess
				local sum = 0
				for i=1,100 do sum = sum + func(tempEntity) end
				value = sum/100
			else
				value = 0
			end
		end
		elevel = elevel + (weight * value)
	end

	EntityRegistry:unregister(tempEntity:getID())
	tempEntity:destroy()

	return _round(elevel*10)
end

-- get by filename
function EntityDB:getByFilename(filename)
	filename = match(filename, "(%w+).json") or filename
	return self._byFilename[filename]
end

-- get by ID (lookup familty, kind and variation from entity with id ID)
function EntityDB:getByID(id)
	local entity = EntityRegistry:get(id)
	if not entity then return nil end

	local fam = entity:getFamily()
	local kind = entity:getKind()
	local var = entity:getVariation()

	return self:getByFamily(fam, kind, var)
end

-- get by name
function EntityDB:getByName(name) return self._byName[name] end

-- get by family
-- get by family and kind
-- get by family and kind and variation
function EntityDB:getByFamily(family, kind, variation)
	if kind and variation then
		local key = format("%s-%s-%s", family, kind, tostring(variation))
		return self._byFamKV[key]
	elseif kind then
		local key = format("%s-%s", family, kind)
		return self._byFamK[key]
	end

	return self._byFam[family]
end

-- get by property in range A..B (including default properties)
--   OR
-- get by heuristic entity level (calculated from properties)
function EntityDB:getByELevel(min, max)
	if not max then return self._byELevel[min] end

	local results = {}
	local count = 1
	for i=min,max do
		local t = self._byELevel[i]
		if t then
			local num = #t
			for j=1,num do
				results[count] = t[j]
				count = count + 1
			end
		end
	end

	return results
end


-- the class
return EntityDB
