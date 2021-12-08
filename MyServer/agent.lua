-- An agent service is attached to a single client
-- and handles all the request of this client.

local skynet = require "skynet"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local WATCHDOG
local host
local send_request
local fd
local playerId = 10

local CMD = {}
local REQUEST = {}

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

function REQUEST:clientReady()
	skynet.call("SIMPLEDB", "lua", "clientready", playerId)
end

function REQUEST:handshake()
	return { msg = "Welcome, I will send heartbeat every 5 sec." }
end

function REQUEST:getCmd()
	print("getting cmd of frame: ", self.fn)
	cnt, cmds = skynet.call("SIMPLEDB", "lua", "getcmd", self.fn)
	local types = {}
	local vec3s = {}
	local targs = {}
	local cnts = {}
	local idss = {}
	local vec3Offset = 0
	local idsOffset = 0
	for i=1,cnt do
		types[i] = cmds[i][1]
		vec3Offset = vec3Offset + 1
		vec3s[vec3Offset] = cmds[i][2][1]
		vec3Offset = vec3Offset + 1
		vec3s[vec3Offset] = cmds[i][2][2]
		vec3Offset = vec3Offset + 1
		vec3s[vec3Offset] = cmds[i][2][3]
		targs[i] = cmds[i][3]
		cnts[i] = cmds[i][4]
		for j=1,cnts[i] do
			idsOffset = idsOffset + 1
			idss[idsOffset] = cmds[i][5][j]
		end
	end
	send_package(send_request("sendCmds", {fn=self.fn, cmdCnt=cnt, type=types, vec3=vec3s, target=targs, cnt=cnts, ids=idss}))
end

function REQUEST:sendCmd()
	print("cmd received: ", self.fn, self.type)
	skynet.call("SIMPLEDB", "lua", "sendcmd", self.fn, self.type, self.vec3, self.target, self.cnt, self.ids)
end

function REQUEST:connect()
	print("Connection request: ", self.side, self.hero, self.name)
	if playerId ~= 10 then
		return {msg="already connected", id=playerId}
	end
	playerId = skynet.call("SIMPLEDB", "lua", "regnewplayer", self.side, self.hero, self.name)
	remsg = "Connection success"
	if playerId < 0 then
		remsg = "No available seat"
	end
	return { msg = remsg,
			id = playerId }
end

local function request(name, args, response)
	print("request name: ", name)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (fd, _, type, ...)
		--assert(fd == client_fd)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		skynet.trace()
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.sendcmds(fn, cmdCnt, type, vec3, target, cnt, ids)
	if playerId < 0 or playerId == 10 then
		return
	end
	print("num of cmds: ", cmdCnt)
	send_package(send_request("sendCmds", {fn=fn, cmdCnt=cmdCnt, type=type, vec3=vec3, target=target, cnt=cnt, ids=ids}))
end

function CMD.sendplayerinfo()
	local ids, names, heros, readys = skynet.call("SIMPLEDB", "lua", "getplayersinfo")
	send_package(send_request("players", { ids = ids, names = names, heros = heros, readys = readys}))
end

function CMD.sendheartbeat()
	send_package(send_request("heartbeat"))
end

function CMD.start(conf)
	fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.call(gate, "lua", "forward", fd)
end


function CMD.disconnect(fd)
	print("disconnect", fd)
	local noplayer = skynet.call("SIMPLEDB", "lua", "playerexit", playerId)
	if noplayer then
		skynet.call(WATCHDOG, "lua", "opengamelob")
	end
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
