
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
	return love.graphics.newImage('image/'..k..'.png')
end)
Sound = Proxy(function(k)
	return love.audio.newSource(
		love.sound.newSoundData('sound/'..k..'.ogg'),
		'static')
end)

--[[ EXAMPLES
-- now you are able to do this without prior loading of resources
love.graphics.draw(Image.player, player.x, player.y, player.angle, 1,1
									 Image.player:getWidth()/2, Image.player:getHeight()/2)

love.graphics.setFont(Font[30])
love.graphics.print("Hello, world!", 10,10)

-- loads states/intro.lua which returns a gamestate.
Gamestate.switch(State.intro)

-- with the "audio manager" (see below)
love.audio.play(Sound.explosion)
--]]


-----------------------------
-- float values for colors --
-----------------------------
do
	local sc = love.graphics.setColor
	local sbg = love.graphics.setBackgroundColor

	local function color(r, g, b, a)
		if type(r) == 'table' then r,g,b,a = r[1],r[2],r[3],r[4] end

		if    r <= 1 and r >= 0
			and g <= 1 and g >= 0
			and b <= 1 and b >= 0
			and (not a or (a <= 1 and a >= 0))
		then
			r, g, b, a = 255*r, 255*g, 255*b, 255*(a or 1)
		end
		return r, g, b, a
	end

	function love.graphics.setColor(r,g,b,a) sc(color(r,g,b,a)) end
	function love.graphics.setBackgroundColor(r,g,b,a) sbg(color(r,g,b,a)) end
end

--[[ EXAMPLES
love.graphics.setColor(0.4, 0.2, 0.2, 1) -- sets to dark greyish red
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
	if nil ~= debug then
		for i=1,select('#', ...) do
			local x = select(i, ...)
			assert(type(x) == t, '%s expected (was %s)', t, type(x))
		end
	end
	return true
end


         --[[--
      AUDIO MANAGER
         --]]--

do
	-- will hold the currently playing sources
	local sources = {}

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
