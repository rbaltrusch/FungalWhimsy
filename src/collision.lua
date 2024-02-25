Collision = {}

local function in_range(number, lower, upper)
    return number > lower and number < upper
end

function Collision.get_x_overlap(rect1, rect2)
    if rect1.x1 == rect2.x1 and rect1.x2 == rect2.x2 then
        return rect1.x2 - rect1.x1
    end

    if in_range(rect1.x1, rect2.x1, rect2.x2) then
        return rect1.x1 - rect2.x2
    end

    return rect1.x2 - rect2.x1
end

function Collision.get_y_overlap(rect1, rect2)
    if rect1.y1 == rect2.y1 and rect1.y2 == rect2.y2 then
        return rect1.y2 - rect1.y1
    end

    if in_range(rect1.y1, rect2.y1, rect2.y2) then
        return rect1.y1 - rect2.y2
    end

    return rect1.y2 - rect2.y1
end

local function colliding(rect1, rect2)
    return (
        (
            in_range(rect1.x1, rect2.x1, rect2.x2)
            or in_range(rect1.x2, rect2.x1, rect2.x2)
            or rect1.x1 == rect2.x1 and rect1.x2 >= rect2.x2
            or rect1.x1 <= rect2.x1 and rect1.x2 == rect2.x2
        )
        and (
            in_range(rect1.y1, rect2.y1, rect2.y2)
            or in_range(rect1.y2, rect2.y1, rect2.y2)
            or rect1.y1 == rect2.y1 and rect1.y2 >= rect2.y2
            or rect1.y1 <= rect2.y1 and rect1.y2 == rect2.y2
        )
    )
end

function Collision.colliding(rect1, rect2)
    return colliding(rect1, rect2) or colliding(rect2, rect1)
end
