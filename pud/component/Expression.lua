local Class = require 'lib.hump.class'
local property = require 'pud.component.property'

local sub, gsub, match = string.sub, string.gsub, string.match

-- Expression
-- class to evaluate component property expressions.
local Expression = Class{name='Expression',
	function(self) end
}

-- destructor
function Expression:destroy() end

-- test mediator for use in testing expression functions after they're built
local testMediator = {
	query = function(self, p)
		p = property(p)
		if nil ~= p then return 1 end
		error('invalid property: '..p)
	end,
}

function Expression.isExpression(expr)
	if type(expr) ~= 'string' then return false end
	local is = false

	-- expressions must begin with '='
	if match(expr, '^[=!]') then
		-- try to make a function out of the expression
		testfunc = Expression.makeExpression(expr)
		if type(testfunc) == 'function' then is = true end
	end

	return is
end

local _funcCache = setmetatable({}, {__mode = 'v'})
function Expression.makeExpression(expression)
	local result = _funcCache[expression]
	local ok, err

	if nil == result then
		-- don't continue if there are bare words not beginning with @ or $
		if not match(expression, '([^@$%w]+)(%a+)') then
			-- remove the beginning '=' or '!'
			local when = sub(expression, 1, 1) == '=' and 'onCreate' or 'onAccess'
			local expr = sub(expression, 2)

			-- substitute $words with property queries
			--  e.g. "$Health" becomes "e:query(property('Health'))"
			expr = gsub(expr, '$(%u[%w_]+)', 'e:query(property(\'%1\'))')

			-- substitute @words with doFunction calls
			--  e.g. "@Explode(12)" becomes "e.doExplode and e:doExplode(12) or nil"
			expr = gsub(expr, '@(%u[%w_]+)(%(.-%))', 'e.do%1 and e:do%1%2 or nil')

			-- substitute dice designations with dice rolls
			--  e.g. "5d10+20" becomes "Random:dice_roll('5d10+20')"
			expr = gsub(expr, '(%d+d%d+[%+%-]?%d*)', 'Random:dice_roll(\'%1\')')

			-- create the function body
			local string = [[
			local e,property
			if select('#', ...) > 0 then
				e = select(1, ...)
				property = require 'pud.component.property'
			end
			return ]]..expr

			-- load the string into a function
			ok, err = pcall(loadstring, string)

			if ok then
				-- test that the function works
				local func = err
				ok,err = pcall(func, testMediator)

				if ok then
					result = {[when] = func}
					_funcCache[expression] = result
				else
					result = nil
				end
			end
		end
	end

	return result, err
end


-- the class
return Expression
