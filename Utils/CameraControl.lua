-- CameraControl.lua
-- Подстраивает дистанцию камеры при входе в мир, посадке и спешивании.

local ConsoleMenu = _G.ConsoleMenu

-- Базовая дистанция в ярдах: пешком, на обычном средстве передвижения и в полёте на драконе.
local defaultZoom = {
    unmounted = 6,
    mount = 11,
    dragonriding = 10,
}

-- Максимальная дистанция камеры, которую допускает клиент.
local maxClientZoom = 39

-- Множитель, при котором достигается максимальная дистанция.
local maxZoomFactor = 2.6

-- Базовая дистанция, которую клиент умножает на множитель.
local baseMaxZoom = 15

-- Разница, меньше которой камеру не двигаем.
local zoomEpsilon = 0.05

-- Короткая пауза, пока журнал отметит активный маунт.
local mountJournalDelay = 0.1

-- Скорость зума на время нашей подстройки.
local applyZoomSpeed = 80

-- Пока идёт наша анимация, живое значение дистанции ещё старое.
local commandFlightTime = 0.35

-- Целевая дистанция камеры для спешенного персонажа: раса и тип тела.
-- Тип тела в игре — мужской или женский; более дробное сложение вне парикмахерской недоступно.
local raceZoom = {
    BloodElf = { male = 4.9, female = nil },
    DarkIronDwarf = { male = nil, female = nil },
    Dracthyr = { male = nil, female = nil },
    Draenei = { male = nil, female = nil },
    Dwarf = { male = nil, female = nil },
    Earthen = { male = nil, female = nil },
    EarthenDwarf = { male = nil, female = nil },
    Gnome = { male = nil, female = nil },
    Goblin = { male = nil, female = nil },
    HighmountainTauren = { male = 7.3, female = nil },
    Human = { male = nil, female = nil },
    KulTiran = { male = nil, female = nil },
    LightforgedDraenei = { male = nil, female = nil },
    MagharOrc = { male = nil, female = nil },
    Mechagnome = { male = nil, female = nil },
    Nightborne = { male = 4.9, female = nil },
    NightElf = { male = nil, female = nil },
    Orc = { male = nil, female = 4.5 },
    Pandaren = { male = 6, female = nil },
    Scourge = { male = 4.7, female = nil },
    Tauren = { male = 7.3, female = nil },
    Troll = { male = nil, female = nil },
    VoidElf = { male = nil, female = nil },
    Vulpera = { male = nil, female = nil },
    Worgen = { male = nil, female = nil },
    ZandalariTroll = { male = 5, female = nil },
}

-- Дистанция для конкретных средств передвижения: идентификатор журнала и русское имя в комментарии.
local mountZoom = {
    [2237] = 10.5,
    [2265] = 18.5,
    [2604] = 13.5,
    [2982] = 14.5,
}

-- Последняя заданная нами дистанция и отложенная подстройка после посадки.
local lastCommandedZoom
local lastCommandedAt = 0
local pendingApply

-- Возвращает истину, если автоматическая подстройка включена в настройках.
local function IsEnabled()
    return ConsoleMenuDB and ConsoleMenuDB.cameraControlEnable == 1
end

-- Возвращает английское имя расы персонажа.
local function GetPlayerRaceFile()
    local _, englishRaceName = UnitRace("player")
    return englishRaceName
end

-- Возвращает тип тела персонажа: мужской или женский.
local function GetPlayerBodyType()
    if UnitSexBase then
        local sex = UnitSexBase("player")
        if Enum and Enum.UnitSex then
            if sex == Enum.UnitSex.Male then
                return "male"
            end
            if sex == Enum.UnitSex.Female then
                return "female"
            end
        end
    end

    local sex = UnitSex("player")
    if sex == 2 then
        return "male"
    end
    if sex == 3 then
        return "female"
    end

    return nil
end

-- Возвращает дистанцию для расы и типа тела или пустое значение.
local function GetRaceZoom()
    local raceFile = GetPlayerRaceFile()
    if not raceFile then
        return nil
    end

    local entry = raceZoom[raceFile]
    if not entry then
        return nil
    end

    local bodyType = GetPlayerBodyType()
    if bodyType then
        return entry[bodyType]
    end

    return nil
end

-- Возвращает идентификатор активного средства передвижения или пустое значение.
local function GetActiveMountID()
    if not IsMounted() or not C_MountJournal or not C_MountJournal.GetMountIDs then
        return nil
    end

    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs then
        return nil
    end

    for index = 1, #mountIDs do
        local mountID = mountIDs[index]
        local _, _, _, isActive = C_MountJournal.GetMountInfoByID(mountID)
        if isActive then
            return mountID
        end
    end

    return nil
