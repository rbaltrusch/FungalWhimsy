require "src/colour"
require "src/debug_util"
require "src/player"
require "src/animation"
require "src/error_util"
require "src/sprite_sheet"
require "src/tilemap"
require "src/camera"
require "src/collision"
require "src/timer"
require "src/sound_collection"
require "src/particle"

---@param time number
---@return string
local function get_time_string(time)
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time % 3600) / 60)
    local seconds = time % 60
    return string.format("%02i:%02i:%06.3f", hours, minutes, seconds)
end

local function get_player_rect(tiles)
    local player_tiles = TileMap.get_tile_rects(tiles["player"].tiles, TILE_SIZE)
    for pos, tile in pairs(player_tiles) do
        return tile.rect
    end
end

local function load_sound(filename, volume)
    local sound = love.audio.newSource(filename, "static")
    sound:setVolume(volume or 1)
    return sound
end

local function init_player()
    PLAYER_JUMP_HEIGHT = 51
    local death_sound = load_sound("assets/death.wav")
    death_sound:setPitch(3)

    local player_image = love.graphics.newImage("assets/player.png")
    player_image:setFilter("nearest", "nearest")
    player = Player.construct{
        image=player_image,
        x=0,
        y=0,
        speed=80,
        max_jump_height = PLAYER_JUMP_HEIGHT,
        stars = player and player.stars,
        deaths = player and player.deaths,
        jump_timer=Timer.construct(0.05),
        dash_timer=Timer.construct(0.45),
        coyote_timer=Timer.construct(0.2),
        idle_timer=Timer.construct(0.5),
        stun_timer=Timer.construct(0.5),
        death_timer=Timer.construct(0.5),
        stun_after_airborne=1,
        size= {x = 16, y = 22},
        tile_size=TILE_SIZE,
        walk_animation=Animation.construct(
            SpriteSheet.load_sprite_sheet("assets/player_walk.png", 17, 22, 1), 0.1
        ),
        walk_left_animation=Animation.construct(
            SpriteSheet.load_sprite_sheet("assets/player_walk_left.png", 17, 22, 1), 0.1
        ),
        idle_animation=Animation.construct(
            SpriteSheet.load_sprite_sheet("assets/player_idle.png", 17, 22, 1), 0.1
        ),
        death_animation=Animation.construct(
            SpriteSheet.load_sprite_sheet("assets/player_death.png", 17, 22, 1), 0.05
        ),
        walk_sound=load_sound("assets/walk.wav"),
        fall_sound=load_sound("assets/fall.wav"),
        land_sound=load_sound("assets/land.wav"),
        dash_sound=load_sound("assets/dash.wav", 0.3),
        checkpoint_sound=load_sound("assets/checkpoint.wav", 0.04),
        dash_reset=load_sound("assets/dash_reset.wav", 0.2),
        death_sound=death_sound,
        jump_sound=SoundCollection.construct({
            load_sound("assets/jump.wav", 0.3),
            load_sound("assets/jump2.wav", 0.3),
        }),
        landing_particle_system=ParticleSystem.construct({
            x = 0,
            y = 0,
            colour = Colour.construct(255, 255, 255, 0.5),
            size = 1,
            size_change = 2.5, -- per sec
            spawn_chance = 100,  -- per sec
            max_particles = 100,
            max_active_time = 0.3,
            speed_x_getter = function() return math.random(-20, 20) end,
            speed_y_getter = function() return - math.random(5, 10) end,
            expired_predicate = function(particle) return particle.size > 20 or particle.alive_time > 0.3 end
        }),
        walking_particle_system=ParticleSystem.construct({
            x = 0,
            y = 0,
            colour = Colour.construct(255, 255, 255, 0.5),
            size = 1,
            size_change = 1.5, -- per sec
            spawn_chance = 20,  -- per sec
            max_particles = 10,
            max_active_time = nil,
            speed_x_getter = function() return math.random(-1, 1) end,
            speed_y_getter = function() return - math.random(2, 3) end,
            expired_predicate = function(particle) return particle.size > 10 or particle.alive_time > 0.25 end
        }),
    }
end

local function load_tilemap(tilemap_name)
    tilemap = require(tilemap_name)
    tiles = TileMap.construct_tiles(tilemap, tileset)
    local player_rect = get_player_rect(tiles)
    init_player()
    player.x = player_rect.x1
    player.y = player_rect.y1
    player:set_checkpoint()
    player:move(1, 0) -- HACK for gravity fix if starting by standing on ground
    player:update_collisions(tiles["terrain"])
    camera:reset(player_rect.x1, player_rect.y1)
end

