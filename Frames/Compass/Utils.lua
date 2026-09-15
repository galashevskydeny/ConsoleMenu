-- Utils.lua
-- Безопасное чтение скрытых значений карты и сбор записи точки.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass

-- Проверяет, скрыто ли значение клиентом.
function Compass.IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

-- Возвращает значение, если его можно читать.
function Compass.Readable(value)
    if not Compass.IsSecret(value) then
        return value
    end
end

-- Возвращает конечное число или ничего.
function Compass.Number(value)
    value = Compass.Readable(value)
    if type(value) == "number" and value == value and math.abs(value) < math.huge then
        return value
    end
end

-- Читает пару координат из таблицы положения.
function Compass.ReadPosition(position)
    position = Compass.Readable(position)
    if type(position) == "table" then
        return Compass.Number(position.x), Compass.Number(position.y)
    end
end

-- Проверяет, что координаты лежат на карте.
function Compass.IsMapPosition(position)
    local x, y = Compass.ReadPosition(position)
    return x ~= nil and y ~= nil and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

-- Добавляет точку на полосу, если у неё есть имя и координаты.
function Compass:AddMarker(markers, key, position, name, atlas, priority, kind, destination)
    local C = self.Constants
    local x, y = self.ReadPosition(position)
    name, atlas = self.Readable(name), self.Readable(atlas)
    if not x or not y or type(name) ~= "string" or name == "" then
        return
    end
    if type(atlas) ~= "string" or atlas == "" then
        atlas = C.FALLBACK_ATLAS
    end
    local marker = {
        key = key,
        x = x,
        y = y,
        name = name,
        atlas = atlas,
        sizeScale = C.MARKER_ATLAS_SCALES[atlas:lower()] or 1,
        priority = priority,
        kind = kind,
        destination = destination or { mapID = self.mapID, x = x, y = y },
    }
    markers[#markers + 1] = marker
    return marker
end
