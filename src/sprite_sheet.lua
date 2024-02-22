SpriteSheet = {}

function SpriteSheet.load_sprite_sheet(filepath, width, height, padding)
    local quads = {}
    local image = love.graphics.newImage(filepath)
    image:setFilter("nearest", "nearest")
    local _padding = padding or 0
    for y = 0, image:getHeight() - height, height + _padding do
        for x = 0, image:getWidth() - width, width + _padding do
            table.insert(quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end
    return {image = image, quads = quads, size = #quads}
end
