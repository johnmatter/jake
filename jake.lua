include("jake/lib/snake")
include("jake/lib/rib")
include("jake/lib/apple")

function init()
    game_state = 'menu'
    redraw()
end

function new_game()
    game_state = 'playing'

    local new_ribs = {}
    table.insert(new_ribs, Rib:create{x=7,y=5})
    table.insert(new_ribs, Rib:create{x=6,y=5})
    table.insert(new_ribs, Rib:create{x=5,y=5})
    table.insert(new_ribs, Rib:create{x=4,y=5})
    new_direction = 'E'
    snake = Snake:create{ribs = new_ribs, direction=new_direction}

    -- initial apple
    apple = Apple:create{x=math.random(16), y=math.random(8)}
    -- if the apple would overlap with the snake, keep trying new coordinates
    -- TODO: is this a memory leak?
    -- TODO: include this logic in the Apple "class"
    while snake:check_coordinate_occupied(apple.x, apple.y) do
        apple = Apple:create{x=math.random(16), y=math.random(8)}
    end


    clock.run(play)
end

function play()
    while game_state ~= 'game_over' do
        clock.sync(1/4)

        snake:steer(new_direction)

        snake:step()

        if snake:check_self_collision() then
            game_over()
        end

        if snake:check_apple_collision(apple) then

            -- delete old apple and make a new apple
            apple = Apple:create{x=math.random(16), y=math.random(8)}

            -- if the new apple would overlap with the snake, keep trying new coordinates
            while snake:check_coordinate_occupied(apple.x, apple.y) do
                apple = Apple:create{x=math.random(16), y=math.random(8)}
            end

            -- grow one rib
            snake:grow()

        end

        grid_redraw()
        redraw()
    end
end

g = grid.connect()

function grid_redraw()
    g:all(0)
    snake:draw()
    apple:draw()
    g:refresh()
end

g.key = function(x,y,z)
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

function key(n,z)
    if game_state == 'menu' then
        if n==3 and z==1 then
            new_game()
        end
    end
    if game_state == 'game_over' then
        if n==3 and z==1 then
            new_game()
        end
    end
end

function game_over()
    game_state = 'game_over'
    redraw()
end

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
