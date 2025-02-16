-----------------------------
-- Constants and Configuration
-----------------------------
Config = {
    board = {
        width = 10,
        height = 20,
        cell_size = 30,
        fall_speed = 0.4,
        colors = {
            background = {0.1, 0.1, 0.1},
            board = {0.2, 0.2, 0.2},
            border = {0, 0, 0},
            grid = {0.1, 0.1, 0.1}
        }
    },
    pieces = {
        {
            name = "I",
            shape = {{0,0}, {0,1}, {0,2}, {0,3}},
            color = {0.0, 1.0, 1.0},     -- Cyan
            outline = {0.0, 0.5, 0.5}    -- Darker Cyan
        },
        {
            name = "J",
            shape = {{0,0}, {0,1}, {0,2}, {-1,2}},
            color = {0.0, 0.0, 1.0},     -- Blue
            outline = {0.0, 0.0, 0.5}    -- Darker Blue
        },
        {
            name = "L",
            shape = {{0,0}, {0,1}, {0,2}, {1,2}},
            color = {1.0, 0.5, 0.0},     -- Orange
            outline = {0.5, 0.25, 0.0}   -- Darker Orange
        },
        {
            name = "O",
            shape = {{0,0}, {1,0}, {0,1}, {1,1}},
            color = {1.0, 1.0, 0.0},     -- Yellow
            outline = {0.5, 0.5, 0.0}    -- Darker Yellow
        },
        {
            name = "S",
            shape = {{0,1}, {1,1}, {1,0}, {2,0}},
            color = {0.0, 1.0, 0.0},     -- Green
            outline = {0.0, 0.5, 0.0}    -- Darker Green
        },
        {
            name = "T",
            shape = {{0,0}, {1,0}, {2,0}, {1,1}},
            color = {0.5, 0.0, 1.0},      -- Purple
            outline = {0.25, 0.0, 0.5}   -- Darker Purple
        },
        {
            name = "Z",
            shape = {{0,0}, {1,0}, {1,1}, {2,1}},
            color = {1.0, 0.0, 0.0},      -- Red
            outline = {0.5, 0.0, 0.0}    -- Darker Red
        }
    },
    menu = {
        options = {"Start New Game", "Load Game", "Quit"},
        spacing = 40,
        start_y = 150,
        background = {0.2, 0.2, 0.4}
    },
    animations = {
        clear_duration = 0.5, -- Duration of line clear animation
        clear_scale = 1.5     -- Scale factor for clear animation
    }
}

------------------
-- Game State
------------------
local State = {
    board = {},
    current_piece = nil,
    next_piece = nil,
    game_state = "menu",
    selected_menu = 1,
    block_count = 0,
    player_name = "",
    input_active = true,
    fall_timer = 0,
    load_files = {},
    selected_save = 1,
    clearing_lines = {}, -- Table to store lines being cleared
    clear_animation_timer = 0
}

------------------
-- Core Game Logic
------------------
local function create_board()
    local board = {}
    for y = 1, Config.board.height do
        board[y] = {}
        for x = 1, Config.board.width do
            board[y][x] = 0
        end
    end
    return board
end

