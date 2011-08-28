
         --[[--
    INITIALIZE STATE
          ----
   Initialize resources
   needed for the game.
         --]]--

local st = GameState.new()

function st:init()
	-- entity databases
	HeroDB = getClass('pud.entity.HeroEntityDB')()
	EnemyDB = getClass('pud.entity.EnemyEntityDB')()
	ItemDB = getClass('pud.entity.ItemEntityDB')()
end

function st:enter(prevState, nextState)
	print('initialize')
	if Console then Console:show() print('show') end

	-- load entities
	HeroDB:load()
	EnemyDB:load()
	ItemDB:load()

	GameState.switch(nextState)
end

function st:leave() end

function st:destroy()
	print('initialize destroy')
	-- destroy entity databases
	HeroDB:destroy()
	EnemyDB:destroy()
	ItemDB:destroy()
	HeroDB = nil
	EnemyDB = nil
	ItemDB = nil
end

function st:update(dt) end

function st:draw()
	if Console then Console:draw() end
	print('draw init')
end

function st:keypressed(key, unicode) end

return st
