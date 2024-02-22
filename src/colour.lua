Colour = {}

local function saturate_colour(x)
    return math.max(0, math.min(255, x)) / 255
end

function Colour.construct(r, g, b, a)
    a = a ~= nil and a or 1
    return {saturate_colour(r), saturate_colour(g), saturate_colour(b), a}
end
