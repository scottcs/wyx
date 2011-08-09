-- common query functions
-- t is guaranteed to be an array with at least one value
-- each funciton is recursive to enable operating on nested tables

local sumFunc = function(t)
	local sum
	local isTable = type(t[1]) == 'table'

	for k,v in pairs(t) do
		if isTable then
			sum = sum or {}
			for key,val in pairs(v) do
				if type(val) == 'number' then
					sum[key] = sum[key] and sum[key] + val or val
				end
			end
		elseif type(v) == 'number' then
			sum = sum and sum + v or v
		end
	end

	return sum
end


local meanFunc = function(t)
	local mean
	local count = 0
	local isTable = type(t[1]) == 'table'

	for k,v in pairs(t) do
		if isTable then
			mean = mean or {}
			local found = false
			for key,val in pairs(v) do
				if type(val) == 'number' then
					mean[key] = mean[key] and mean[key] + val or val
					found = true
				end
			end
			if found then count = count + 1 end
		elseif type(v) == 'number' then
			mean = mean and mean + v or v
			count = count + 1
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

	for k,v in pairs(t) do
		if isTable then
			product = product or {}
			for key,val in pairs(v) do
				if type(val) == 'number' then
					product[key] = product[key] and product[key] * val or val
				end
			end
		elseif type(v) == 'number' then
			product = product and product * v or v
		end
	end

	return product
end


local randomFunc = function(t) return t[Random(#t)] end
local existsFunc = function(t) return true end


return {
	sum = sumFunc,
	mean = meanFunc,
	product = productFunc,
	random = randomFunc,
	exists = existsFunc
}