local function new_random_piece()
    local piece = Config.pieces[math.random(#Config.pieces)]
    return {
        shape = piece.shape,
        color = piece.color,
        x = math.floor(Config.board.width / 2),
        y = 1
    }
end

local function check_collision(x, y, shape)
    for _, cell in ipairs(shape) do
        local px = x + cell[1]
        local py = y + cell[2]
        if px < 1 or px > Config.board.width 
           or py > Config.board.height 
           or (py > 0 and State.board[py][px] ~= 0) then
            return true
        end
    end
    return false
end

local function rotate_piece(shape, clockwise)
    local new_shape = {}
    local pivot_x, pivot_y = shape[1][1], shape[1][2]
    
    for _, cell in ipairs(shape) do
        local x, y = cell[1], cell[2]
        if clockwise then
            table.insert(new_shape, {pivot_x - (y - pivot_y), pivot_y + (x - pivot_x)})
        else
            table.insert(new_shape, {pivot_x + (y - pivot_y), pivot_y - (x - pivot_x)})
        end
    end
    return new_shape
end

local function freeze_piece(piece)
    for _, cell in ipairs(piece.shape) do
        local x = piece.x + cell[1]
        local y = piece.y + cell[2]
        if y > 0 then  -- Prevent freezing above the board
            State.board[y][x] = piece.color
        end
    end
end

local function finish_clearing_lines()
    print("finish_clearing_lines() called. Lines to clear:", table.concat(State.clearing_lines, ", "))

    -- Sort in descending order so removing doesn't affect indices
    table.sort(State.clearing_lines, function(a,b) return a > b end)

    for _, y in ipairs(State.clearing_lines) do
        print("Removing line from board at y =", y)

        -- Shift lines down manually:
        for row = y, 2, -1 do -- Start from y, go up to the second row
            State.board[row] = State.board[row - 1] -- Copy the row above
        end

        -- Create a new empty line at the top with proper values
        State.board[1] = {}
        for x = 1, Config.board.width do
            State.board[1][x] = 0 -- Set each cell to 0 (empty)
        end
    end

    print("State.board after finish_clearing_lines():")
    for y, row in ipairs(State.board) do
        local row_string = ""
        for x, cell in ipairs(row) do
            if type(cell) == "table" then
                row_string = row_string .. "{" .. table.concat(cell, ",") .. "}, "
            else
                row_string = row_string .. tostring(cell) .. ", "
            end
        end
        print(y, row_string)
    end

    State.clearing_lines = {}
end

------------------
-- Game Operations
------------------
local function reset_game()
    State.board = create_board()
    State.block_count = 0
    State.current_piece = new_random_piece()
    State.next_piece = new_random_piece()
end

local function check_lines()
    local lines_to_clear = {}  -- Store the lines to clear

    for y = 1, Config.board.height do
        local full = true
        for x = 1, Config.board.width do
            if State.board[y][x] == 0 then
                full = false
                break
            end
        end
        if full then
            table.insert(lines_to_clear, y)  -- Add line index to the list
        end
    end

    if #lines_to_clear > 0 then  -- If any lines are to be cleared...
        State.clearing_lines = lines_to_clear  -- Start the clearing animation
        State.clear_animation_timer = 0
        return true -- Return true to indicate that lines are going to be cleared
    end

    return false -- Return false to indicate that no lines are going to be cleared
end

------------------
-- Drawing System
------------------
local function draw_cell(x, y, color)
    local cs = Config.board.cell_size
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x * cs, y * cs, cs, cs)
    love.graphics.setColor(Config.board.colors.border)
    love.graphics.rectangle("line", x * cs, y * cs, cs, cs)
end

local function draw_clearing_lines()
    local cs = Config.board.cell_size
    local scale = 1 + (State.clear_animation_timer / Config.animations.clear_duration) * (Config.animations.clear_scale - 1)

    -- Calculate the center offset for the board
    local board_center_x = love.graphics.getWidth() / 2
    local board_offset_x = board_center_x - (Config.board.width * cs) / 2

    for _, y in ipairs(State.clearing_lines) do
        love.graphics.push()

        -- Translate to the center of the board for the current line
        love.graphics.translate(board_offset_x, (y - 1) * cs)

        -- Apply scaling at the center
        love.graphics.translate(Config.board.width * cs / 2, cs / 2)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-Config.board.width * cs / 2, -cs / 2)

        -- Draw the rectangle for the line
        love.graphics.setColor(1, 1, 1, 1 - (State.clear_animation_timer / Config.animations.clear_duration))
        love.graphics.rectangle("fill", 0, 0, Config.board.width * cs, cs)

        love.graphics.pop()
    end

end

local function draw_board()
    local board_x = (love.graphics.getWidth() - (Config.board.width * Config.board.cell_size)) / 2
    love.graphics.translate(board_x, 0)
    
    -- Draw board background
    love.graphics.setColor(Config.board.colors.board)
    love.graphics.rectangle("fill", 0, 0, 
        Config.board.width * Config.board.cell_size, 
        Config.board.height * Config.board.cell_size)

    -- Draw cells
    for y = 1, Config.board.height do
        for x = 1, Config.board.width do
            if State.board[y][x] ~= 0 then
                draw_cell(x - 1, y - 1, State.board[y][x])
            end
        end
    end

    -- Draw grid lines
    love.graphics.setColor(Config.board.colors.grid)
    for y = 1, Config.board.height do
        for x = 1, Config.board.width do
            love.graphics.rectangle("line", (x - 1) * Config.board.cell_size, (y - 1) * Config.board.cell_size, Config.board.cell_size, Config.board.cell_size)
        end
    end

    love.graphics.origin()
