
         --[[--
        UTILITIES
         --]]--

--------------------------
-- handy switch statement --
--------------------------
function switch(x)
	return function (of)
		local what = of[x] or of.default
		if type(what) == "function" then
			return what()
		end
		return what
	end
end

--[[ EXAMPLES
self.animation_offset = switch(self.anim.position) {
		[2] = vector(0,-1),
		[3] = vector(1,-1),
		[4] = vector(1,0),
		default = vector(0,0),
}

local x = switch (position) {
		left    = 0, -- same as ['left'] = 0
		center  = (love.graphics.getWidth() - self.width) / 2,
		right   = love.graphics.getWidth() - self.width,
		default = 100
}

-- function evaluation
switch (key) {
		up    = function() player.move(0,-1) end,
		down  = function() player.move(0,1) end,
		left  = function() player.move(-1,0) end,
		right = function() player.move(1,0) end,
}
--]]


------------------------------
-- get nearest power of two --
------------------------------
function nearestPO2(x)
	local po2 = {0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096}

	assert(x <= po2[#po2], 'higher than '..po2[#po2]..' is not supported')

	for i=#po2-1,1,-1 do
		if x > po2[i] then return po2[i+1] end
	end

	return 2
end

--[[ EXAMPLES
local fb = love.graphics.newFramebuffer(nearestPO2(love.graphics.getWidth()),
																				nearestPO2(love.graphics.getHeight()))
--]]


-----------------
-- fast assert --
-----------------
do
	local oldassert, format, select = assert, string.format, select
	assert = function(condition, ...)
		if condition then return condition end
		if select('#', ...) > 0 then
			oldassert(condition, format(...))
		else
			oldassert(condition)
		end
	end
end

-- assert helpers
function verify(t, ...)
	for i=1,select('#', ...) do
		local x = select(i, ...)
		assert(type(x) == t, '%s expected (was %s)', t, type(x))
	end
	return true
end

-------------
-- warning --
-------------
function warning(msg, ...)
	msg = msg or 'unknown warning'
	msg = 'Warning: '..msg..'\n'
	io.stderr:write(string.format(msg, ...))
end
