Snake = {}
Snake.__index = Snake

-- copy constructor
function Snake:create(s)
    local snake = {}
    setmetatable(snake,Snake)
    snake.ribs = s.ribs
    snake.direction = s.direction
    snake.dx = s.dx
    snake.dy = s.dy
    snake.direction = s.direction
    snake:steer(snake.direction)
    snake.last_tail = snake.ribs[#snake.ribs]
    return snake
end

-- draw the snake
function Snake:draw()
    for n, rib in pairs(self.ribs) do
        rib:draw()
    end
end

-- take a step
function Snake:step()
    -- Keep track of last tail for when the snake grows.
    -- We'll need the position.
    self.last_tail = self.ribs[#self.ribs]

    -- The head rib of the snake should take a step determined by self.direction.
    -- The remainder of the ribs should inherit their position from the rib directly ahead.
    for n=0,(#self.ribs-2) do
        self.ribs[#self.ribs-n].x = self.ribs[#self.ribs-n-1].x
        self.ribs[#self.ribs-n].y = self.ribs[#self.ribs-n-1].y
    end
    self.ribs[1].x = (self.ribs[1].x -1 + self.dx) % 16 + 1
    self.ribs[1].y = (self.ribs[1].y -1 + self.dy) % 8 + 1
end

-- set direction
function Snake:steer(dir)
    self.direction = dir
    if self.direction == 'N' then
        self.dx = 0
        self.dy = -1
    elseif self.direction == 'S' then
        self.dx = 0
        self.dy = 1
    elseif self.direction == 'E' then
        self.dx = 1
        self.dy = 0
    elseif self.direction == 'W' then
        self.dx = -1
        self.dy = 0
    end
end

-- grow
function Snake:grow(new_note)
    new_rib = Rib:create{
        x=self.last_tail.x,
        y=self.last_tail.y,
        note=new_note
    }
    table.insert(self.ribs, new_rib)
end

-- check if snake collided with an object
function Snake:check_collision(x,y)
    if self.ribs[1].x==x and self.ribs[1].y==y then
        return true
    else
        return false
    end
end

-- check if collided with self
function Snake:check_self_collision()
    for n=2,#self.ribs do
        if self:check_collision(self.ribs[n].x,self.ribs[n].y) then
            return true
        end
    end
    return false
end

-- check if collided with apple
function Snake:check_apple_collision(apple)
    return self:check_collision(apple.x, apple.y)
end

-- check if coordinate is occupied by snake
function Snake:check_coordinate_occupied(x,y)
    for n,rib in pairs(self.ribs) do
        if rib.x==x and rib.y==y then
            return true
        end
    end
    return false
end

-- print for debug
function Snake:print()
    for n,rib in pairs(self.ribs) do
        print(string.format('%2d %2d %2d %d', n, rib.x, rib.y, rib.note))
    end
end
