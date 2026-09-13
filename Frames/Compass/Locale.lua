-- Locale.lua
-- Подписи сторон света, типов точек и сообщений полосы.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass

-- Тексты для русского и английского клиента.
local STRINGS = {
    ruRU = {
        N = "С",
        W = "З",
        S = "Ю",
        E = "В",
        METERS_F = "%d м",
        DETAIL_F = "%s, %s",
        WAYPOINT = "Путевая точка",
        CORPSE = "Возвращение к телу",
        CHOOSE_POINT = "Выберите точку для отслеживания",
        OVERLAP_HINT_F = "Здесь %d точек. Нажмите, чтобы выбрать точку для отслеживания.",
        WAYPOINT_INVALID = "Неверные координаты точки.",
        WAYPOINT_UNAVAILABLE = "На этой карте нельзя поставить путевую точку.",
        quest = "Задание",
        worldQuest = "Локальное задание",
        treasure = "Сокровище",
        rare = "Редкий противник",
        rareElite = "Редкий элитный противник",
        worldBoss = "Мировой босс",
        flightMaster = "Распорядитель полетов",
        event = "Событие",
        race = "Воздушная гонка",
        questHub = "Центр заданий",
        delve = "Вылазка",
        poi = "Точка интереса",
        waypoint = "Путевая точка",
        directions = "Указания стражников",
        mapLink = "Транспортные переходы",
        petTamer = "Укротители питомцев",
        digSite = "Места раскопок",
        content = "Отслеживаемые предметы коллекции",
        questOffer = "Доступные задания",
        corpse = "Возвращение к телу",
        party = "Участники группы",
        graveyard = "Кладбище",
        flag = "Флаг",
        vehicle = "Техника",
        FLAG = "Флаг",
    },
    enUS = {
        N = "N",
        W = "W",
        S = "S",
        E = "E",
        METERS_F = "%d m",
        DETAIL_F = "%s, %s",
        WAYPOINT = "Waypoint",
        CORPSE = "Corpse Recovery",
        CHOOSE_POINT = "Choose a point to track",
        OVERLAP_HINT_F = "%d points here. Click to choose which to track.",
        WAYPOINT_INVALID = "Invalid location.",
        WAYPOINT_UNAVAILABLE = "Waypoints are unavailable on that map.",
        quest = "Quest",
        worldQuest = "World Quest",
        treasure = "Treasure",
        rare = "Rare",
        rareElite = "Rare Elite",
        worldBoss = "World Boss",
        flightMaster = "Flight Master",
        event = "Event",
        race = "Skyriding Race",
        questHub = "Quest Hub",
        delve = "Delve",
        poi = "Point of Interest",
        waypoint = "Waypoint",
        directions = "Guard Directions",
        mapLink = "Travel Connections",
        petTamer = "Pet Tamers",
        digSite = "Archaeology Dig Sites",
        content = "Tracked Collectibles",
        questOffer = "Available Quests",
        corpse = "Corpse Recovery",
        party = "Group Members",
        graveyard = "Graveyard",
        flag = "Flag",
        vehicle = "Vehicle",
        FLAG = "Flag",
    },
}

-- Выбирает набор строк по языку клиента.
function Compass:InitLocale()
    local locale = GetLocale()
    self.L = STRINGS[locale] or STRINGS.enUS
end

-- Возвращает расстояние в метрах для подписи.
function Compass:DisplayDistance(yards)
    local C = self.Constants
    return math.floor((yards or 0) * C.METERS_PER_YARD + 0.5)
end

-- Собирает строку расстояния в метрах.
function Compass:FormatDistance(yards)
    return self.L.METERS_F:format(self:DisplayDistance(yards))
end
