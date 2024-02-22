Animation = {}

function Animation.construct(sprite_sheet, time_per_frame)
    local animation = {
        image = sprite_sheet.image,
        quads = sprite_sheet.quads,
        size = sprite_sheet.size,
        time_per_frame = time_per_frame,
        ongoing = false,
        counter = 1,
    }

    function animation.start(self)
        self.counter = 1
        self.ongoing = true
    end

    function animation.stop(self)
        self.ongoing = false
    end

    function animation.update(self, dt)
        if not self.ongoing then
            return
        end

        self.counter = self.counter + dt / time_per_frame
        if self.counter >= self.size + 1 then
            self.ongoing = false
        end
    end

    function animation.get_current_quad(self)
        return self.quads[math.floor(self.counter)]
    end

    return animation
end