end

local function draw_piece(piece, offset_x, offset_y)
    if not piece then return end
    for _, cell in ipairs(piece.shape) do
        local x = (piece.x + cell[1] - 1) * Config.board.cell_size + offset_x
        local y = (piece.y + cell[2] - 1) * Config.board.cell_size + offset_y
        draw_cell(x / Config.board.cell_size, y / Config.board.cell_size, piece.color)
    end
end

local function draw_ui()
    local board_width = Config.board.width * Config.board.cell_size
    local board_center_x = love.graphics.getWidth() / 2
    local board_offset_x = board_center_x - board_width / 2
    
    -- Increase margin to 40 pixels from the board
    local right_ui_x = board_offset_x + board_width + 40 

    -- Calculate vertical center of the board
    local board_height = Config.board.height * Config.board.cell_size
    local board_center_y = board_height / 2

    -- Calculate estimated total height of UI elements
    local ui_height = 20 + (4 * Config.board.cell_size + 10) + 20 + 20

    -- Calculate starting y for UI elements to center vertically
    local ui_start_y = board_center_y - ui_height / 2

    -- Next piece preview
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Next:", right_ui_x, ui_start_y)
    if State.next_piece then
        local cell_size = Config.board.cell_size
        for _, cell in ipairs(State.next_piece.shape) do
            local x = right_ui_x + (cell[1] + 1) * cell_size
            local y = ui_start_y + 30 + (cell[2] + 1) * cell_size
            love.graphics.setColor(State.next_piece.color)
            love.graphics.rectangle("fill", x, y, cell_size, cell_size)
            love.graphics.setColor(Config.board.colors.border)
            love.graphics.rectangle("line", x, y, cell_size, cell_size)
        end
    end

    -- Player name (positioned below the "Next" piece preview)
    if State.player_name ~= "" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Player: " .. State.player_name, right_ui_x, ui_start_y + (4 * Config.board.cell_size + 10) + 30)
    end

    -- Block count (positioned below the player's name)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Blocks: " .. State.block_count, right_ui_x, ui_start_y + (4 * Config.board.cell_size + 10) + 70)
end

local function draw_menu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("TETRIS", 0, 100, love.graphics.getWidth(), "center")

    for i, option in ipairs(Config.menu.options) do
        local color = (i == State.selected_menu) and {1, 0, 0} or {1, 1, 1}
        love.graphics.setColor(color)
        
        local y = Config.menu.start_y + (i - 1) * Config.menu.spacing
        love.graphics.rectangle("line", 
            love.graphics.getWidth()/2 - 75, y, 150, 30)
        love.graphics.printf(option, 0, y + 5, love.graphics.getWidth(), "center")
    end
end

local function draw_load_menu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Load Game", 0, 80, love.graphics.getWidth(), "center")

    if #State.load_files == 0 then
        love.graphics.printf("No save files found", 0, 150, love.graphics.getWidth(), "center")
    else
        for i, file in ipairs(State.load_files) do
            local color = (i == State.selected_save) and {1, 0, 0} or {1, 1, 1}
            love.graphics.setColor(color)
            love.graphics.printf(file, 0, 150 + (i-1)*30, love.graphics.getWidth(), "center")
        end
    end
end

------------------
-- Save/Load System
------------------
local function serialize_table(tbl)
    local result = "{"
    
    -- Check if it's an array-like table
    if #tbl > 0 then
        for i, v in ipairs(tbl) do
            local value
            if type(v) == "table" then
                value = serialize_table(v)
            elseif type(v) == "string" then
                value = string.format("%q", v)
            else
                value = tostring(v)
            end
            result = result .. value .. ", "
        end
    else
        -- Handle key-value tables
        for k, v in pairs(tbl) do
            local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%s]", k)
            local value = type(v) == "table" and serialize_table(v) 
                        or type(v) == "string" and string.format("%q", v) 
                        or tostring(v)
            result = result .. string.format("%s = %s, ", key, value)
        end
    end
    
    return result:gsub(", $", "") .. "}"
end

