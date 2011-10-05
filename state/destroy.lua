
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
	for _,s in ipairs({'save', 'playmenu', 'play', 'construct', 'loadgame',
		'loadmenu', 'createchar', 'initialize'})
	do
		local state = State[s]
		if state then
			if state.destroy and state.initHasRun then
				state:destroy()
			end
			rawset(State, s, nil)
		else
			print('bad state: %q', tostring(s))
		end
	end

	if nil ~= nextState then
		RunState.switch(State[nextState], ...)
	else
		-- switch to the main menu
		RunState.switch(State.initialize, 'menu')
	end
end

function st:draw() end

return st
