---@meta

require "src/math_util"
require "src/collision"
require "src/tilemap"

Player = {}

function Player.construct(args)
    local player = {
        x = args.x,
        y = args.y,
        previous_x = args.x,
        previous_y = args.y,
        size = args.size,
        jump_timer = args.jump_timer,
        coyote_timer = args.coyote_timer,
        image = love.graphics.newImage(args.image_path),
        walk_sound = args.walk_sound,
        jump_sound = args.jump_sound,
        fall_sound = args.fall_sound,
        land_sound = args.land_sound,
        death_sound = args.death_sound,  -- TODO
        respawn_sound = args.respawn_sound, -- TODO
        unlock_sound = args.unlock_sound, -- TODO
        speed_x = 0,
        speed_y = 0,
        SPEED = args.speed,
        walk_animation = args.walk_animation,
        walk_left_animation = args.walk_left_animation,
        idle_animation = args.idle_animation,
        TILE_SIZE = args.tile_size,
        looking_right = true,
        airborne = false,
        jumping = false,
        idle = false,
        idle_timer = args.idle_timer,
        JUMP_DECAY = 37,  -- how fast jump speed drops
        JUMP_SPEED = 770,
        jump_counter = 0,
        dead = false,
        EDGE_LENIENCE = 7,  -- how forgiving terrain edge collisions are
        GRAVITY = 145,
        airborne_time = 0,
        MIN_AIRBORNE_TIME = 0.1,
    }

    function player.move(self, x, y)
        if x == 0 and y == 0 or self.dead then
            return
        end

        if not self.airborne and not self.walk_sound:isPlaying() then
            self.walk_sound:play()
        end

        if not self:get_animation().ongoing then
            self:get_animation():start()
        end
        self.x = self.x + x
        self.y = self.y + y
    end

    function player.start_move_left(self)
        self.looking_right = false
        self.walk_animation:stop()
        self.speed_x = - self.SPEED
        print(self.speed_x, self.speed_y)
    end

    function player.start_move_right(self)
        self.looking_right = true
        self.walk_left_animation:stop()
        self.speed_x = self.SPEED
        print(self.speed_x, self.speed_y)
    end

    function player.jump(self)
        if self.jump_timer:is_ongoing() or self.airborne and not self.coyote_timer:is_ongoing() then
            return
        end

        self.jump_sound:play()
        self.jump_counter = 0
        -- self.speed_y = - self.SPEED * 8
        self.speed_y = - self.JUMP_SPEED
        self.airborne = true
        self.jumping = true
        self.jump_timer:start()
        print("jumping", self.speed_x, self.speed_y)
    end

    function player.stop(self)
        print("stopping")
        self.speed_x = 0
    end

    function player.get_animation(self)
        if self.idle then
            return self.idle_animation
        end
        return self.looking_right and self.walk_animation or self.walk_left_animation
    end

    function player.update_jump(self)
        if not self.jumping then
            return
        end

        print("update jump", self.speed_y)
        -- self.speed_y = math.min(0, self.speed_y + decay)
        self.jump_counter = self.jump_counter + 1
        self.speed_y = - self.JUMP_SPEED * math.pow(0.5, self.jump_counter / 5)
        if self.jump_counter > 30 then
            self.speed_y = 0
            self.jumping = false
        end
    end

    function player.update_gravity(self)
        if self.jumping then
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
        self.coyote_timer:update(dt)
        self.idle_timer:update(dt)
        self:update_jump()
        self:update_gravity()

        if self.walk_sound:isPlaying() and self.speed_x == 0 or self.speed_y ~= 0 then
            self.walk_sound:stop()
        end

        if self.airborne then
            self.airborne_time = self.airborne_time + dt
            self.fall_sound:setVolume(self.airborne_time)
        end

        self.previous_x = self.x
        self.previous_y = self.y
        self:update_idle()
        self:move(self.speed_x * dt, self.speed_y * dt)
    end

    function player.get_current_bottom_tile(self)
        return {
            MathUtil.round(self.x / self.TILE_SIZE),
            MathUtil.round((self.y + self.size.y) / self.TILE_SIZE),  -- bottom tile
        }
    end

    function player.get_rect(self)
        return {
            x1 = self.x,
            y1 = self.y,
            x2 = self.x + self.size.x,
            y2 = self.y + self.size.y
        }
    end

    function player.respawn(self)
        -- TODO: set x and y
        if not self.respawn_sound:isPlaying() then
            self.respawn_sound:play()
        end
        self.dead = false
        print("respawned")
    end

    function player.die(self)
        self:stop()
        self.walk_sound:stop()
        self:get_animation():stop()
        if not self.death_sound:isPlaying() then
            self.death_sound:play()
        end
        print("died")
    end

    function player.update_collisions(self, tiles)
        local x, y = unpack(self:get_current_bottom_tile())
        self:_update_fall_by_gravity(tiles, x, y)
        self:_update_collisions(tiles, x, y - 1)  -- top
        self:_update_collisions(tiles, x, y)  -- bottom
    end

    function player._update_fall_by_gravity(self, tiles, x, y)
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

    function player._update_collisions(self, tiles, x, y)
        for x_offs = -1, 1 do
            for y_offs = -1, 1 do
                local tile = tiles:get(x + x_offs, y + y_offs)
                if tile == nil then
                    goto continue
                end

                local tile_rect = TileMap.get_tile_rect(x + x_offs, y + y_offs, self.TILE_SIZE)
                local player_rect = player:get_rect()

                -- HACK - open doors
                -- local DOOR = 539
                -- if tile.index - 1 == DOOR and (self.inventory.items["key"] or 0) > 0 then
                --     tiles.tiles[x + x_offs][y + y_offs] = nil -- remove door
                --     self.unlock_sound:play()
                --     self.inventory.items["key"] = self.inventory.items["key"] - 1
                --     goto continue
                -- end

                if not Collision.colliding(player_rect, tile_rect) then
                    goto continue
                end

                local speed_x = self.x - self.previous_x
                local speed_y = self.y - self.previous_y
                if speed_x ~= 0 then
                    print("collide x")
                    local y_overlap = Collision.get_y_overlap(player_rect, tile_rect)
                    local neighbour = tiles:get(x + x_offs, y + y_offs + (y_overlap > 0 and -1 or 1))
                    if math.abs(y_overlap) < self.EDGE_LENIENCE and neighbour == nil then
                        self.y = self.y - y_overlap
                    else
                        self.x = tile_rect.x1 + self.TILE_SIZE * (speed_x > 0 and -1 or 1)
                    end
                end
                if speed_y ~= 0 then
                    print("collide y")
                    local x_overlap = Collision.get_x_overlap(player_rect, tile_rect)
                    local neighbour = tiles:get(x + x_offs + (x_overlap > 0 and -1 or 1), y + y_offs)
                    if math.abs(x_overlap) < self.EDGE_LENIENCE and neighbour == nil then
                        if not self.airborne then
                            self.x = self.x - x_overlap
                        end
                    else
                        -- land on ground
                        self.y = tile_rect.y1 + (speed_y > 0 and - self.size.y  or self.TILE_SIZE)
                        self.airborne = false
                        self.speed_y = 0
                        self.coyote_timer:stop()
                        if self.fall_sound:isPlaying() then
                            self.fall_sound:stop()
                        end
                        if self.land_sound:isPlaying() then
                            self.land_sound:stop()
                        end
                        self.land_sound:setVolume(math.min(1, self.airborne_time / 4))
                        self.land_sound:play()
                        self.airborne_time = 0
                    end
                end
                ::continue::
            end
        end
    end

    function player.render(self, camera)
        local transform = love.math.newTransform(self.x - camera.total_x, self.y - camera.total_y)
        local anim = self:get_animation()
        if anim.ongoing then
            local quad = anim:get_current_quad()
            love.graphics.draw(anim.image, quad, transform)
        else
            love.graphics.draw(self.image, transform)
        end
    end

    return player
end
