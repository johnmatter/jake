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

-- draw rib, with default brightness 5
function Apple:draw(brightness)
    g:led(self.x, self.y, brightness or 7)
end
