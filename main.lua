--------------------
-- Case statement --
--------------------
function case(x)
   return function (of)
      local what = of[x] or of.default
      if type(what) == "function" then
         return what()
      end
      return what
   end
end

----------------------
-- memoized Loaders --
----------------------
local function Proxy(loader)
   return setmetatable({}, {__index = function(self, k)
      local v = loader(k)
      rawset(self, k, v)
      return v
   end})
end

-- set up a few caches
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

----------------------
-- set up Gamestate --
----------------------
Gamestate = require 'lib.hump.gamestate'

function love.load()
   Gamestate.registerEvents()
   Gamestate.switch(State.intro)
end

function love.quit()
   print('BYE!')
end
