local Class = require 'lib.hump.class'

local json = require 'lib.dkjson'

local format, match, tostring = string.format, string.match, tostring
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
	self._etype = nil

	for i=1,#self._byFilename do self._byFilename[i] = nil end
	self._byFilename = nil

	for k,v in pairs(self._byELevel) do
		for j in pairs(v) do v[j] = nil end
		self._byELevel[k] = nil
	end
	self._byELevel = nil

	for k,v in pairs(self._byFam) do
		for j in pairs(v) do v[j] = nil end
		self._byFam[k] = nil
	end
	self._byFam = nil

	for k,v in pairs(self._byFamK) do
		for j in pairs(v) do v[j] = nil end
		self._byFamK[k] = nil
	end
	self._byFamK = nil

	for i=1,#self._byFamKV do self._byFamKV[i] = nil end
	self._byFamKV = nil

	for i=1,#self._byName do self._byName[i] = nil end
	self._byName = nil
end

-- load all entity files of self._etype
function EntityDB:load()
	local path = 'entity/'..self._etype
	local entityFiles = enumerate(path)
	local numFiles = #entityFiles

	for i=1,numFiles do
		local filename = entityFiles[i]

		local contents, size = read(path..'/'..filename)

		-- these files should be at mininmum 27 bytes
		if size < 27 then
			error('File does not appear to be an entity definition: '..filename)
		end

		local info, pos, err = json.decode(contents)
		if err then error(err) end

		filename = match(filename, "(%w+).json") or filename
		info.filename = filename
		self:_processEntityInfo(info)
	end
end

-- process information read from entity file and store for easy retrieval
function EntityDB:_processEntityInfo(info)
	if not info.family then
		warning('No family defined for %s', info.filename)
		info.family = "FAMILY?"
	end
	if not info.kind then
		warning('No kind defined for %s', info.filename)
		info.kind = "KIND?"
	end

	info.variation = info.variation or 1
	info.name = info.name or format("%s %s (%d)",
		info.family, info.kind, info.variation)

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

	info.elevel = self:_calculateELevel(info)
	if info.elevel then
		key = info.elevel
		self._byELevel[key] = self._byELevel[key] or setmetatable({}, _mt)
		size = #(self._byELevel[key])
		self._byELevel[key][size+1] = info
	end
end

-- get the predefined weights for properties, to caluclate ELevel.
-- this is the main reason to subclass this class.
function EntityDB:_getPropertyWeights() return nil end

-- calculate the elevel of this entity based on relevant properties.
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

	for p,t in pairs(found) do
		local weight, value = t.weight, t.value
		if type(value) == 'boolean' then value = value and 1 or 0 end
		elevel = elevel + (weight * value)
	end

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
