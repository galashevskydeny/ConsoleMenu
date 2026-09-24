-- Waypoint.lua
-- Команда чата для путевой точки по координатам текущей карты.

local ConsoleMenu = _G.ConsoleMenu

-- Достаёт два числа из текста команды и переводит их в доли карты.
local function ParseCoordinates(message)
    local numbers = {}
    for token in string.gmatch(message or "", "%d+%.?%d*") do
        numbers[#numbers + 1] = tonumber(token)
        if #numbers > 2 then
            return nil
        end
    end

    if #numbers ~= 2 then
        return nil
    end

    local x, y = numbers[1], numbers[2]
    if not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then
        return nil
    end

    return x / 100, y / 100
end

-- Ставит путевую точку на карте игрока и включает её отслеживание.
local function SetWayCommand(message)
    local compass = ConsoleMenu.Compass
    local x, y = ParseCoordinates(message)
    if not x or not compass then
        print("Укажите координаты: /way 69.25, 43.95")
        return
    end

    local mapID = compass.Number(C_Map.GetBestMapForUnit("player"))
    if not mapID then
        print("Не удалось определить текущую карту.")
        return
    end

    if not compass.L and compass.InitLocale then
        compass:InitLocale()
    end

    local success, reason = compass:SetWaypoint(mapID, x, y)
    if not success then
        print(reason or "Не удалось поставить путевую точку.")
    end
end

-- Команда: /way 69.25, 43.95
SLASH_CONSOLEMENUWAY1 = "/way"
SlashCmdList["CONSOLEMENUWAY"] = SetWayCommand
