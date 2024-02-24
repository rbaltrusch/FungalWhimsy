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

function love.load()
    BACKGROUND_COLOUR = Colour.construct(0, 0, 0)
    TILE_SIZE = 16
    DEBUG_ENABLED = false
    DEFAULT_SCALING = 2
    WIDTH, HEIGHT = 600, 450
    WIN_WIDTH, WIN_HEIGHT = love.window.getDesktopDimensions()
    MAX_SCALING = DEFAULT_SCALING * math.min(WIN_WIDTH / WIDTH, WIN_HEIGHT / HEIGHT)
    -- love.window.setIcon(love.image.newImageData("assets/runeM.png"))

    muted = false

    -- TODO
    -- local music = love.audio.newSource("assets/myrkur_menu2.wav", "stream")
    -- music:setVolume(0.2)
    -- music:setPitch(0.5)
    -- music:setLooping(true)
    -- music:play()

    tileset = SpriteSheet.load_sprite_sheet("assets/quick_tilesheet.png", TILE_SIZE, TILE_SIZE, 1)
    tilemap = require "assets/testmap"
    collision_map = TileMap.construct_collision_map(tilemap, "terrain")
    tiles = TileMap.construct_tiles(tilemap, tileset)

    local player_image = love.graphics.newImage("assets/player.png")
    player_image:setFilter("nearest", "nearest")
    local player_rect = get_player_rect(tiles)
    player = Player.construct{
        image=player_image,
        x=player_rect.x1,
        y=player_rect.y1,
        speed=80,
        jump_timer=Timer.construct(0.45),
        coyote_timer=Timer.construct(0.2),
        idle_timer=Timer.construct(0.5),
        stun_timer=Timer.construct(0.5),
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
        walk_sound=load_sound("assets/walk.wav"),
        fall_sound=load_sound("assets/fall.wav"),
        land_sound=load_sound("assets/land.wav"),
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
    player:move(1, 0)
    player:update_collisions(tiles["terrain"])
    camera = Camera.construct{x=0, y=0, speed_factor=2.5, width=WIDTH/DEFAULT_SCALING, height=HEIGHT/DEFAULT_SCALING}
    font = love.graphics.newFont("assets/KenneyPixel.ttf")

    shader = love.graphics.newShader(require("src/shader"))
end

local function check_collectible_collisions()
    local player_rect = player:get_rect()
    local collectibles = TileMap.get_tile_rects(tiles["collectibles"].tiles, TILE_SIZE)
    for pos, tile in pairs(collectibles) do
        if Collision.colliding(player_rect, tile.rect) then
            -- TODO do something with tile
        end
    end
end

local function update(dt)
    player:update(dt)
    player:update_collisions(tiles["terrain"])
    check_collectible_collisions()
    camera:update(player, dt)

    -- if won then
    --     return
    -- end

    -- for _, entity in ipairs(entities) do
    --     entity:update(dt, player, collision_map)
    -- end
end

local function respawn()
    -- TODO
    player:respawn()
end

local function draw()
    local scaling = love.window.getFullscreen() and MAX_SCALING or DEFAULT_SCALING
    love.graphics.scale(scaling, scaling)

    local width, height, _ = love.window.getMode()
    shader:send("u_resolution", {width, height})
    shader:send("u_time", love.timer.getTime())
    love.graphics.setShader(shader)
    love.graphics.setBackgroundColor(unpack(BACKGROUND_COLOUR))

    local x_offset = math.sin(love.timer.getTime() * 5) * 1.5
    TileMap.render(tiles["terrain"].tiles, tileset, camera, TILE_SIZE)
    TileMap.render(tiles["collectibles"].tiles, tileset, camera, TILE_SIZE, x_offset)
    player:render(camera)

    -- for _, entity in ipairs(entities) do
    --     entity:render(camera)
    -- end

    love.graphics.setShader() --reset

    love.graphics.setFont(font)

    -- local text = crown_bar:get_text(player.inventory.items["crown"])
    -- local text_width = font:getWidth(text)
    -- love.graphics.printf(text, width/scaling - text_width - TILE_SIZE - 10, 10, 200, "left", 0, 1, 1)
    -- love.graphics.draw(crown_bar.image, width/scaling - TILE_SIZE - 10, 10 - TILE_SIZE/4)

    -- if won then
    --     local text = "You won!"
    --     local text_width = font:getWidth(text)
    --     love.graphics.printf(text, width/2/scaling - text_width/2, height/2/scaling, 200, "left", 0, 1, 1)
    -- end

    if not player.dead then
        -- respawn
    end

    -- local anim = tileset -- player.walk_animation
    -- for x = 1, anim.size do
    --     local transform = love.math.newTransform(player.x - camera.total_x - 100 + x * 14, player.y - camera.total_y + 50)
    --     love.graphics.draw(anim.image, anim.quads[3], transform)
    -- end

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

    if key == "left" or key == "a" then
        player:start_move_left()
    elseif key == "right" or key == "d" then
        player:start_move_right()
    elseif key == "space" then
        player:jump()
    elseif key == "c" then
        -- camera.enabled = not camera.enabled
    end
end

local function handle_player_stop_walk(key)
    local keys = {
        ["left"] = player.start_move_left,
        ["right"] = player.start_move_right,
        ["a"] = player.start_move_left,
        ["e"] = player.start_move_left,
        ["d"] = player.start_move_right,
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
    end
end

function love.visible(visible)
    love.audio.setVolume(visible and 1 or 0)
end
