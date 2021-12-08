local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 		0 : integer
	session 	1 : integer
}

handshake 		1 {
	response {
		msg 	0 : string
	}
}

connect			2 {
	request {
		side	0 : integer
		hero	1 : integer
		name	2 : string
	}
	response {
		msg 	0 : string
		id		1 : integer
	}
}

clientReady		3 {

}

sendCmd			4 {
	request {
		fn		0 : integer
		type	1 : integer
		vec3	2 : *double
		target	3 : integer
		cnt		4 : integer
		ids		5 : *integer
	}
}

getCmd			5 {
	request {
		fn		0 : integer
	}
}
]]

proto.s2c = sprotoparser.parse [[
.package {
	type 		0 : integer
	session 	1 : integer
}

heartbeat 		1 {}

players			2 {
	request {
		ids		0 : *integer
		names	1 : *string
		heros	2 : *integer
		readys	3 : *boolean
	}
}

sendCmds		3 {
	request {
		fn		0 : integer
		cmdCnt 	1 : integer
		type	2 : *integer
		vec3	3 : *double
		target	4 : *integer
		cnt		5 : *integer
		ids		6 : *integer
	}
}
]]

return proto
