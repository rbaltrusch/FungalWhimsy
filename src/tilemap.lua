TileMap = {}

function TileMap.get_tile_rect(x, y, tilesize)
    return {
        x1 = x * tilesize,
        x2 = (x + 1) * tilesize,
        y1 = y * tilesize,
        y2 = (y + 1) * tilesize,
    }
end

-- accepts tiles of a single layer
function TileMap.get_tile_rects(tiles, tilesize)
    local rects = {}
    for x, col in pairs(tiles) do
        for y, tile in pairs(col) do
            rects[{x, y}] = {tile = tile, rect = TileMap.get_tile_rect(x, y, tilesize)}
        end
    end
    return rects
end



-- returns zero-indexed 2d table of tiles
---@alias Tile {index: integer, quad: love.Quad}
---@alias layername string
---@return table<layername, {tiles: table<integer, table<integer, Tile>>}>
function TileMap.construct_tiles(tilemap, tileset)
    local layers = {}
    for _, layer in ipairs(tilemap.layers) do
        local name = layer.name
        layers[name] = {
            tiles = {},
            get = function(self, x, y)
                local tiles_x = self.tiles[x]
                return tiles_x ~= nil and tiles_x[y] or nil
            end,
        }
        for i = 0, tilemap.width do
            layers[name].tiles[i] = {}
        end
    end

    local width = tilemap.width
    for _, layer in ipairs(tilemap.layers) do
        local name = layer.name
        for i, tile_index in ipairs(layer.data) do
            -- skip empty tiles
            if tile_index == 0 then goto continue end
    
            i = i - 1
            local x = i % width
            local y = math.floor(i / width)
            layers[name].tiles[x][y] = {index=tile_index, quad=tileset.quads[tile_index]}
            ::continue::
        end
    end

    return layers
end

-- for use with luafinding a 2d table of bools (passable or not)
function TileMap.construct_collision_map(tilemap, layer_name)
    local tiles = {}
    local width = tilemap.width
    for _, layer in ipairs(tilemap.layers) do
        if layer.name ~= layer_name then goto continue end
        for i = 0, tilemap.width do
            tiles[i] = {}
        end
        for i, tile_index in ipairs(layer.data) do
            local x = i % width
            local y = math.floor(i / width)
            tiles[x][y] = tile_index == 0 --passable if empty
        end
        ::continue::
    end
    return tiles
end

-- offset is optional
function TileMap.render_tiles(tiles, tileset, camera, tilesize, width, height, y_offset)
    y_offset = y_offset or 0
    local tiles_min_x = camera.total_x / tilesize - 100
    local tiles_min_y = camera.total_y / tilesize - 100
    local tiles_max_x = (width + camera.total_x) / tilesize + 100
    local tiles_max_y = (height + camera.total_y) / tilesize + 100

    for x, col in pairs(tiles) do
        if x < tiles_min_x then goto continuex end
        if x > tiles_max_x then break end
        for y, tile in pairs(col) do
            if y < tiles_min_y or tile == nil then goto continuey end
            if y > tiles_max_y then break end
            local transform = love.math.newTransform(
                x * tilesize - camera.total_x, y * tilesize - camera.total_y + y_offset
            )
            love.graphics.draw(tileset.image, tile.quad, transform)
            ::continuey::
        end
        ::continuex::
    end
end

function TileMap.render(tiles, tileset, camera, tilesize, y_offset)
    y_offset = y_offset or 0
    for x, col in pairs(tiles) do
        for y, tile in pairs(col) do
            local transform = love.math.newTransform(
                x * tilesize - camera.total_x, y * tilesize - camera.total_y + y_offset
            )
            love.graphics.draw(tileset.image, tile.quad, transform)
            ::continue::
        end
    end
end