function love.load(_, _, restart)
    started = restart and true or false -- for title screen rendering at startup
    completed_since = 0
    completion_time = 0
    player_death_icon = love.graphics.newImage("assets/player_death_icon.png")
    player_death_icon:setFilter("nearest", "nearest")

    title_screen = love.graphics.newImage("assets/title_screen.png")
    title_screen:setFilter("nearest", "nearest")

    DASH_REFRESH_RESET_TIME = 2.5
    BACKGROUND_COLOUR = Colour.construct(0, 0, 0)
    background_image = love.graphics.newImage("assets/background.png")
    background_mushroom = love.graphics.newSpriteBatch(love.graphics.newImage("assets/large_mushroom_with_ground.png"))
    background_entities = {{32, 125, 133}, {32, 95, 52}, {25, 34, -48}, {24, 317, 165}, {20, 45, 22}, {19, 226, 159}, {18, 53, 170}, {17, 349, 12}, {16, 316, 69}, 
    {16, 204, -34}, {15, 328, 112}, {11, 172, 45}, {9, 174, 190}, {8, -46, 246}, {8, -46, -41}}
    WIN_WIDTH, WIN_HEIGHT = love.window.getDesktopDimensions()
    MAX_SCALING = DEFAULT_SCALING * math.min(WIN_WIDTH / WIDTH, WIN_HEIGHT / HEIGHT)
    love.window.setIcon(love.image.newImageData("assets/player_icon.png"))

    muted = false
    star_sound = load_sound("assets/star.wav", 0.05)
    win_sound = load_sound("assets/win.wav", 0.7)
    teleport_sound = load_sound("assets/teleport.wav")
    teleport_sound:setPitch(0.7)
    jump_pad_sound = load_sound("assets/boink.wav", 0.3)

    music = love.audio.newSource("assets/FungalWhimsy.wav", "stream")
    music:setVolume(0.5)
    music:setPitch(0.5)
    music:setLooping(true)
    music:play()

    won = false
    current_tilemap_index = 1
    tilemaps = {"assets/levels/level1", "assets/levels/level2", "assets/levels/level3"}
    tileset = SpriteSheet.load_sprite_sheet("assets/tilesheet.png", TILE_SIZE, TILE_SIZE, 1)
    camera = Camera.construct{x=0, y=0, speed_factor=2.5, width=WIDTH/DEFAULT_SCALING, height=HEIGHT/DEFAULT_SCALING}
    load_tilemap(tilemaps[current_tilemap_index])

    font = love.graphics.newFont("assets/KenneyPixel.ttf")
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)
    shader = love.graphics.newShader(require("src/shader"))
end

local function check_collectible_collisions()
    local player_rect = player:get_rect()
    local collectibles = TileMap.get_tile_rects(tiles["collectibles"].tiles, TILE_SIZE)
    for pos, tile in pairs(collectibles) do
        local x, y = unpack(pos)
        if Collision.colliding(player_rect, tile.rect) then
            if tile.tile.index == STAR and not won then
                player.stars = player.stars + 1
                star_sound:play()
                tiles["collectibles"].tiles[x][y] = nil
            elseif tile.tile.index == DASH_REFRESH and not tile.tile.collected then
                player.dash_timer:stop()
                player.dash_reset:play()
                ---@diagnostic disable-next-line: inject-field
                tile.tile.collected = 0
            elseif tile.tile.index == PORTAL then
                current_tilemap_index = current_tilemap_index + 1
                load_tilemap(tilemaps[current_tilemap_index])
                teleport_sound:play()
            end
        end
    end
end

local function check_interactible_collisions()
    local player_rect = player:get_rect()
    player_rect.y2 = player_rect.y2 + 1
    local collectibles = TileMap.get_tile_rects(tiles["interactibles"].tiles, TILE_SIZE)
    for pos, tile in pairs(collectibles) do
        -- print(player_rect.x1, player_rect.x2, player_rect.y1, player_rect.y2, tile.rect.x1, tile.rect.x2, tile.rect.y1, tile.rect.y2)
        if Collision.colliding(player_rect, tile.rect) then
            if tile.tile.index == JUMP_PAD then
                local factor = love.keyboard.isDown("space") and 3.2 or 2.1  -- jump higher with space
                -- force jump by resetting all jump vars
                player.jump_timer:stop()
                player.stun_timer:stop()
                player.airborne = false
                player:jump(PLAYER_JUMP_HEIGHT * factor, factor)
                jump_pad_sound:play()
            end
        end
    end
end

