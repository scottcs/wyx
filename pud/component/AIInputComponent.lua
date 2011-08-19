local Class = require 'lib.hump.class'
local InputComponent = getClass 'pud.component.InputComponent'
local message = require 'pud.component.message'
local property = require 'pud.component.property'

-- tables to translate direction strings to coordinates
local _x = {l=-1, r=1, u=0, d=0, ul=-1, ur=1, dl=-1, dr=1}
local _y = {l=0, r=0, u=-1, d=1, ul=-1, ur=-1, dl=1, dr=1}

-- AIInputComponent
--
local AIInputComponent = Class{name='AIInputComponent',
	inherits=InputComponent,
	function(self, properties)
		InputComponent.construct(self, properties)
		self:_addMessages(
			'TIME_TICK',
			'COLLIDE_BLOCKED',
			'COLLIDE_NONE')
		self._directions = {}
		self:_allowAllDirections()
	end
}

-- destructor
function AIInputComponent:destroy()
	for dir in pairs(self._directions) do self._directions[dir] = nil end
	self._directions = nil
	InputComponent.destroy(self)
end

-- figure out what to do on next tick
function AIInputComponent:_determineNextAction(ap)
	local moveCost = self._mediator:query(property('MoveCost'))
	local allowed = self:_getAllowedDirections()
	if allowed then
		while ap > moveCost do
			local dir = allowed[Random(#allowed)]
			local x, y = _x[dir], _y[dir]

			self:move(x, y)
			ap = ap - moveCost
		end
	end
end

-- disallow attempting to move in the given direction
function AIInputComponent:_denyDirection(node, nodeX, nodeY)
	local pos = self._mediator:query(property('Position'))
	local x, y = nodeX-pos[1], nodeY-pos[2]
	local dir = ''

	if y > 0 then dir = dir..'d'
	elseif y < 0 then dir = dir..'u'
	end

	if x > 0 then dir = dir..'r'
	elseif x < 0 then dir = dir..'l'
	end

	if self._directions[dir] ~= nil then self._directions[dir] = false end
end

-- get currently allowed directions
function AIInputComponent:_getAllowedDirections()
	local allowed = {}
	local count = 0

	for dir in pairs(self._directions) do
		if self._directions[dir] then
			count = count + 1
			allowed[count] = dir
		end
	end

	return count > 0 and allowed or nil
end

-- allow traveling in all directions
function AIInputComponent:_allowAllDirections()
	self._directions.l = true
	self._directions.r = true
	self._directions.u = true
	self._directions.d = true
	self._directions.ul = true
	self._directions.ur = true
	self._directions.dl = true
	self._directions.dr = true
end

function AIInputComponent:receive(msg, ...)
	if msg == message('TIME_TICK') then
		self:_determineNextAction(...)
	elseif msg == message('COLLIDE_BLOCKED') then
		self:_denyDirection(...)
	elseif msg == message('COLLIDE_NONE') then
		self:_allowAllDirections(...)
	else
		InputComponent.receive(self, msg, ...)
	end
end


-- the class
return AIInputComponent
