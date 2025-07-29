-- FIFO Queue
local Queue = {}

function Queue.new()
    local obj = {first = 0, last = -1}
    setmetatable(obj, {__index = Queue})
    return obj
end

function Queue:enqueue(value)
    self.last = self.last + 1
    self[self.last] = value
end

function Queue:dequeue()
    if self.first > self.last then
        return nil  -- queue is empty
    end
    local value = self[self.first]
    self[self.first] = nil  -- allow garbage collection
    self.first = self.first + 1
    return value
end

function Queue:isEmpty()
    return self.first > self.last
end

function Queue:size()
    return self.last - self.first + 1
end

return Queue