local function check_spike_collisions()
    local player_rect = player:get_rect()
    local x, y = player:get_current_bottom_tile()
    for x_offs = -1, 1 do
        for y_offs = -2, 1 do
            ---@diagnostic disable-next-line: undefined-field
            local tile = tiles["spikes"]:get(x + x_offs, y + y_offs)
            if tile ~= nil then
                local tile_rect = TileMap.get_tile_rect(x + x_offs, y + y_offs, TILE_SIZE)
                if tile.index == FLAT_SPIKES then -- smaller hitbox (only 4 pixels wide instead of 16)
                    tile_rect.y1 = tile_rect.y1 + (TILE_SIZE - 4)
                end
                if Collision.colliding(player_rect, tile_rect) then
                    player:die()
                end
            end
        end
    end
end

local function check_checkpoint_collisions()
    local player_rect = player:get_rect()
    local collectibles = TileMap.get_tile_rects(tiles["checkpoints"].tiles, TILE_SIZE)
    for pos, tile in pairs(collectibles) do
        if Collision.colliding(player_rect, tile.rect) then
            local checkpoint_x = tile.rect.x2 - player.size.x
            local checkpoint_y = tile.rect.y2 - player.size.y
            if tile.tile.index == WIN_FLAG then
                won = true
                if completed_since == 0 then
                    win_sound:play()
                end
            elseif player.checkpoint.x ~= checkpoint_x or player.checkpoint.y ~= checkpoint_y then
                player.checkpoint_sound:play()
            end
            player:set_checkpoint(checkpoint_x, checkpoint_y)
        end
    end
end

local function update_collectibles(dt)
    local collectibles = TileMap.get_tile_rects(tiles["collectibles"].tiles, TILE_SIZE)
    for pos, data in pairs(collectibles) do
        local tile = data.tile
        if tile.collected then
            tile.collected = tile.collected + dt
            if tile.collected > DASH_REFRESH_RESET_TIME then
                tile.collected = nil
            end
        end
    end
end

local function update(dt)
    if not started then
        player.fall_sound:stop()
        return
    end

    player:update(dt)
    player:update_collisions(tiles["terrain"])  -- only collide with a single tile layer or it will not work!
    check_collectible_collisions()
    update_collectibles(dt)
    check_interactible_collisions()
    check_checkpoint_collisions()
    check_spike_collisions()
    camera:update(player, dt)

    if not won then
        completion_time = completion_time + dt
    else
        completed_since = completed_since + dt
        if win_sound:isPlaying() then
            music:setVolume(math.max(0.1, 0.5 - completed_since / 4)) -- fade out 2s
        else
            music:setVolume(math.min(0.5, music:getVolume() + dt / 10)) -- fade back in 5s
        end
    end

    if not player.walking and (love.keyboard.isDown("left") or love.keyboard.isDown("right")) then
        local func = love.keyboard.isDown("left") and player.start_move_left or player.start_move_right
        func(player)
    end
end

local function draw_win_screen(width, height, scaling)
    local middle_x = width / (2 * scaling)
    local middle_y = height / (2 * scaling)
    local text_padding = 5

    local offset = 0
    local text = "You won!"
    local text_width = font:getWidth(text)
    love.graphics.print(text, middle_x - text_width/2, middle_y + offset, 0, 1.5, 1.5)

    offset = offset + font:getHeight() * 1.5 + text_padding
    text = string.format("Completed in %s", get_time_string(completion_time))
    text_width = font:getWidth(text)
    love.graphics.print(text, middle_x - text_width/2, middle_y + offset, 0, 1, 1)

    offset = offset + font:getHeight() * 1 + text_padding
    text = string.format("%s/%s collected", player.stars, MAX_STARS)
    text_width = font:getWidth(text)
    local star_x = middle_x - text_width/2 - TILE_SIZE + 7
    love.graphics.print(text, star_x + TILE_SIZE + 2, middle_y + offset, 0, 1, 1)
    love.graphics.draw(tileset.image, tileset.quads[STAR], love.math.newTransform(star_x, middle_y + offset - 4))

    offset = offset + TILE_SIZE - 2
    text = string.format("%s death%s", player.deaths, player.deaths == 1 and "" or "s")
    text_width = font:getWidth(text)
    font:getHeight()
    love.graphics.print(text, star_x + TILE_SIZE + 2, middle_y + offset, 0, 1, 1)
    love.graphics.draw(player_death_icon, love.math.newTransform(star_x, middle_y + offset - 4))

    offset = offset + TILE_SIZE + text_padding
    text = "Press r to try again"
    text_width = font:getWidth(text)
    love.graphics.print(text, middle_x - text_width/2, middle_y + offset, 0, 1, 1)
end

local function draw_background()
    love.graphics.draw(background_image, love.math.newTransform())
    background_mushroom:clear()
    for _, position in ipairs(background_entities) do
        local factor, x, y = unpack(position)
        background_mushroom:add(x - camera.total_x / factor, y - camera.total_y / factor, 0, 2, 2)
    end
    love.graphics.draw(background_mushroom)
end

