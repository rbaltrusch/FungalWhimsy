---@meta

require "src/math_util"
require "src/collision"
require "src/tilemap"

Player = {}

function Player.construct(args)
    local player = {
        x = args.x,
        y = args.y,
        checkpoint = {x = args.x, y = args.y},
        previous_x = args.x,
        previous_y = args.y,
        size = args.size,
        jump_timer = args.jump_timer,
        dash_timer = args.dash_timer,
        coyote_timer = args.coyote_timer,
        stun_timer = args.stun_timer,
        death_timer = args.death_timer,
        stun_after_airborne = args.stun_after_airborne,
        image = args.image,
        walk_sound = args.walk_sound,
        jump_sound = args.jump_sound,
        fall_sound = args.fall_sound,
        land_sound = args.land_sound,
        dash_sound = args.dash_sound,
        death_sound = args.death_sound,
        checkpoint_sound = args.checkpoint_sound,
        dash_reset = args.dash_reset,
        speed_x = 0,
        speed_y = 0,
        SPEED = args.speed,
        walk_animation = args.walk_animation,
        walk_left_animation = args.walk_left_animation,
        idle_animation = args.idle_animation,
        death_animation = args.death_animation,
        TILE_SIZE = args.tile_size,
        dash_looking_right = true,
        looking_right = true,
        airborne = false,
        walking = false,
        jumping = false,
        dashing = false,
        idle = false,
        dying = false,
        idle_timer = args.idle_timer,
        jump_update_timer = Timer.construct(0.212),
        dash_update_timer = Timer.construct(0.192),
        landing_particle_system = args.landing_particle_system,
        walking_particle_system = args.walking_particle_system,
        JUMP_DECAY = 37,  -- how fast jump speed drops
        JUMP_SPEED = 591,
        DASH_SPEED = 250,
        EDGE_LENIENCE = 7,  -- how forgiving terrain edge collisions are
        GRAVITY = 120,
        airborne_time = 0,
        MIN_AIRBORNE_TIME = 0.1,
        jump_height_reached = 0,
        max_jump_height = args.max_jump_height,
        jump_factor = 1,
        dash_factor = 1,
        dash_type = nil,
        dash_positions = {},
        deaths = args.deaths or 0,
        stars = args.stars or 0,
    }

    function player.move(self, x, y)
        if x == 0 and y == 0 or self.dying then
            return
        end

        if not self.airborne and not self.walk_sound:isPlaying() then
            self.walk_sound:play()
        end

        if not self:get_animation().ongoing and not self.stun_timer.ongoing then
            self:get_animation():start()
        end
        self.x = self.x + x
        self.y = self.y + y
    end

    function player.start_move_left(self)
        if self.stun_timer.ongoing then
            return
        end
        self.walking = true
        self.looking_right = false
        self.walk_animation:stop()
        self.walking_particle_system:start()
    end

    function player.start_move_right(self)
        if self.stun_timer.ongoing then
            return
        end
        self.walking = true
        self.looking_right = true
        self.walk_left_animation:stop()
        self.walking_particle_system:start()
    end

    function player.stop(self)
        print("stopping")
        self.speed_x = 0
        self.walking = false
        self.walking_particle_system:stop()
    end

    function player.jump(self, max_jump_height, factor)
        if self.stun_timer.ongoing then
            return
        end
        if self.jump_timer:is_ongoing() or self.airborne and not self.coyote_timer:is_ongoing() then
            return
        end

        if self.dashing then -- boosted ground dash
            self.dash_factor = 1.9
        end

        self.max_jump_height = max_jump_height
        self.jump_factor = factor
        self.jump_sound:play()
        self.speed_y = 0-- - self.JUMP_SPEED
        self.airborne = true
        self.airborne_time = 0
        self.jumping = true
        self.jump_height_reached = 0
        self.jump_timer:start()
        self.jump_update_timer:start()
    end

    ---@param dash_type string
    function player.dash(self, dash_type)
        if self.dash_timer:is_ongoing() or self.dashing then
            return
        end

        self.dash_sound:play()
        self.dashing = true
        self.dash_factor = 1
        self.dash_positions = {{self.x, self.y}}
        self.dash_looking_right = self.looking_right
        self.dash_timer:start()
        self.dash_type = dash_type
        self.dash_update_timer:start()
    end

    function player.set_dash_speed(self)
        if not self.jumping then
            self.speed_y = 0
        end

        if self.dash_type == "neutral" then
            self.speed_x = self.DASH_SPEED * (self.dash_looking_right and 1 or -1) * self.dash_factor
        end
    end

    function player.update_dash(self)
        if not self.dashing then
            return
        end

        self:set_dash_speed()
        self.dash_positions[#self.dash_positions + 1] = {self.x, self.y}
        if self.dash_update_timer:is_expired() then
            self.dash_positions = {}
            self.dashing = false
            self.speed_x = 0
            self.speed_y = 0
        end
    end

    function player.update_jump(self)
        if not self.jumping then
            return
        end

        local completion = self.jump_update_timer.time / self.jump_update_timer.delay
        self.speed_y = - self.JUMP_SPEED * math.pow(2, -4 * completion) * self.jump_factor
        if self.jump_update_timer:is_expired() then
            self.speed_y = 0
            self.jumping = false
        end
    end

    function player.update_gravity(self)
        if self.jumping or self.dashing then
            return
        end
        self.speed_y = self.airborne and self.GRAVITY or 0
    end

    function player.update_idle(self)
        local idle = self.idle
        self.idle = self.speed_x == 0 and self.speed_y == 0
        if self.idle and not idle then
            self.idle_timer:start()
        end

        if self.idle then
            if not self.idle_animation.ongoing and self.idle_timer:is_expired() then
                self.idle_animation:start()
            end
        else
            self.idle_animation:stop()
            self.idle_timer:stop()
        end
    end

    function player.update(self, dt)
        self:get_animation():update(dt)
        self.jump_timer:update(dt)
        self.dash_timer:update(dt)
        self.coyote_timer:update(dt)
        self.idle_timer:update(dt)
        self.stun_timer:update(dt)
        self.jump_update_timer:update(dt)
        self.dash_update_timer:update(dt)
        self:update_jump()
        self:update_dash()
        self:update_gravity()
        self.landing_particle_system:update(dt)
        self.walking_particle_system:update(dt)
        self.walking_particle_system:move_to(self.x + self.size.x / 2, self.y + self.size.y)

        if self:check_dead() then
            self.death_timer:update(dt)
            if self.death_timer:is_expired() then
                self:respawn()
            end
        end

        if self.walk_sound:isPlaying() and not self.walking then
            self.walk_sound:stop()
        end

        if self.airborne and not self.jumping then
            self.airborne_time = self.airborne_time + dt
            self.landing_particle_system.max_active_time = self.airborne_time * 0.6
            self.landing_particle_system.max_particles = math.ceil(self.airborne_time * 30)
            local max_particle_size = math.min(math.ceil(self.airborne_time * 30), 20)
            self.landing_particle_system.expired_predicate = function(particle)
                return particle.size > max_particle_size or particle.alive_time > self.landing_particle_system.max_active_time
            end
            self.fall_sound:setVolume(math.min(1, self.airborne_time * 0.6))
        end

        self.previous_x = self.x
        self.previous_y = self.y
        self:update_idle()

        if self.stun_timer:is_expired() then
            self.stun_timer:stop()
        end

        if self.jumping then
            local old = self.jump_height_reached
            self.jump_height_reached = old + self.speed_y * dt
            if math.abs(self.jump_height_reached) > self.max_jump_height then
                self.jumping = false
                self.speed_y = - (self.max_jump_height - math.abs(old)) / dt
            end
        end

        if not self.stun_timer.ongoing then
            local walk_speed = self.walking and (self.SPEED * (self.looking_right and 1 or -1)) or 0
            self:move((self.speed_x + walk_speed) * dt, self.speed_y * dt)
        end
    end

    function player.get_current_bottom_tile(self)
        return MathUtil.round(self.x / self.TILE_SIZE), MathUtil.round((self.y + self.size.y) / self.TILE_SIZE)
    end

    function player.get_rect(self)
        return {
            x1 = self.x,
            y1 = self.y,
            x2 = self.x + self.size.x,
            y2 = self.y + self.size.y
        }
    end

    function player.get_spike_rect(self)
        local player_rect = self:get_rect()
        player_rect.x1 = player_rect.x1 + 2
        player_rect.x2 = player_rect.x2 - 2
        player_rect.y1 = player_rect.y1 + 3
        player_rect.y2 = player_rect.y2 - 3
        return player_rect
    end

    function player.set_checkpoint(self, x, y)
        self.checkpoint = {x = x or self.x, y = y or self.y}
    end

    function player.respawn(self)
        self.x = self.checkpoint.x
        self.y = self.checkpoint.y
        self.dying = false
        self.airborne_time = 0 -- no stun after respawn
        self.death_timer:stop()
        print("respawned")
    end

    function player.die(self)
        if self.dying then
            return
        end

        self:stop()
        self.walk_sound:stop()
        self:get_animation():stop()
        if not self.death_sound:isPlaying() then
            self.death_sound:play()
        end
        self.deaths = self.deaths + 1
        self.dying = true
        self.death_animation:start()
        self.fall_sound:stop()
        self.death_timer:start()
        print("died")
    end

    function player.check_dead(self)
        return self.dying and not self.death_animation.ongoing  -- finished death animation
    end

    function player.update_collisions(self, tiles)
        local x, y = self:get_current_bottom_tile() -- rounded
        local foot_y = math.floor((self.y + self.size.y) / self.TILE_SIZE)
        self:_update_fall_by_gravity(tiles, x, foot_y)
        self:_update_collisions(tiles, x, y)  -- bottom
    end

    function player._update_fall_by_gravity(self, tiles, x, y)
        if self.dying or self.dashing then
            return
        end

        -- handle gravity start by falling due to no floor
        local floor = tiles:get(x, y)
        local airborne = self.airborne
        if floor == nil then
            self.airborne = true
            if not self.coyote_timer.ongoing then
                self.coyote_timer:start()
            end
            if not airborne then
                self.fall_sound:play()
            end
            self:get_animation():stop()
        end
    end

    function player._land_on_ground(self)
        self.airborne = false
        self.speed_y = 0
        self.coyote_timer:stop()
        if self.fall_sound:isPlaying() then
            self.fall_sound:stop()
        end
        if self.land_sound:isPlaying() then
            self.land_sound:stop()
        end
        if self.airborne_time > self.stun_after_airborne then
            self.stun_timer:start()
            self.walking = false
        end
        self.landing_particle_system:move_to(self.x + self.size.x / 2, self.y + self.size.y)
        self.landing_particle_system:start()
        self.land_sound:setVolume(math.min(1, self.airborne_time / 4))
        self.land_sound:play()
        self.airborne_time = 0
    end

    function player._update_collisions(self, tiles, x, y)
        for x_offs = -1, 1 do
            for y_offs = -2, 1 do
                local player_rect = player:get_rect()
                local tile = tiles:get(x + x_offs, y + y_offs)
                if tile ~= nil then
                    local tile_rect = TileMap.get_tile_rect(x + x_offs, y + y_offs, self.TILE_SIZE)
                    if Collision.colliding(player_rect, tile_rect) then
                        local speed_x = self.x - self.previous_x
                        local speed_y = self.y - self.previous_y
                        if speed_x ~= 0 then
                            local y_overlap = Collision.get_y_overlap(player_rect, tile_rect)
                            local neighbour = tiles:get(x + x_offs, y + y_offs + (y_overlap > 0 and -1 or 1))
                            if math.abs(y_overlap) < self.EDGE_LENIENCE and neighbour == nil then
                                self.y = self.y - y_overlap
                            else
                                self.x = tile_rect.x1 + self.TILE_SIZE * (speed_x > 0 and -1 or 1)
                            end
                        end
                        if speed_y ~= 0 then
                            local x_overlap = Collision.get_x_overlap(player_rect, tile_rect)
                            local neighbour = tiles:get(x + x_offs + (x_overlap > 0 and -1 or 1), y + y_offs)
                            if math.abs(x_overlap) < self.EDGE_LENIENCE and neighbour == nil then
                                if not self.airborne then
                                    self.x = self.x - x_overlap
                                end
                            else
                                -- land on ground
                                self.y = tile_rect.y1 + (speed_y > 0 and - self.size.y  or self.TILE_SIZE)
                                self:_land_on_ground()
                            end
                        end
                    end
                end
            end
        end
    end

    function player.get_animation(self)
        if self.dying then
            return self.death_animation
        end
        if self.idle then
            return self.idle_animation
        end
        return self.looking_right and self.walk_animation or self.walk_left_animation
    end

    function player.render(self, camera)
        self.landing_particle_system:draw(camera)
        self.walking_particle_system:draw(camera)
        if self:check_dead() then
            return
        end

        local function draw(transform)
            local anim = self:get_animation()
            if anim.ongoing then
                local quad = anim:get_current_quad()
                love.graphics.draw(anim.image, quad, transform)
            else
                love.graphics.draw(self.image, transform)
            end
        end

        -- not dashing or in place dash
        if not self.dashing or #self.dash_positions == 1 then
            local transform = love.math.newTransform(self.x - camera.total_x, self.y - camera.total_y)
            draw(transform)
        else
            local r, g, b, a = love.graphics.getColor()
            local length = #self.dash_positions
            for i, pos in ipairs(self.dash_positions) do
                local x, y = unpack(pos)
                local alpha = math.max(0.05, i / length)
                love.graphics.setColor(1, 1, 1, alpha) -- set alpha for image draw -- FIXME not working
                local transform = love.math.newTransform(x - camera.total_x, y - camera.total_y)
                local anim = self:get_animation()
                if anim.ongoing then
                    local quad = anim:get_current_quad()
                    love.graphics.draw(anim.image, quad, transform)
                else
                    love.graphics.draw(self.image, transform)
                end
            end
            love.graphics.setColor(r, g, b, a) -- reset
        end
    end

    return player
end
