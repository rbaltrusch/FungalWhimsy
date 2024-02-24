ParticleSystem = {}

function ParticleSystem.construct(args)
    return {
        x = args.x,
        y = args.y,
        colour = args.colour,
        size = args.size,
        size_change = args.size_change,
        speed_x_getter = args.speed_x_getter,
        speed_y_getter = args.speed_y_getter,
        expired_predicate = args.expired_predicate,
        spawn_chance = args.spawn_chance,
        max_particles = args.max_particles,
        particles = {},
        active = false,
        active_time = 0,
        max_active_time = args.max_active_time,
        update = ParticleSystem.update,
        draw = ParticleSystem.draw,
        move_to = ParticleSystem.move_to,
        start = ParticleSystem.start,
        stop = ParticleSystem.stop,
        _spawn_new_particle = ParticleSystem._spawn_new_particle,
    }
end

function ParticleSystem.start(self)
    self.active_time = 0
    self.active = true
end

function ParticleSystem.stop(self)
    self.active_time = 0
    self.active = false
    self.particles = {}
end

function ParticleSystem.move_to(self, x, y)
    self.x = x
    self.y = y
end

function ParticleSystem.update(self, dt)
    if not self.active then
        return
    end

    self.active_time = self.active_time + dt

    -- spawn one or more particles, depending on spawn chance
    local can_spawn = not self.max_active_time or self.active_time <= self.max_active_time
    if can_spawn and #self.particles < self.max_particles then
        local spawn_chance = self.spawn_chance * dt
        if spawn_chance > 1 then
            for _ = 0, math.floor(spawn_chance) do
                table.insert(self.particles, self:_spawn_new_particle())
            end
        elseif spawn_chance > math.random() then
            table.insert(self.particles, self:_spawn_new_particle())
        end
    end

    for _, particle in ipairs(self.particles) do
        if not particle.expired then
            particle:update(dt)
        end
    end

    -- remove expired
    local expired = {}
    for i, particle in ipairs(self.particles) do
        if particle.expired then
            table.insert(expired, i)
        end
    end
    for _, i in ipairs(expired) do
        table.remove(self.particles, i)
    end
end

function ParticleSystem._spawn_new_particle(self)

    local function update(_self, dt)
        if _self.expired then
            return
        end
        _self.size = _self.size + _self.size_change * dt
        _self.x = _self.x + _self.speed_x * dt
        _self.y = _self.y + _self.speed_y * dt
        _self.alive_time = _self.alive_time + dt
        _self.expired = self.expired_predicate(_self)
    end

    local function draw(_self, camera)
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(_self.colour)
        love.graphics.circle("fill", _self.x - camera.total_x, _self.y - camera.total_y, _self.size)
        love.graphics.setColor(r, g, b, a)
    end

    local speed_x = self.speed_x_getter()
    local speed_y = self.speed_y_getter()
    return {
        x = self.x + speed_x / 2,
        y = self.y + speed_y / 2,
        speed_x = speed_x,
        speed_y = speed_y,
        colour = self.colour,
        size = self.size,
        size_change = self.size_change,
        alive_time = 0,
        update = update,
        draw = draw,
    }
end

function ParticleSystem.draw(self, camera)
    if not self.active then
        return
    end

    for _, particle in ipairs(self.particles) do
        if not particle.expired then
            particle:draw(camera)
        end
    end
end
