function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

local Queue = class("Queue")

function Queue:ctor(capacity)
	self.size = 0
	self.front = -1
	self.back = -1
	self.queue = {}
    self.capacity = capacity
end

function Queue:push(element)
    if self.size < self.capacity then
        if self.size == 0 then
            self.front = 0
        end
        self.back = (self.back + 1) % self.capacity
        self.size = self.size + 1
        self.queue[self.back] = element
    end
end

function Queue:pop()
	if self.size == 0 then
		return nil
	end
	local element = self.queue[self.front]
	self.front = (self.front + 1) % self.capacity
	self.size = self.size - 1
	if self.size == 0 then
		self.front = -1
		self.back = -1
	end
	return element
end

return Queue