SoundCollection = {}

math.randomseed(os.time())

---@param sounds love.Source[]
function SoundCollection.construct(sounds)
    return {
        sounds = sounds,
        current_sound = nil,
        play = SoundCollection.play,
        stop = SoundCollection.stop,
    }
end

function SoundCollection.play(self)
    self:stop()
    local index = math.random(1, #self.sounds)
    self.sounds[index]:play()
end

function SoundCollection.stop(self)
    if self.current_sound then
        self.current_sound:stop()
    end
end

function SoundCollection.isPlaying(self)
    if self.current_sound then
        return self.current_sound:isPlaying()
    end
    return false
end
