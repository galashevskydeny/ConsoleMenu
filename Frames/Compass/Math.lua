-- Math.lua
-- Расчёт азимута и проекции точки на полосу.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass

-- Нормализует угол в диапазон от минус 180 до 180.
function Compass:WrapDegrees(degrees)
    local C = self.Constants
    return (degrees + C.HALF_TURN) % C.FULL_TURN - C.HALF_TURN
end

-- Возвращает азимут и расстояние по смещению на восток и север.
function Compass:Bearing(east, north, distanceSquared)
    local distance = math.sqrt(distanceSquared)
    if distance == 0 then
        return nil, distance
    end
    return math.deg(math.atan2(-east, north)), distance
end

-- Проецирует азимут на полосу относительно направления взгляда.
function Compass:Project(bearing, facing, viewAngle, width, clipFraction)
    local C = self.Constants
    local delta = self:WrapDegrees(facing - bearing)
    local hideAt = 1 - (clipFraction or 0)
    local halfView = viewAngle / 2
    if math.abs(delta) > halfView * hideAt then
        return nil, nil, delta
    end
    local fraction = delta / halfView
    local alpha = math.min(1, (hideAt - math.abs(fraction)) / C.EDGE_FADE_FRACTION)
    return fraction * width / 2, alpha, delta
end
