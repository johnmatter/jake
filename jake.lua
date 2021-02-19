include("jake/lib/snake")
include("jake/lib/rib")
include("jake/lib/apple")

-- clock
lattice = require("lattice")

-- music
music = require("musicutil")

-- engine
local MollyThePoly = require("molly_the_poly/lib/molly_the_poly_engine")
engine.name = "MollyThePoly"

-- output options
output_names = {"audio", "midi", "audio + midi", "crow out 1+2", "crow ii JF"}

active_notes = {}
midi_out_device = 1
midi_out_channel = 1

-- init
function init()

    -- scale/root params infrastructure
    scale_names = {}
    for n=1,#music.SCALES do
        table.insert(scale_names, music.SCALES[n].name)
    end

    note_names = {}
    for n=0,100 do
        table.insert(note_names, music.note_num_to_name(n,true))
    end

    root_note = 48
    scale_index = 11
    scale_name = scale_names[scale_index]
    scale = music.generate_scale_of_length(root_note, scale_name, 24)

    -- params
    -- output
    params:add_option("output", "output", output_names, 5)
    params:set_action("output", set_output)

    params:add{
            type = "number",
            id = "midi_out_device",
            name = "midi out device",
            min = 1, max = 4, default = 1,
            action = function(value)
                midi_out_device = midi.connect(value)
            end
    }

    params:add{
            type = "number",
            id = "midi_out_channel",
            name = "midi out channel",
            min = 1, max = 16, default = 1,
            action = function(value)
                all_notes_off()
                midi_out_channel = value
            end
    }


    -- scale and root
    params:add_separator()
    params:add_option("scale", "scale", scale_names, 11)
    params:set_action("scale", set_scale)
    -- TODO: figure out why this displays the note off by one
    params:add_option("root_note", "root note", note_names, 48)
    params:set_action("root_note", set_root_note)

    -- engine
    params:add_separator()
    MollyThePoly.add_params()

    game_state = 'menu'

    -- create a lattice
    my_lattice = lattice:new{
        auto = true,
        meter = 4,
        ppqn = 96
    }

    -- start the lattice
    my_lattice:start()

    -- redraw screen
    redraw()
end

-- are you a bad enough dude?
function new_game()
    game_state = 'playing'

    all_notes_off()

    -- make a snake
    -- TODO: randomize starting position
    local new_ribs = {}
    table.insert(new_ribs, Rib:create{x=7,y=5,note=math.random(10),brightness=6})
    table.insert(new_ribs, Rib:create{x=6,y=5,note=math.random(10),brightness=3})
    table.insert(new_ribs, Rib:create{x=5,y=5,note=math.random(10),brightness=3})
    table.insert(new_ribs, Rib:create{x=4,y=5,note=math.random(10),brightness=3})
    new_direction = 'E'
    snake = Snake:create{ribs = new_ribs, direction=new_direction}

    -- make a movement pattern
    movement_pattern = my_lattice:new_pattern{
        action = function(t) move_snake() end,
        division = 1/8
    }

    -- make a sequencer pattern
    last_note = nil
    sequencer_pattern = my_lattice:new_pattern{
        action = function(t) advance_sequence() end,
        division = 1/16
    }

    -- make initial apple
    -- if the apple would overlap with the snake, keep trying new coordinates
    -- TODO: is this a memory leak?
    -- TODO: include this logic in the Apple "class"
    apple = Apple:create{x=math.random(16), y=math.random(8)}
    while snake:check_coordinate_occupied(apple.x, apple.y) do
        apple = Apple:create{x=math.random(16), y=math.random(8)}
    end

    movement_pattern.enabled = true
    grid_redraw()
    redraw()
end

-- game over, pal
function game_over()
    game_state = 'game_over'
    note_off(last_note)
    movement_pattern:stop()
    sequencer_pattern:destroy()
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
        -- calculate note from apple position
        -- TODO: calculate notes some other way
        apple_note = apple.x + apple.y - 1

        -- delete old apple and make a new apple
        -- but, if the new apple would overlap with the snake, keep trying new coordinates
        apple = Apple:create{x=math.random(16), y=math.random(8)}
        while snake:check_coordinate_occupied(apple.x, apple.y) do
            apple = Apple:create{x=math.random(16), y=math.random(8)}
        end

        -- grow a rib
        snake:grow(apple_note)
    end

    -- redraw everything
    grid_redraw()
    redraw()
end

-- output options
function set_output(output)
    all_notes_off()
    if output == 4 then
        -- TODO: change to ar
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
    elseif output == 5 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
    end
end

-- sequence and music stuff
function set_scale(new_scale_name)
    scale = music.generate_scale_of_length(root_note, new_scale_name, 24)
end

function set_root_note(new_root_note)
    root_note = new_root_note
    scale = music.generate_scale_of_length(new_root_note, scale_name, 24)
end

function advance_sequence()
    -- get next note based on scale and step
    local this_note = scale[snake.ribs[snake.active_step].note]

    -- turn off last note
    -- TODO: gate length?
    if last_note then
        note_off(last_note)
    end

    -- play note
    note_on(this_note)
    last_note = this_note

    -- advance counter
    snake.active_step = (snake.active_step) % (#snake.ribs) + 1

    -- TODO: redraw snake on grid to show active step?
end

-- turn on note for selected output
function note_on(note)
    -- audio
    if params:get("output") == 1 then
        local freq = music.note_num_to_freq(note)
        engine.noteOn(note, freq, 80)
        table.insert(active_notes, note)
    -- MIDI
    elseif params:get("output") == 2 then
        midi_out_device:note_on(note, 80, midi_out_channel)
        table.insert(active_notes, note)
    -- audio/MIDI
    elseif params:get("output") == 3 then
        local freq = music.note_num_to_freq(note)
        engine.noteOn(note, freq, 80)
        midi_out_device:note_on(note, 80, midi_out_channel)
        table.insert(active_notes, note)
    -- crow
    elseif params:get("output") == 4 then
        crow.output[1].volts = (note)/12
        crow.output[2].execute()
    -- jf
    elseif params:get("output") == 5 then
        crow.ii.jf.play_note((note-60)/12,5)
    end
end

-- turn off note for MIDI and engine
function note_off(note)
    -- if params:get("output") == 1 then
    --     engine.noteOff(note)
    -- elseif params:get("output") == 2 then
    --     midi_out_device:note_off(note, nil, midi_out_channel)
    -- elseif params:get("output") == 3 then
        engine.noteOff(note)
        midi_out_device:note_off(note, nil, midi_out_channel)
    -- end
end

-- turn off all notes for MIDI and engine
function all_notes_off()
    for n,note in pairs(active_notes) do
        note_off(note)
    end
    active_notes = {}
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
    if n==3 and z==1 then
        if game_state == 'menu' then
            new_game()
            movement_pattern:toggle()
        end
        if game_state == 'playing' then
            movement_pattern:toggle()
        end
        if game_state == 'game_over' then
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
