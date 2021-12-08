-- Watchdog service listens to the new connection request
-- and send broadcast message.
-- In our implementation, we consider it a game room.

local skynet = require "skynet"

local maxAgentNumber = 800
local agentCnt = 0

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

local dt = 50
local gameTime = 0
local gameStart = false

function SOCKET.open(fd, addr)
	if agentCnt == maxAgentNumber then
		return
	end
	skynet.error("New client from : " .. addr)
	agent[fd] = skynet.newservice("agent")
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
	agentCnt = agentCnt + 1
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect", fd)
		agentCnt = agentCnt - 1
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function CMD.broadcastpi()
	for k,v in pairs(agent) do
		if v ~= nil then
			skynet.send(v, "lua", "sendplayerinfo")
		end
	end
end

-- Create a new game lob.
function NewGameLob()
	gameStart = false
	skynet.fork(function()
		skynet.call("SIMPLEDB", "lua", "newframe") -- Initialize the first frame.
		local fn = 1
		while true do
			if gameStart == false then -- If the game is not started, we synchronize players information every 50 ms.
				ids, names, heros, readys = skynet.call("SIMPLEDB", "lua", "getplayersinfo")
				local ready = true
				local cnt = 0
				for i=1,8 do
					if ids[i] ~= 0 then
						if readys[i] == false then
							ready = false
						end
						cnt = cnt + 1
					end
				end
				if ready == false and cnt > 0 then
					for k,v in pairs(agent) do
						if v ~= nil then
							skynet.send(v, "lua", "sendplayerinfo")
						end
					end
				elseif cnt > 0 then -- When all player is ready, game is about to start.
					print("game is ready to start")
					gameStart = true
				end
			elseif agentCnt > 0 then -- When game is ready to start.
				-- This should returns nothing because the first frame doesn't handle any commands synchronization.
				cnt, cmds = skynet.call("SIMPLEDB", "lua", "getcmd", fn) 
				local types = {}
				local vec3s = {}
				local targs = {}
				local cnts = {}
				local idss = {}
				for k,v in pairs(agent) do -- Broadcast the first frame.
					if v ~= nil then
						skynet.send(v, "lua", "sendcmds", fn, cnt, types, vec3s, targs, cnts, idss)
					end
				end
				-- Initialize the next frame.
				skynet.call("SIMPLEDB", "lua", "newframe")
				break -- When game is started, quit the game lob.
			end
			skynet.sleep(dt)
		end
	end)
end

function CMD.opengamelob()
	print("Openning a new game lob")
	NewGameLob()
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)

	skynet.fork(function()
		while true do
			for k,v in pairs(agent) do
				if v ~= nil then
					skynet.call(v, "lua", "sendheartbeat")
				end
			end
			skynet.sleep(500)
		end
	end)
	NewGameLob()
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
end)
