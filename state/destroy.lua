
         --[[--
      DESTROY STATE
          ----
   Destroy everything
   that was created by
   the Initialize, NewGame,
   LoadGame and Construct
   states.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.destroy' end}
setmetatable(st, mt)

function st:enter(prevState, nextState, ...)
	InputEvents:clear()
	GameEvents:clear()
	CommandEvents:clear()

	-- reset all game states
	if State.save.destroy then State.save:destroy() end
	rawset(State, 'save', nil)

	if State.play.destroy then State.play:destroy() end
	rawset(State, 'play', nil)

	if State.construct.destroy then State.construct:destroy() end
	rawset(State, 'construct', nil)

	if State.loadgame.destroy then State.loadgame:destroy() end
	rawset(State, 'loadgame', nil)

	if State.initialize.destroy then State.initialize:destroy() end
	rawset(State, 'initialize', nil)

	if nil ~= nextState then
		RunState.switch(State[nextState], ...)
	else
		-- switch to the main menu
		RunState.switch(State.menu)
	end
end

function st:draw()
	if Console then Console:draw() end
end

return st
