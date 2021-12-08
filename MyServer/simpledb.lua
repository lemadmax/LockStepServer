-- Simpledb works as the database of a single game.
-- Player informations and game frames are stored and accessed here.

local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
require "utils"

local players = {}

local command = {}

local availableIDs = { 0, 0, 0, 0, 0, 0, 0, 0 }

local keyFrameNum = 0
local keyFrames = {}

function command.CLIENTREADY(id)
	players[id].ready = true
end

function command.GETCMD(fn)
	-- When a client is trying to get the current frame,
	-- the server moves to the next frame.
	if fn == keyFrameNum then
		keyFrameNum = keyFrameNum + 1
		keyFrames[keyFrameNum] = NewFrame(keyFrameNum)
	end
	for i=1,keyFrames[fn].cmdCnt do
		print("cmd: ", keyFrames[fn].cmds[i][2][1], keyFrames[fn].cmds[i][2][2], keyFrames[fn].cmds[i][2][3])
	end
	return keyFrames[fn].cmdCnt, keyFrames[fn].cmds
end

function command.NEWFRAME()
	keyFrameNum = keyFrameNum + 1
	keyFrames[keyFrameNum] = NewFrame(keyFrameNum)
end

function command.SENDCMD(fn, type, vec3, target, cnt, ids)
	if keyFrames[keyFrameNum] == nil then
		keyFrames[keyFrameNum] = NewFrame(keyFrameNum)
	end
	AddCmd(keyFrames[keyFrameNum], {type, vec3, target, cnt, ids})
end

function command.GETPLAYERSINFO()
	local ids = {}
	local names = {}
	local heros = {}
	local readys = {}
	for i=1,8 do
		ids[i] = availableIDs[i]
		if ids[i] ~= 0 then
			print("player: ", i, players[i].name, players[i].hero)
			names[i] = players[i].name
			heros[i] = players[i].hero
			readys[i] = players[i].ready
		else
			names[i] = ""
			heros[i] = -1
			readys[i] = false
		end
	end
	return ids, names, heros, readys
end

function command.REGNEWPLAYER(side, hero, name)
	res = -1
	if side == 1 then
		for i=1,4 do
			if availableIDs[i] == 0 then
				res = i
				availableIDs[i] = 1
				break
			end
		end
	elseif side == 2 then
		for i=5,8 do
			if availableIDs[i] == 0 then
				res = i
				availableIDs[i] = 1
				break
			end
		end
	end
	if res ~= -1 then
		players[res] = NewPlayer(res, side, hero, name)
	end
	return res
end

function command.PLAYEREXIT(id)
	availableIDs[id] = 0
	local noPlayer = true
	for i=1,8 do
		if availableIDs[i] ~= 0 then
			noPlayer = false
		end
	end
	if noPlayer then
		print("all player exited")
		keyFrameNum = 0
		keyFrames = {}
		return true
	end
	return false
end

function command.DEAD(id)
	playerStatus[id] = "dead"
end


skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		cmd = cmd:upper()
		if cmd == "PING" then
			assert(session == 0)
			local str = (...)
			if #str > 20 then
				str = str:sub(1,20) .. "...(" .. #str .. ")"
			end
			skynet.error(string.format("%s ping %s", skynet.address(address), str))
			return
		end
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
--	skynet.traceproto("lua", false)	-- true off tracelog
	skynet.register "SIMPLEDB"
end)