MathUtil = {}

function MathUtil.round(num)
    return num + (2^52 + 2^51) - (2^52 + 2^51)
end

function MathUtil.dist(point1, point2)
    local x1, y1 = unpack(point1)
    local x2, y2 = unpack(point2)
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end
