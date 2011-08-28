
         --[[--
      DESTROY STATE
          ----
   Destroy everything
   that was created by
   the Initialize, NewGame,
   LoadGame and Construct
   states.
         --]]--

local st = GameState.new()

function st:enter(prevState)
	print('destroy')
	-- reset all game states
	--[[
	if State.save.destroy then State.save:destroy() end
	State.save = nil
	]]--

	if State.play.destroy then State.play:destroy() end
	State.play = nil

	if State.construct.destroy then State.construct:destroy() end
	State.construct = nil

	--[[
	if State.loadgame.destroy then State.loadgame:destroy() end
	State.loadgame = nil
	]]--

	if State.newgame.destroy then State.newgame:destroy() end
	State.newgame = nil

	if State.initialize.destroy then State.initialize:destroy() end
	State.initialize = nil

	-- switch to the main menu
	GameState.switch(State.menu)
end

return st