local function save_game()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "save_" .. timestamp .. ".txt"
    local save_dir = "saves"

    if not love.filesystem.getInfo(save_dir) then
        love.filesystem.createDirectory(save_dir)
    end

    local save_data = {
        board = State.board,
        current_piece = State.current_piece,
        next_piece = State.next_piece,
        game_state = State.game_state,
        block_count = State.block_count,
        player_name = State.player_name
    }

    local content = string.format([[
return {
    board = %s,
    current_piece = %s,
    next_piece = %s,
    game_state = "%s",
    block_count = %d,
    player_name = "%s"
}
    ]],
    serialize_table(State.board),
    serialize_table(State.current_piece),
    serialize_table(State.next_piece),
    State.game_state,
    State.block_count,
    State.player_name
    )

    local success, err = love.filesystem.write(save_dir .. "/" .. filename, content)
    if success then
        print("Game saved to " .. filename)
    else
        print("Save error:", err)
    end
end

local function load_game(filename)
    local save_dir = "saves"
    local filepath = save_dir .. "/" .. filename
    
    -- Read and validate file
    local content, err = love.filesystem.read(filepath)
    if not content then
        print("Load error:", err)
        return
    end

    -- Parse saved data
    local chunk, err = loadstring(content)
    if not chunk then
        print("Load error:", err)
        return
    end

    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
        print("Load error: Invalid save file")
        return
    end

    -- Full state reset before loading
    reset_game()

    -- Load board state with validation
    if type(data.board) == "table" then
        for y = 1, math.min(#data.board, Config.board.height) do
            if type(data.board[y]) == "table" then
                for x = 1, math.min(#data.board[y], Config.board.width) do
                    if type(data.board[y][x]) == "table" then  -- Color cell
                        State.board[y][x] = {
                            math.min(1, math.max(0, data.board[y][x][1] or 0)),
                            math.min(1, math.max(0, data.board[y][x][2] or 0)),
                            math.min(1, math.max(0, data.board[y][x][3] or 0))
                        }
                    else  -- Empty cell
                        State.board[y][x] = 0
                    end
                end
            end
        end
    end

    -- Load current piece with validation
    if type(data.current_piece) == "table" then
        State.current_piece = {
            x = data.current_piece.x or math.floor(Config.board.width/2),
            y = data.current_piece.y or 1,
            shape = data.current_piece.shape or new_random_piece().shape,
            color = data.current_piece.color or {1, 1, 1}
        }
    end

    -- Load next piece with validation
    if type(data.next_piece) == "table" then
        State.next_piece = {
            x = data.next_piece.x or math.floor(Config.board.width/2),
            y = data.next_piece.y or 1,
            shape = data.next_piece.shape or new_random_piece().shape,
            color = data.next_piece.color or {1, 1, 1}
        }
    end

    -- Load other game state
    State.game_state = data.game_state or "playing"
    State.block_count = type(data.block_count) == "number" and data.block_count or 0
    State.player_name = type(data.player_name) == "string" and data.player_name or ""

    print("Successfully loaded game from " .. filename)
end

------------------
-- Input Handling
------------------
local function handle_menu_input(key)
    if key == "up" then
        State.selected_menu = math.max(1, State.selected_menu - 1)
    elseif key == "down" then
        State.selected_menu = math.min(#Config.menu.options, State.selected_menu + 1)
    elseif key == "return" then
        if State.selected_menu == 1 then
            reset_game()
            State.game_state = "playing"
        elseif State.selected_menu == 2 then
            State.game_state = "load_menu"
            State.load_files = love.filesystem.getDirectoryItems("saves")
        elseif State.selected_menu == 3 then
            love.event.quit()
        end
    end
end

local function handle_load_menu_input(key)
    if key == "up" then
        State.selected_save = math.max(1, State.selected_save - 1)
    elseif key == "down" then
        State.selected_save = math.min(#State.load_files, State.selected_save + 1)
    elseif key == "return" then
        if #State.load_files > 0 then
            load_game(State.load_files[State.selected_save])
            State.game_state = "playing"
        end
    elseif key == "escape" then
        State.game_state = "menu"
    end
end

local function handle_game_input(key)
    if key == "escape" then
        State.game_state = "menu"
    elseif key == "s" then
        save_game()
    elseif State.current_piece then
        if key == "left" then
            if not check_collision(State.current_piece.x - 1, State.current_piece.y, State.current_piece.shape) then
                State.current_piece.x = State.current_piece.x - 1
                Sounds.move:play()  -- Play move sound
            end
        elseif key == "right" then
            if not check_collision(State.current_piece.x + 1, State.current_piece.y, State.current_piece.shape) then
                State.current_piece.x = State.current_piece.x + 1
                Sounds.move:play()  -- Play move sound
            end
        elseif key == "down" then
            Sounds.drop:play()  -- Play drop sound
            while not check_collision(State.current_piece.x, State.current_piece.y + 1, State.current_piece.shape) do
                State.current_piece.y = State.current_piece.y + 1
            end
            freeze_piece(State.current_piece)
            check_lines()
            State.block_count = State.block_count + 1
            State.current_piece = State.next_piece
            State.next_piece = new_random_piece()
        elseif key == "z" then
            local rotated = rotate_piece(State.current_piece.shape, false)
            if not check_collision(State.current_piece.x, State.current_piece.y, rotated) then
                State.current_piece.shape = rotated
                Sounds.move:play()  -- Play move sound
            end
        elseif key == "x" then
            local rotated = rotate_piece(State.current_piece.shape, true)
            if not check_collision(State.current_piece.x, State.current_piece.y, rotated) then
                State.current_piece.shape = rotated
                Sounds.move:play()  -- Play move sound
            end
        end
    end
end

------------------
-- LÖVE Callbacks
------------------
function love.load()
    print("Save directory:", love.filesystem.getSaveDirectory())
    math.randomseed(os.time())
    love.window.setTitle("Tetris")
    reset_game()
    State.load_files = love.filesystem.getDirectoryItems("saves") or {}
    Sounds = {}
    -- Load sound effects (added)
    Sounds.move = love.audio.newSource("sounds/move.mp3", "static")
    Sounds.drop = love.audio.newSource("sounds/drop.mp3", "static")
    Sounds.clear = love.audio.newSource("sounds/clear.mp3", "static")
    Sounds.gameover = love.audio.newSource("sounds/gameover.mp3", "static")
end

function love.update(dt)
    if State.game_state == "playing" then
        if #State.clearing_lines > 0 then  -- Check if lines are being cleared
            State.clear_animation_timer = State.clear_animation_timer + dt
            if State.clear_animation_timer >= Config.animations.clear_duration then
                finish_clearing_lines()  -- Remove the lines *after* the animation
                State.clear_animation_timer = 0 -- Reset the timer
            end
            -- finish_clearing_lines()
        else  -- Normal gameplay (no lines being cleared)
            State.fall_timer = State.fall_timer + dt
            if State.fall_timer >= Config.board.fall_speed then
                State.fall_timer = 0
                if not check_collision(State.current_piece.x, State.current_piece.y + 1, State.current_piece.shape) then
                    State.current_piece.y = State.current_piece.y + 1
                else
                    freeze_piece(State.current_piece)
                    Sounds.drop:play()  -- Play place sound
                    if State.current_piece.y <= 1 then
                        State.game_state = "game_over"
                        Sounds.gameover:play()  -- Play game over sound
                    else
                        local cleared = check_lines()
                        if cleared then
                            Sounds.clear:play()  -- Play clear sound
                        end
                        State.block_count = State.block_count + 1
                        State.current_piece = State.next_piece
                        State.next_piece = new_random_piece()
                    end
                end
            end
        end
    elseif State.game_state == "load_menu" then
        State.load_files = love.filesystem.getDirectoryItems("saves") or {}
    end
end

function love.draw()
    love.graphics.setBackgroundColor(Config.board.colors.background)
    
    if State.game_state == "playing" and #State.clearing_lines > 0 then
        draw_clearing_lines() -- Draw the clearing animation
    end

    if State.game_state == "menu" then
        draw_menu()
    elseif State.game_state == "load_menu" then
        draw_load_menu()
    elseif State.game_state == "playing" then
        draw_board()
        draw_piece(State.current_piece, 
            (love.graphics.getWidth() - Config.board.width * Config.board.cell_size) / 2, 0)
        draw_ui()
    elseif State.game_state == "game_over" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Over!\nPress Enter to continue", 
            0, love.graphics.getHeight()/2 - 20, 
            love.graphics.getWidth(), "center")
    end
end

function love.keypressed(key)
    if State.game_state == "menu" then
        handle_menu_input(key)
    elseif State.game_state == "load_menu" then
        handle_load_menu_input(key)
    elseif State.game_state == "playing" then
        handle_game_input(key)
    elseif State.game_state == "game_over" and key == "return" then
        State.game_state = "menu"
    end
end