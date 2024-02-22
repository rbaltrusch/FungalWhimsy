SpriteSheet = {}

function SpriteSheet.load_sprite_sheet(filepath, width, height)
    local quads = {}
    local image = love.graphics.newImage(filepath)
    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end
    return {image = image, quads = quads, size = #quads}
end
