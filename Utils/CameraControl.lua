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

-- Короткая пауза между попытками дождаться записи маунта в журнале.
local mountJournalDelay = 0.1

-- Сколько раз спрашивать журнал, прежде чем взять общий зум маунта.
local mountJournalAttempts = 5

-- Скорость зума на время нашей подстройки.
local applyZoomSpeed = 80

-- Сколько держать повышенную скорость, пока камера доезжает.
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

-- Приращение дистанции на маунте относительно пешего пандарена-мужчины, на котором снимались значения.
local mountZoomDelta = {
    [2237] = 4.5,
    [2265] = 11.5,
    [2604] = 7.5,
    [2982] = 8.5,
}

-- Отложенная подстройка, сохранённые настройки клиента и регистрация слэш-команды.
local pendingApply
local savedMaxZoomFactor
local savedZoomSpeed
local restoreSpeedTimer
local zoomSlashRegistered

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

-- Возвращает дистанцию пешком для текущей расы и типа тела.
local function GetUnmountedZoom()
    return GetRaceZoom() or defaultZoom.unmounted
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

    for _, mountID in ipairs(mountIDs) do
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
        if mountID and mountZoomDelta[mountID] then
            return GetUnmountedZoom() + mountZoomDelta[mountID]
        end

        if IsDragonridingMounted() then
            return defaultZoom.dragonriding
        end

        return defaultZoom.mount
    end

    return GetUnmountedZoom()
end

-- Максимальная дистанция при данном множителе.
local function MaxDistanceForFactor(factor)
    return math.min(baseMaxZoom * factor, maxClientZoom)
end

-- Поднимает потолок дистанции на время дальней цели и возвращает его, когда цель снова ближе.
local function EnsureMaxZoom(target)
    if target > maxClientZoom then
        target = maxClientZoom
    end

    local currentFactor = tonumber(GetCVar("cameraDistanceMaxZoomFactor")) or 1.9
    local originalFactor = tonumber(savedMaxZoomFactor) or currentFactor
    local originalMax = MaxDistanceForFactor(originalFactor)

    if target <= originalMax then
        if savedMaxZoomFactor then
            SetCVar("cameraDistanceMaxZoomFactor", savedMaxZoomFactor)
            savedMaxZoomFactor = nil
        end
        return target
    end

    if not savedMaxZoomFactor then
        savedMaxZoomFactor = GetCVar("cameraDistanceMaxZoomFactor")
    end

    local neededFactor = target / baseMaxZoom
    if neededFactor > maxZoomFactor then
        neededFactor = maxZoomFactor
    end
    if neededFactor > currentFactor then
        SetCVar("cameraDistanceMaxZoomFactor", neededFactor)
    end

    return math.min(target, maxClientZoom)
end

-- Возвращает скорость зума к значению игрока.
local function RestoreZoomSpeed()
    restoreSpeedTimer = nil
    if savedZoomSpeed then
        SetCVar("cameraZoomSpeed", savedZoomSpeed)
        savedZoomSpeed = nil
    end
end

-- Приближает или отдаляет камеру до целевой дистанции.
local function SetWorldCameraZoom(target)
    if not GetCameraZoom or not CameraZoomIn or not CameraZoomOut then
        return
    end

    target = EnsureMaxZoom(target)
    local current = GetCameraZoom()
    if not current then
        return
    end

    local delta = current - target
    if math.abs(delta) <= zoomEpsilon then
        return
    end

    if not savedZoomSpeed then
        savedZoomSpeed = GetCVar("cameraZoomSpeed")
    end
    SetCVar("cameraZoomSpeed", applyZoomSpeed)
    if delta > 0 then
        CameraZoomIn(delta)
    else
        CameraZoomOut(-delta)
    end

    if restoreSpeedTimer then
        restoreSpeedTimer:Cancel()
    end
    restoreSpeedTimer = C_Timer.NewTimer(commandFlightTime, RestoreZoomSpeed)
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

-- Печатает текущую дистанцию камеры и идентификатор маунта, если персонаж сидит.
local function PrintZoomInfo()
    local zoom = GetCameraZoom and GetCameraZoom() or nil
    local mountID = GetActiveMountID()
    if mountID then
        local name = C_MountJournal.GetMountInfoByID(mountID)
        print("Зум:", zoom, "Маунт:", mountID, name)
        return
    end

    print("Зум:", zoom)
end

-- Включает отладочную слэш-команду.
local function RegisterZoomSlash()
    if zoomSlashRegistered then
        return
    end

    SLASH_CONSOLEMENUZOOM1 = "/cmzoom"
    SlashCmdList["CONSOLEMENUZOOM"] = PrintZoomInfo
    zoomSlashRegistered = true
end

-- Выключает отладочную слэш-команду.
local function UnregisterZoomSlash()
    if not zoomSlashRegistered then
        return
    end

    SlashCmdList["CONSOLEMENUZOOM"] = nil
    SLASH_CONSOLEMENUZOOM1 = nil
    zoomSlashRegistered = false
end

-- Возвращает изменённые настройки камеры к значениям игрока.
local function RestoreClientCameraSettings()
    StopPendingApply()
    if restoreSpeedTimer then
        restoreSpeedTimer:Cancel()
        restoreSpeedTimer = nil
    end
    RestoreZoomSpeed()
    if savedMaxZoomFactor then
        SetCVar("cameraDistanceMaxZoomFactor", savedMaxZoomFactor)
        savedMaxZoomFactor = nil
    end
end

-- Применяет зум сразу или после нескольких попыток дождаться журнала маунтов.
local function ScheduleApply()
    if not IsEnabled() then
        return
    end

    StopPendingApply()

    local attempts = 0
    local function TryApply()
        pendingApply = nil

        if IsMounted() and not GetActiveMountID() and attempts < mountJournalAttempts then
            attempts = attempts + 1
            pendingApply = C_Timer.NewTimer(mountJournalDelay, TryApply)
            return
        end

        ConsoleMenu:ApplyCameraZoom()
    end

    TryApply()
end

-- Включает или выключает автоматическую подстройку после смены настройки.
function ConsoleMenu:OnCameraControlSettingChanged(enabled)
    if enabled then
        RegisterZoomSlash()
        ScheduleApply()
        return
    end

    UnregisterZoomSlash()
    RestoreClientCameraSettings()
end

-- Подписывается на вход в мир и смену средства передвижения.
function ConsoleMenu:InitializeCameraControl()
    if not self.CameraControlFrame then
        self.CameraControlFrame = CreateFrame("Frame")
    end

    local frame = self.CameraControlFrame
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            local isInitialLogin, isReloadingUi = ...
            if isInitialLogin or isReloadingUi then
                ScheduleApply()
            end
            return
        end

        if event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
            ScheduleApply()
        end
    end)

    if IsEnabled() then
        RegisterZoomSlash()
    end
end