local function draw()
    local scaling = love.window.getFullscreen() and MAX_SCALING or DEFAULT_SCALING
    love.graphics.scale(scaling, scaling)

    local width, height, _ = love.window.getMode()
    if not started then
        love.graphics.draw(title_screen, love.math.newTransform((width / (scaling * 2) - title_screen:getWidth()/2), 0))
        local text = "Press any key to start"
        local text_width = font:getWidth(text)
        love.graphics.print(text, width / scaling - text_width - 5, height / scaling - font:getHeight() - 5, 0, 0.5, 0.5)
        return
    end

    shader:send("u_resolution", {width, height})
    shader:send("u_time", love.timer.getTime())
    shader:send("u_death_time", player.death_timer.time / player.death_timer.delay)
    shader:send("u_offset", math.min(0.5, completed_since / 8))
    love.graphics.setShader(shader)
    love.graphics.setBackgroundColor(unpack(BACKGROUND_COLOUR))
    draw_background()

    local x_offset = math.sin(love.timer.getTime() * 5) * 1.5
    TileMap.render(tiles["terrain"].tiles, tileset, camera, TILE_SIZE, WIDTH, HEIGHT)
    TileMap.render(tiles["checkpoints"].tiles, tileset, camera, TILE_SIZE, WIDTH, HEIGHT)
    TileMap.render(tiles["interactibles"].tiles, tileset, camera, TILE_SIZE, WIDTH, HEIGHT)
    TileMap.render(tiles["spikes"].tiles, tileset, camera, TILE_SIZE, WIDTH, HEIGHT, 0, 5)
    TileMap.render(tiles["collectibles"].tiles, tileset, camera, TILE_SIZE, WIDTH, HEIGHT, x_offset)
    player:render(camera)

    love.graphics.setShader() --reset

    if DEBUG_ENABLED then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor({1, 0, 0})
        local rect = player:get_spike_rect()
        love.graphics.rectangle("line", rect.x1 - camera.total_x, rect.y1 - camera.total_y, rect.x2 - rect.x1, rect.y2 - rect.y1)
        love.graphics.setColor(r, g, b, a)
    end

    -- speed run timer
    if not won then
        local text = get_time_string(completion_time)
        love.graphics.printf(text, (width/scaling) - 45 - 10, 5, 200, "left", 0, 1, 1)
    end

    -- win screen
    if won then
        draw_win_screen(width, height, scaling)
    end

    if DEBUG_ENABLED then
        love.graphics.print(string.format("fps: %s", math.floor(love.timer.getFPS())), 0, 0, 0, 0.5, 0.5)
    end
end

function love.update(dt)
    if NUKE_FPS then
        for i = 0, 50 do
            print(i)
        end
    end
    update(dt)
end

function love.draw()
    draw()
end

function love.mousepressed()
    if not started then -- any key to start
        started = true
        return
    end
end

function love.keypressed(key)
    --Debug
    -- type "cont" to exit debug mode
    if DEBUG_ENABLED and key == "rctrl" then
       debug.debug()
    end

    if key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif key == "m" then
        muted = not muted
        love.audio.setVolume(muted and 0 or 1)
    elseif key == "escape" and not IS_WEB then
        love.event.quit(0)
    end

    if not started then -- any key to start
        started = true
        return
    end

    if key == "left" then
        player:start_move_left()
    elseif key == "right" then
        player:start_move_right()
    elseif key == "space" then
        player:jump(PLAYER_JUMP_HEIGHT, 1)
    elseif key == "c" then
        player:dash("neutral")
    elseif key == "r" then
        if won then
            player = nil -- reset stats
            music:stop()
            love.load(nil, nil, true)
        else  --respawn
            player:respawn()
            player:move(1, 0) -- HACK for gravity fix if starting by standing on ground
            player:update_collisions(tiles["terrain"])
        end

    elseif key == "z" and DEBUG_ENABLED then
        current_tilemap_index = current_tilemap_index == 1 and 2 or 1
        load_tilemap(tilemaps[current_tilemap_index])
    elseif key == "w" and DEBUG_ENABLED then
        won = true
        win_sound:play()
    end
end

local function handle_player_stop_walk(key)
    local keys = {
        ["left"] = player.start_move_left,
        ["right"] = player.start_move_right,
    }
    for key_, _ in pairs(keys) do
        if key_ == key then

            for key__, func in pairs(keys) do
                if love.keyboard.isDown(key__) then
                    func(player)
                    return
                end
            end
            player:stop()
        end
    end
end

function love.keyreleased(key)
    handle_player_stop_walk(key)
    if key == "space" then
        player.speed_y = 0
        player.jumping = false
    end
end

function love.visible(visible)
    love.audio.setVolume(visible and 1 or 0)
end
