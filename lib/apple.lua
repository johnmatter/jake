Apple = {}
Apple.__index = Apple

-- copy constructor
function Apple:create(a)
    local apple = {}
    setmetatable(apple,Apple)
    apple.x = a.x
    apple.y = a.y
    return apple
end

-- draw apple, with default brightness 7
function Apple:draw(brightness)
    g:led(self.x, self.y, brightness or 7)
end
