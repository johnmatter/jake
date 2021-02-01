include("jake/lib/snake")
include("jake/lib/rib")
include("jake/lib/apple")

lattice = require("lattice")

-- init
function init()
    -- create a lattice
    my_lattice = lattice:new{
        auto = true,
        meter = 4,
        ppqn = 96
    }

    -- start the lattice
    my_lattice:start()

    game_state = 'menu'
    redraw()
end

-- are you a bad enough dude?
function new_game()
    game_state = 'playing'

    -- make a snake
    -- TODO: randomize starting position
    local new_ribs = {}
    table.insert(new_ribs, Rib:create{x=7,y=5})
    table.insert(new_ribs, Rib:create{x=6,y=5})
    table.insert(new_ribs, Rib:create{x=5,y=5})
    table.insert(new_ribs, Rib:create{x=4,y=5})
    new_direction = 'E'
    snake = Snake:create{ribs = new_ribs, direction=new_direction}

    -- make a movement pattern
    movement_pattern = my_lattice:new_pattern{
        action = function(t) move_snake() end,
        division = 1/4,
        enabled = false
    }

    -- make initial apple
    -- if the apple would overlap with the snake, keep trying new coordinates
    -- TODO: is this a memory leak?
    -- TODO: include this logic in the Apple "class"
    apple = Apple:create{x=math.random(16), y=math.random(8)}
    while snake:check_coordinate_occupied(apple.x, apple.y) do
        apple = Apple:create{x=math.random(16), y=math.random(8)}
    end

    movement_pattern:start()
end

-- game over, pal
function game_over()
    game_state = 'game_over'
    movement_pattern:stop()
    redraw()
end

-- move it along, buddy
function move_snake()
    -- manage movement
    snake:steer(new_direction)
    snake:step()

    -- check if we've lost
    if snake:check_self_collision() then
        game_over()
    end

    -- check if we've eaten an apple (yum)
    if snake:check_apple_collision(apple) then
        -- delete old apple and make a new apple
        -- but, if the new apple would overlap with the snake, keep trying new coordinates
        apple = Apple:create{x=math.random(16), y=math.random(8)}
        while snake:check_coordinate_occupied(apple.x, apple.y) do
            apple = Apple:create{x=math.random(16), y=math.random(8)}
        end

        -- grow a rib
        snake:grow()
    end

    -- redraw everything
    grid_redraw()
    redraw()
end

-- grid interaction
g = grid.connect()

function grid_redraw()
    g:all(0)
    snake:draw()
    apple:draw()
    g:refresh()
end

g.key = function(x,y,z)
    -- if the snake is traveling horizontally, a press above/below
    -- will change the direction to be upward/downward.
    -- if the snake is traveling vertically, a press to the left/right
    -- will change the direction to be leftward/rightward.
    if z == 1 then
        if snake.direction == 'E' or snake.direction == 'W' then
            if y < snake.ribs[1].y then
                new_direction = 'N'
            elseif y > snake.ribs[1].y then
                new_direction = 'S'
            end
        elseif snake.direction == 'S' or snake.direction == 'N' then
            if x < snake.ribs[1].x then
                new_direction = 'W'
            elseif x > snake.ribs[1].x then
                new_direction = 'E'
            end
        end
    end
end

-- key input
function key(n,z)
    if game_state == 'menu' then
        if n==3 and z==1 then
            new_game()
        end
    end
    if game_state == 'playing' then
        if n==3 and z==1 then
            movement_pattern:toggle()
        end
    end
    if game_state == 'game_over' then
        if n==3 and z==1 then
            new_game()
        end
    end
end

-- enc input
function enc(n,delta)
end

-- screen redraw
-- TODO: the screen should probably display sequencer parameters
-- TODO: high score would be cute too
function redraw()
    screen.clear()

    if game_state == 'menu' then
        screen.move(10, 20)
        screen.level(5)
        screen.font_face(13)
        screen.font_size(24)
        screen.text('main menu')

        screen.move(15, 35)
        screen.level(10)
        screen.font_face(1)
        screen.font_size(8)
        screen.text('press k3 for a new game')
    end

    if game_state == 'playing' then
        screen.move(10, 20)
        screen.level(5)
        screen.font_face(13)
        screen.font_size(24)
        screen.text('snake!')

        screen.move(15, 35)
        screen.level(10)
        screen.font_face(1)
        screen.font_size(8)
        screen.text('snake!')

        screen.move(20, 45)
        screen.level(10)
        screen.font_face(1)
        screen.font_size(8)
        screen.text("you're playing snake!")
    end

    if game_state == 'game_over' then
        screen.move(10, 20)
        screen.level(5)
        screen.font_face(13)
        screen.font_size(24)
        screen.text('game over')

        screen.move(15, 35)
        screen.level(10)
        screen.font_face(1)
        screen.font_size(8)
        screen.text('you are no longer a snake')

        screen.move(20, 45)
        screen.level(10)
        screen.font_face(1)
        screen.font_size(8)
        screen.text('press k3 for a new game')
    end
    screen.update()
end