end

-- Возвращает истину, если персонаж на средстве передвижения с планированием.
local function IsDragonridingMounted()
    if not IsMounted() or not C_PlayerInfo or not C_PlayerInfo.GetGlidingInfo then
        return false
    end

    local _, canGlide = C_PlayerInfo.GetGlidingInfo()
    return canGlide and true or false
end

-- Выбирает целевую дистанцию по состоянию персонажа.
local function GetTargetZoom()
    if IsMounted() then
        local mountID = GetActiveMountID()
        if mountID and mountZoom[mountID] then
            return mountZoom[mountID]
        end

        if IsDragonridingMounted() then
            return defaultZoom.dragonriding
        end

        return defaultZoom.mount
    end

    local zoom = GetRaceZoom()
    if zoom then
        return zoom
    end

    return defaultZoom.unmounted
end

-- Поднимает потолок дистанции, если цель дальше текущего максимума.
local function EnsureMaxZoom(target)
    if target > maxClientZoom then
        target = maxClientZoom
    end

    local factor = tonumber(GetCVar("cameraDistanceMaxZoomFactor")) or 1.9
    local currentMax = math.min(baseMaxZoom * factor, maxClientZoom)
    if target <= currentMax then
        return target
    end

    local neededFactor = target / baseMaxZoom
    if neededFactor > maxZoomFactor then
        neededFactor = maxZoomFactor
    end

    SetCVar("cameraDistanceMaxZoomFactor", neededFactor)
    return math.min(target, maxClientZoom)
end

-- Берёт текущую дистанцию, не путая её с незавершённой нашей анимацией.
local function GetEffectiveZoom()
    local current = GetCameraZoom and GetCameraZoom() or nil
    if lastCommandedZoom and (GetTime() - lastCommandedAt) < commandFlightTime then
        if not current or math.abs(current - lastCommandedZoom) > zoomEpsilon then
            return lastCommandedZoom
        end
    end
    return current
end

-- Приближает или отдаляет камеру до целевой дистанции.
local function SetWorldCameraZoom(target)
    if not CameraZoomIn or not CameraZoomOut then
        return
    end

    target = EnsureMaxZoom(target)
    local current = GetEffectiveZoom()
    if not current then
        return
    end

    local delta = current - target
    lastCommandedZoom = target
    lastCommandedAt = GetTime()
    if math.abs(delta) <= zoomEpsilon then
        return
    end

    local previousSpeed = GetCVar("cameraZoomSpeed")
    SetCVar("cameraZoomSpeed", applyZoomSpeed)
    if delta > 0 then
        CameraZoomIn(delta)
    else
        CameraZoomOut(-delta)
    end
    SetCVar("cameraZoomSpeed", previousSpeed)
end

-- Применяет дистанцию камеры под текущее состояние персонажа.
function ConsoleMenu:ApplyCameraZoom()
    if not IsEnabled() then
        return
    end

    SetWorldCameraZoom(GetTargetZoom())
end

-- Останавливает отложенную подстройку.
local function StopPendingApply()
    if pendingApply then
        pendingApply:Cancel()
        pendingApply = nil
    end
end

-- Применяет зум сразу или чуть позже, если журнал ещё не отметил маунт.
local function ScheduleApply()
    if not IsEnabled() then
        return
    end

    StopPendingApply()

    if IsMounted() and not GetActiveMountID() then
        pendingApply = C_Timer.NewTimer(mountJournalDelay, function()
            pendingApply = nil
            ConsoleMenu:ApplyCameraZoom()
        end)
        return
    end

    ConsoleMenu:ApplyCameraZoom()
end

-- Подписывается на вход в мир и смену средства передвижения.
function ConsoleMenu:InitializeCameraControl()
    if not self.CameraControlFrame then
        self.CameraControlFrame = CreateFrame("Frame")
    end

    local frame = self.CameraControlFrame
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:SetScript("OnEvent", function()
        ScheduleApply()
    end)

    if IsLoggedIn and IsLoggedIn() then
        ScheduleApply()
    end
end

-- Печатает текущую дистанцию камеры и идентификатор маунта, если персонаж сидит.
SLASH_CONSOLEMENUZOOM1 = "/cmzoom"
SlashCmdList["CONSOLEMENUZOOM"] = function()
    local zoom = GetCameraZoom and GetCameraZoom() or nil
    local mountID = GetActiveMountID()
    if mountID then
        local name = C_MountJournal.GetMountInfoByID(mountID)
        print("Зум:", zoom, "Маунт:", mountID, name)
        return
    end

    print("Зум:", zoom)
end
