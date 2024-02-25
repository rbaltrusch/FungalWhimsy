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
    PLAYER_JUMP_HEIGHT = 36
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
        jump_timer=Timer.construct(0.4),
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
            colour = Colour.construct(200, 200, 200, 0.2),
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
            colour = Colour.construct(200, 200, 200, 0.2),
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
end

function love.load()
    JUMP_PAD = 21
    PORTAL = 22
    WIN_FLAG = 10
    DASH_REFRESH = 23
    STAR = 25
    FLAT_SPIKES = 17

    completed_since = 0
    completion_time = 0
    MAX_STARS = 10 -- TODO
    player_death_icon = love.graphics.newImage("assets/player_death_icon.png")
    player_death_icon:setFilter("nearest", "nearest")

    BACKGROUND_COLOUR = Colour.construct(0, 0, 0)
    background_image = love.graphics.newImage("assets/background.png")
    background_mushroom = love.graphics.newImage("assets/large_mushroom_with_ground.png")
    -- background_mushroom:setFilter("nearest", "nearest")
    -- background_entities = {{32, 137, 119}, {31, 184, 77}, {31, 181, 69}, {29, 94, 39}, {28, 6, 189}, {28, -24, 139}, {26, 262, 106}, {26, 233, 217}, {26, 174, 20}, {26, 80, 190}, {25, 210, 2}, {24, 211, 204}, {24, 147, 9}, {24, 139, -28}, {24, -13, 220}, {21, 290, 196}, {21, 167, 69}, {21, 132, 129}, {19, 330, -2}, {19, 229, -40}, {19, 101, 117}, {19, -1, 194}, {18, 187, 162}, {17, 296, 212}, {17, 217, 215}, {17, -6, 159}, {16, 298, -11}, {16, 74, 61}, {15, 346, 241}, {15, 43, 242}, {15, -38, 127}, {13, 110, 13}, {13, 44, 88}, {12, 54, -12}, {11, -10, 18}, {10, 239, 216}, {9, 
    -- 343, 41}, {9, 154, 195}, {8, 282, 12}, {8, -10, -47}}
    background_entities = {{32, 125, 133}, {32, 95, 52}, {25, 34, -48}, {24, 317, 165}, {20, 45, 22}, {19, 226, 159}, {18, 53, 170}, {17, 349, 12}, {16, 316, 69}, 
    {16, 204, -34}, {15, 328, 112}, {11, 172, 45}, {9, 174, 190}, {8, -46, 246}, {8, -46, -41}}
    TILE_SIZE = 16
    DEBUG_ENABLED = true
    DEFAULT_SCALING = 2
    WIDTH, HEIGHT = 600, 450
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
    tilemaps = {"assets/testmap", "assets/testmap2"}
    tileset = SpriteSheet.load_sprite_sheet("assets/tilesheet.png", TILE_SIZE, TILE_SIZE, 1)
    load_tilemap(tilemaps[current_tilemap_index])

    camera = Camera.construct{x=0, y=0, speed_factor=2.5, width=WIDTH/DEFAULT_SCALING, height=HEIGHT/DEFAULT_SCALING}
    font = love.graphics.newFont("assets/KenneyPixel.ttf")
    font:setFilter("nearest", "nearest")
    shader = love.graphics.newShader(require("src/shader"))
end

local function check_collectible_collisions()
    local player_rect = player:get_rect()
    local collectibles = TileMap.get_tile_rects(tiles["collectibles"].tiles, TILE_SIZE)
    for pos, tile in pairs(collectibles) do
        local x, y = unpack(pos)
        if Collision.colliding(player_rect, tile.rect) then
            if tile.tile.index == STAR then
                if won then goto continue end
                player.stars = player.stars + 1
                star_sound:play()
            elseif tile.tile.index == DASH_REFRESH then
                player.dash_timer:stop()
                player.dash_reset:play()
            elseif tile.tile.index == PORTAL then
                current_tilemap_index = current_tilemap_index + 1
                load_tilemap(tilemaps[current_tilemap_index])
                teleport_sound:play()
            end
            tiles["collectibles"].tiles[x][y] = nil
            ::continue::
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
                local factor = love.keyboard.isDown("space") and 3 or 2  -- jump higher with space
                player:jump(PLAYER_JUMP_HEIGHT * factor, factor)
                jump_pad_sound:play()
            end
        end
    end
end

local function check_spike_collisions()
    local player_rect = player:get_rect()
    local collectibles = TileMap.get_tile_rects(tiles["spikes"].tiles, TILE_SIZE)
    for pos, tile in pairs(collectibles) do
        if tile.tile.index == FLAT_SPIKES then -- smaller hitbox (only 4 pixels wide instead of 16)
            tile.rect.y1 = tile.rect.y1 + (TILE_SIZE - 4)
        end
        if Collision.colliding(player_rect, tile.rect) then
            player:die()
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

local function update(dt)
    player:update(dt)
    player:update_collisions(tiles["terrain"])  -- only collide with a single tile layer or it will not work!
    check_collectible_collisions()
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

local function draw()
    local scaling = love.window.getFullscreen() and MAX_SCALING or DEFAULT_SCALING
    love.graphics.scale(scaling, scaling)

    local width, height, _ = love.window.getMode()
    shader:send("u_resolution", {width, height})
    shader:send("u_time", love.timer.getTime())
    shader:send("u_death_time", player.death_timer.time / player.death_timer.delay)
    shader:send("u_offset", math.min(0.5, completed_since / 8))
    love.graphics.setShader(shader)
    love.graphics.setBackgroundColor(unpack(BACKGROUND_COLOUR))
    love.graphics.draw(background_image, love.math.newTransform())
    for _, position in ipairs(background_entities) do
        local factor, x, y = unpack(position)
        love.graphics.draw(background_mushroom, love.math.newTransform(x - camera.total_x / factor, y - camera.total_y / factor, 0, 2, 2))
    end

    local x_offset = math.sin(love.timer.getTime() * 5) * 1.5
    TileMap.render(tiles["terrain"].tiles, tileset, camera, TILE_SIZE)
    TileMap.render(tiles["checkpoints"].tiles, tileset, camera, TILE_SIZE)
    TileMap.render(tiles["interactibles"].tiles, tileset, camera, TILE_SIZE)
    TileMap.render(tiles["spikes"].tiles, tileset, camera, TILE_SIZE, 0, 5)
    TileMap.render(tiles["collectibles"].tiles, tileset, camera, TILE_SIZE, x_offset)
    player:render(camera)

    love.graphics.setShader() --reset

    love.graphics.setFont(font)

    -- speed run timer
    if not won then
        local text = get_time_string(completion_time)
        love.graphics.printf(text, (width/scaling) - 45 - 10, 5, 200, "left", 0, 1, 1)
    end

    -- win screen
    if won then
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

    if DEBUG_ENABLED then
        love.graphics.print(string.format("fps: %s", math.floor(love.timer.getFPS())), 0, 0, 0, 0.5, 0.5)
    end
end

function love.update(dt)
    ErrorUtil.call_or_exit(function() update(dt) end, not DEBUG_ENABLED)
end

function love.draw()
    ErrorUtil.call_or_exit(draw, not DEBUG_ENABLED)
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
    elseif key == "escape" then
        love.event.quit(0)
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
            love.load()
        else  --respawn
            player:respawn()
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
        if key_ ~= key then goto continue end

        for key__, func in pairs(keys) do
            if love.keyboard.isDown(key__) then
                func(player)
                return
            end
        end
        player:stop()
        ::continue::
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
