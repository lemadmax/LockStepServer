-- Player = {id = 0, side = 0, hero = 0, name = ""}
-- function Player:new(o,id,side,hero,name)
-- 	o = o or {}
-- 	setmetatable(o,self)
-- 	self.__index = self
-- 	self.id = id
-- 	self.side = side
-- 	self.hero = hero
-- 	self.name = name
-- 	return o
-- end
-- function Player:printInfo()
-- 	print("name: ", self.name)
-- 	print("id: ", self.id)
-- 	print("side: ", self.side)
-- 	print("hero: ", self.hero)
-- end

-- Frame = {fn = 0, cmdCnt = 0, cmds = {}}
-- function Frame:new(o,fn)
--     o = o or {}
--     setmetatable(o,self)
--     self.__index = self
--     self.fn = fn
--     self.cmdCnt = 0
--     -- self.cmds = {} -- this will change the address of all cmds????
--     return o
-- end
-- function Frame:AddCmd(cmd)
--     self.cmdCnt = self.cmdCnt + 1
--     self.cmds[self.cmdCnt] = cmd
-- end

function NewPlayer(id, side, hero, name)
    return {id=id, side=side, hero=hero, name=name, ready=false}
end

function NewFrame(fn)
    return {fn=fn, cmdCnt=0, cmds={}}
end

function AddCmd(frame, cmd)
    frame.cmdCnt = frame.cmdCnt + 1
    frame.cmds[frame.cmdCnt] = cmd
end