local select, type, tostring = select, type, tostring
local pairs, error, setmetatable = pairs, error, setmetatable
local format, io_stderr = string.format, io.stderr

-- pud namespace
pud = {}


         --[[--
        UTILITIES
         --]]--

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


------------------------------
-- get nearest power of two --
------------------------------
function nearestPO2(x)
	local po2 = {0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096}

	assert(x <= po2[#po2], 'higher than %d is not supported', po2[#po2])

	for i=#po2-1,1,-1 do
		if x > po2[i] then return po2[i+1] end
	end

	return 2
end


-------------
-- warning --
-------------
function warning(msg, ...)
	msg = msg or 'unknown warning'
	msg = 'Warning: '..msg..'\n'
	io_stderr:write(format(msg, ...))
end


-------------------
-- class helpers --
-------------------

local _pudPath = ';./pud/?.lua'
local pudfiles = love.filesystem.enumerate('pud')
for _,file in pairs(pudfiles) do
	file = 'pud/'..file
	if love.filesystem.isDirectory(file) then
		_pudPath = _pudPath..';./'..file..'/?.lua'
	else
	end
end

local _classCache = {}
local _verifyCache = {}
local _mt = {__mode = 'k'}

-- cache class objects (even though Lua does this).
-- this also helps to avoid weird loop errors with require, by printing the
-- entire stack trace.
function pud.getClass(className)
	verify('string', className)
	local theClass = _classCache[className]

	if nil == theClass then
		local oldPath = package.path
		package.path = package.path.._pudPath

		local ok,res = xpcall(function()
			return require(className)
		end, debug.traceback)

		if not ok then error(res) end

		package.path = oldPath
		theClass = res
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


         --[[--
      LÖVE UTILITIES
         --]]--

---------------------------
-- loaders for resources --
---------------------------
local function Proxy(loader)
	return setmetatable({}, {__index = function(self, k)
		local v = loader(k)
		rawset(self, k, v)
		return v
	end})
end

State = Proxy(function(k)
	return assert(love.filesystem.load('state/'..k..'.lua'))()
end)
Font  = Proxy(function(k)
	return love.graphics.newFont('font/dejavu.ttf', k)
end)
Image = Proxy(function(k)
	local img = love.graphics.newImage('image/'..k..'.png')
	img:setFilter('nearest', 'nearest')
	return img
end)
Sound = Proxy(function(k)
	return love.audio.newSource(
		love.sound.newSoundData('sound/'..k..'.ogg'),
		'static')
end)


-----------------------------
-- float values for colors --
-----------------------------
do
	local type, setmetatable, table_concat = type, setmetatable, table.concat
	local sc = love.graphics.setColor
	local sbg = love.graphics.setBackgroundColor

	local _colorCache = setmetatable({}, {__mode='v'})
	local function color(r, g, b, a)
		local col = type(r) == 'table' and r or {r,g,b,a}
		local key = table_concat(col, '-')
		local c = _colorCache[key]

		if c == nil then
			if    col[1] <= 1 and col[1] >= 0
				and col[2] <= 1 and col[2] >= 0
				and col[3] <= 1 and col[3] >= 0
				and (not col[4] or (col[4] <= 1 and col[4] >= 0))
			then
				c = {255*col[1], 255*col[2], 255*col[3], 255*(col[4] or 1)}
			else
				c = {col[1], col[2], col[3], (col[4] or 1)}
			end
			_colorCache[key] = c
		end

		return c[1], c[2], c[3], c[4]
	end

	function love.graphics.setColor(r,g,b,a) sc(color(r,g,b,a)) end
	function love.graphics.setBackgroundColor(r,g,b,a) sbg(color(r,g,b,a)) end
end


-------------------
-- resize screen --
-------------------
function resizeScreen(width, height)
	local modes = love.graphics.getModes()
	local w, h
	for i=1,#modes do
		w = modes[i].width
		h = modes[i].height
		if w <= width and h <= height then break end
	end

	if w ~= love.graphics.getWidth() and h ~= love.graphics.getHeight() then
		assert(love.graphics.setMode(w, h))
	end

	-- global screen width/height
	WIDTH, HEIGHT = love.graphics.getWidth(), love.graphics.getHeight()
end


         --[[--
      AUDIO MANAGER
         --]]--

do
	-- will hold the currently playing sources
	local sources = {}
	local pairs, ipairs, type = pairs, ipairs, type

	-- check for sources that finished playing and remove them
	function love.audio.update()
		local remove = {}
		for _,s in pairs(sources) do
			if s:isStopped() then
				remove[#remove + 1] = s
			end
		end

		for i,s in ipairs(remove) do
			sources[s] = nil
		end
	end

	-- overwrite love.audio.play to create and register source if needed
	local play = love.audio.play
	function love.audio.play(what, how, loop)
		local src = what
		if type(what) ~= "userdata" or not what:typeOf("Source") then
			src = love.audio.newSource(what, how)
			src:setLooping(loop or false)
		end

		play(src)
		sources[src] = src
		return src
	end

	-- stops a source
	local stop = love.audio.stop
	function love.audio.stop(src)
		if not src then return end
		stop(src)
		sources[src] = nil
	end
end
