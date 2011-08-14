local vector = require 'lib.hump.vector'

-- common query functions
-- t is guaranteed to be an array with at least one value
-- each funciton is recursive to enable operating on nested tables

local sumFunc = function(t)
	local sum
	local isTable = type(t[1]) == 'table'
	local isVector = vector.isvector(t[1])

	for k,v in pairs(t) do
		if isVector or type(v) == 'number' then
			sum = sum and sum + v or v
		elseif isTable then
			sum = sum or {}
			for key,val in pairs(v) do
				if type(val) == 'number' then
					sum[key] = sum[key] and sum[key] + val or val
				end
			end
		end
	end

	return sum
end


local meanFunc = function(t)
	local mean
	local count = 0
	local isTable = type(t[1]) == 'table'
	local isVector = vector.isvector(t[1])

	for k,v in pairs(t) do
		if isVector or type(v) == 'number' then
			mean = mean and mean + v or v
			count = count + 1
		elseif isTable then
			mean = mean or {}
			local found = false
			for key,val in pairs(v) do
				if type(val) == 'number' then
					mean[key] = mean[key] and mean[key] + val or val
					found = true
				end
			end
			if found then count = count + 1 end
		end
	end

	if isTable then
		for k in pairs(mean) do mean[k] = mean[k] / count end
	else
		mean = mean/count
	end

	return mean
end


local productFunc = function(t)
	local product
	local isTable = type(t[1]) == 'table'
	local isVector = vector.isvector(t[1])

	for k,v in pairs(t) do
		if isVector or type(v) == 'number' then
			product = product and product * v or v
		elseif isTable then
			product = product or {}
			for key,val in pairs(v) do
				if type(val) == 'number' then
					product[key] = product[key] and product[key] * val or val
				end
			end
		end
	end

	return product
end

local boolAndFunc = function(t)
	local bool = true
	local count = 0
	for k,v in pairs(t) do
		if type(v) == 'boolean' then
			bool = bool and v
			count = count + 1
		end
	end

	return count>0 and bool
end

local boolOrFunc = function(t)
	for k,v in pairs(t) do
		if type(v) == 'boolean' then
			if v then return true end
		end
	end

	return false
end

local randomFunc = function(t) return t[Random(#t)] end
local existsFunc = function(t) return true end


return {
	sum = sumFunc,
	mean = meanFunc,
	product = productFunc,
	booland = boolAndFunc,
	boolor = boolOrFunc,
	random = randomFunc,
	exists = existsFunc
}
