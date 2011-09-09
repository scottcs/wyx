local select, type, tostring = select, type, tostring
local pairs, error, setmetatable = pairs, error, setmetatable
local format, io_stderr = string.format, io.stderr
local string_len, string_byte = string.len, string.byte
local sqrt, tonumber = math.sqrt, tonumber


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

local Expression = require 'wyx.component.Expression'

-- verify that all the given objects are of the given type
function verify(theType, ...)
	local isExpr
	if type(theType) == 'expression' then
		isExpr = Expression.isCreatedExpression
	end

	for i=1,select('#', ...) do
		local x = select(i, ...)
		local xType = type(x)
		if isExpr then
			assert(isExpr(x), 'type was %s: %q, expected: expression',
				xType,
				tostring(x))
		else
			assert(xType == theType, 'type was %s: %q, expected: %s',
				xType,
				tostring(x),
				theType)
		end
	end
	return true
end

-- verify that the given object is one of any of the given types
function verifyAny(theObject, ...)
	local theType = type(theObject)
	local is = false

	for i=1,select('#', ...) do
		local x = select(i, ...)

		if 'expression' == x then
			if Expression.isCreatedExpression(theObject) then
				is = true
				break
			end
		end

		if theType == x then
			is = true
			break
		end
	end

	assert(is, 'type was %s: %q, expected any of: %s',
		theType,
		tostring(theObject),
		table.concat({...}, ', '))

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


-------------------
-- common colors --
-------------------
colors = {}
local p100 = 255
local p50 = p100*0.5
local p90, p80, p70, p60 = p100*0.9, p100*0.8, p100*0.7, p100*0.6
local p40, p30, p20, p10 = p100*0.4, p100*0.3, p100*0.2, p100*0.1

colors.WHITE = {p100, p100, p100, p100}
colors.WHITE_A00 = {p100, p100, p100, 0}
colors.BLACK = {0, 0, 0, p100}
colors.BLACK_A70 = {0, 0, 0, p70}
colors.BLACK_A00 = {0, 0, 0, 0}
colors.YELLOW = {p100, p90, 0, p100}
colors.RED = {p100, 0, 0, p100}
colors.LIGHTRED = {p100, p60, p60, p100}
colors.GREEN = {0, p100, 0, p100}
colors.ORANGE = {p100, p100*0.75, p30, p100}
colors.LIGHTORANGE = {p100, p100*0.88, p70, p100}
colors.BROWN = {p50, p40, p20, p100}
colors.BLUE = {p40, p40, p100, p100}
colors.GREY90 = {p90, p90, p90, p100}
colors.GREY80 = {p80, p80, p80, p100}
colors.GREY70 = {p70, p70, p70, p100}
colors.GREY60 = {p60, p60, p60, p100}
colors.GREY50 = {p50, p50, p50, p100}
colors.GREY40 = {p40, p40, p40, p100}
colors.GREY30 = {p30, p30, p30, p100}
colors.GREY20 = {p20, p20, p20, p100}
colors.GREY10 = {p10, p10, p10, p100}
function colors.clone(c) return {c[1], c[2], c[3], c[4]} end


-------------
-- warning --
-------------
function warning(msg, ...)
	msg = msg or 'unknown warning'
	msg = 'Warning: '..msg..'\n'
	io_stderr:write(format(msg, ...))
	if Console then Console:print(colors.YELLOW, msg, ...) end
end


-------------------
-- class helpers --
-------------------
local _mt = {__mode = 'k'}
local _classCache = {}
local _verifyCache = setmetatable({}, _mt)

-- cache class objects (even though Lua does this).
-- this also helps to avoid weird loop errors with require.
function getClass(classPath)
	verify('string', classPath)
	local theClass = _classCache[classPath]

	if nil == theClass then
		local ok,res = pcall(require, classPath)
		if not ok then error(res) end

		theClass = res
		_classCache[classPath] = theClass
	end

	return theClass
end

-- return true if the given object is an instance of the given class
function isClass(class, obj)
	if obj == nil then return false end

	_verifyCache[class] = _verifyCache[class] or setmetatable({}, _mt)
	local is = _verifyCache[class][obj]

	if nil == is then
		local theClass = type(class) == 'string' and getClass(class) or class
		is = type(obj) == 'table'
			and nil ~= obj.is_a
			and type(obj.is_a) == 'function'
			and obj:is_a(theClass)

		_verifyCache[class][obj] = is
		if theClass ~= class then
			_verifyCache[theClass] = _verifyCache[theClass] or setmetatable({}, _mt)
			_verifyCache[theClass][obj] = is
		end
	end

	return is
end

-- assert that the given objects are all instances of the given class
function verifyClass(class, ...)
	for i=1,select('#', ...) do
		local obj = select(i, ...)
		assert(isClass(class, obj),
			'expected %s (was %s, %s)', tostring(class), type(obj), tostring(obj))
	end

	return true
end

-------------------------
-- 2d vector functions --
-------------------------
vec2 = {}
function vec2.len2(x, y) return x*x + y*y end
function vec2.len(x, y) return sqrt(vec2.len2(x, y)) end
function vec2.equal(x1, y1, x2, y2) return x1 == x2 and y1 == y2 end
function vec2.tostring(x, y) return format("(%d,%d)", x,y) end
function vec2.tostringf(x, y) return format("(%.2f,%.2f)", x,y) end


-----------------------------
-- decimal to hex and back --
-----------------------------
function dec2hex(n) return format('%x', n) end
function hex2dec(n) return tonumber(n, 16) end


-----------------------------------
-- string hash (thanks, WoWWiki) --
-----------------------------------
function strhash(s)
	local len = string_len(s)
	local counter = 1

	for i=1,len,3 do
		counter = (counter*8161 % 4294967279) +
		(string_byte(s,i)*16776193) +
		((string_byte(s,i+1) or (len-i+256))*8372226) +
		((string_byte(s,i+2) or (len-i+256))*3932164)
	end

	return (counter % 4294967291)
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


-------------------------
-- render target stack --
-------------------------
local setRenderTarget = love.graphics.setRenderTarget
local Deque = getClass 'wyx.kit.Deque'
local rtStack = Deque()

function pushRenderTarget(target)
	if target then rtStack:push_back(target) end
	setRenderTarget(target)
end

function popRenderTarget()
	rtStack:pop_back()
	local target = rtStack:back()
	setRenderTarget(target)
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
