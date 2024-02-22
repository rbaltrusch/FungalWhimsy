Timer = {}

function Timer.construct(delay)
    local timer = {time = 0, delay = delay, ongoing = false, expired = false}

    function timer.start(self)
        self.time = 0
        self.ongoing = true
        self.expired = false
    end

    function timer.stop(self)
        self.ongoing = false
    end

    function timer.update(self, dt)
        if not self.ongoing then
            return
        end

        self.time = self.time + dt
        if self.time >= self.delay then
            self.expired = true
        end
    end

    function timer.is_expired(self)
        return self.ongoing and self.expired
    end

    function timer.is_ongoing(self)
        return self.ongoing and not self.expired
    end

    return timer
end
