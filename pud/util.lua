local select, type, tostring = select, type, tostring
local format, io_stderr = string.format, io.stderr

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

local vector = require 'lib.hump.vector'

-- assert helpers
function verify(theType, ...)
	for i=1,select('#', ...) do
		local x = select(i, ...)
		local xType = type(x)
		if theType == 'vector' then
			assert(vector.isvector(x), 'vector expected (was %s)', xType)
		else
			assert(xType == theType, '%s expected (was %s)', theType, xType)
		end
	end
	return true
end


function verifyClass(className, ...)
	verify('string', className)

	for i=1,select('#', ...) do
		local obj = select(i, ...)
		assert(pud.isClass(className, obj),
			'expected %s (was %s, %s)', className, type(obj), tostring(obj))
	end

	return true
end


-------------
-- warning --
-------------
function warning(msg, ...)
	msg = msg or 'unknown warning'
	msg = 'Warning: '..msg..'\n'
	io_stderr:write(format(msg, ...))
end

-------------------------------------
-- pud namespace and class helpers --
-------------------------------------
pud = {}

local _pudPath = ';pud/?.lua'
local pudfiles = love.filesystem.enumerate('pud')
for _,file in pairs(pudfiles) do
	if love.filesystem.isDirectory(file) then
		_pudPath = _pudPath..';pud/'..file..'/?.lua'
	end
end

local _classCache = {}
local _verifyCache = {}
local _mt = {__mode = 'k'}

-- cache class objects (even though Lua does this).
-- this also avoids weird loop errors with require.
function pud.getClass(className)
	verify('string', className)
	local theClass = _classCache[className]

	if nil == theClass then
		local oldPath = package.path
		package.path = package.path.._pudPath
		local ok,theClass = pcall(require, className)
		if not ok then error(theClass) end
		package.path = oldPath
		_classCache[className] = theClass
	end

	return theClass
end

-- convenience function to get a new object of className
function pud.new(className, ...)
	local theClass = pud.getClass(className)
	return theClass.new(...)
end

function pud.isClass(className, obj)
	verify('string', className)
	if obj == nil then return false end

	_verifyCache[className] = _verifyCache[className] or setmetatable({}, _mt)
	local is = _verifyCache[className][obj]

	if nil == is then
		local theClass = pud.getClass(className)
		is = type(obj) == 'table' and obj.is_a and type(obj.is_a) == 'function'
			and obj:is_a(theClass)

		_verifyCache[className][obj] = is
	end

	return is
end

