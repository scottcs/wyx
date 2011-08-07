local message = {}

-- check if a given message is valid
local ismessage = function(msg) return message[msg] ~= nil end

-- get a message from the message table
local get = function(msg)
	assert(ismessage(msg), 'invalid component message: %s', msg)
	return message[msg]
end

-- the actual messages
message.IMMOLATE = 'IMMOLATE'

-- the structure of valid message
return setmetatable({ismessage = ismessage},
	{__call = function(_, msg) return get(msg) end})
