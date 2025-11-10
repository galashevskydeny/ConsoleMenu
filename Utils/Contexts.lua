-- Contexts.lua

local ConsoleMenu = _G.ConsoleMenu

-- Набор функций для обновления контекста
local function UpdatePlayerAlive()
    ConsoleMenu.PlayerContext.alive = not UnitIsDead("player") or true
end

local function UpdatePlayerInCombat()
    ConsoleMenu.PlayerContext.inCombat = UnitAffectingCombat("player") or false
end

local function UpdatePlayerMount()
    if UnitPowerBarID("player") == 631 then
        ConsoleMenu.PlayerContext.mount = 2
    elseif IsMounted() then
        ConsoleMenu.PlayerContext.mount = 1
    else
        ConsoleMenu.PlayerContext.mount = 0
    end 
end

local function UpdatePlayerVehicle()
    ConsoleMenu.PlayerContext.vehicle = UnitInVehicle('player') or UnitOnTaxi('player') or false
end

local function UpdatePlayerTarget()
    if not UnitExists("target") then
        ConsoleMenu.PlayerContext.target = {}
    elseif UnitCanAttack("player", "target") then
        ConsoleMenu.PlayerContext.target.isPlayer = UnitIsPlayer("target")
        ConsoleMenu.PlayerContext.target.canAttack = true
        ConsoleMenu.PlayerContext.target.isEnemy = UnitIsEnemy("player", "target")
        ConsoleMenu.PlayerContext.target.isFriend = UnitIsFriend("player", "target")
        ConsoleMenu.PlayerContext.target.canAssist = UnitCanAssist("player", "target")
    end
end

local function UpdatePlayerSoftEnemy()
    if not UnitExists("softenemy") then
        ConsoleMenu.PlayerContext.softenemy = {}
    elseif UnitCanAttack("player", "softenemy") then
        ConsoleMenu.PlayerContext.softenemy.isPlayer = UnitIsPlayer("softenemy")
        ConsoleMenu.PlayerContext.softenemy.canAttack = UnitCanAttack("player", "softenemy")
    end
end

local function UpdatePlayerSoftFriend()
    if not UnitExists("softfriend") then
        ConsoleMenu.PlayerContext.softfriend = {}
    elseif UnitCanAssist("player", "softfriend") then
        ConsoleMenu.PlayerContext.softfriend.isPlayer = UnitIsPlayer("softfriend")
        ConsoleMenu.PlayerContext.softfriend.canAssist = UnitCanAssist("player", "softfriend")
    end
end

-- Работа с хэш-таблицей для отслеживания открытых окон
function ConsoleMenu:AddWindow(type)
    if not self.PlayerContext or not self.PlayerContext.window then
        return
    end
    self.PlayerContext.window[type] = true
end

function ConsoleMenu:RemoveWindow(type)
    if not self.PlayerContext or not self.PlayerContext.window then
        return
    end
    self.PlayerContext.window[type] = nil
end

function ConsoleMenu:HasWindows()
    if not self.PlayerContext or not self.PlayerContext.window then
        return false
    end
    for _ in pairs(self.PlayerContext.window) do
        return true
    end
    return false
end

-- Функция получения контекста
function ConsoleMenu:GetPlayerContext()

    local context = "exploring"

    if self:HasWindows() then
        context = "window"
    elseif ConsoleMenu.PlayerContext.alive == false then
        context = "soul"
    elseif ConsoleMenu.PlayerContext.inCombat == true
       and ConsoleMenu.PlayerContext.mount == 0
       and ConsoleMenu.PlayerContext.vehicle == false
    then
        context = "combat"
    elseif ConsoleMenu.PlayerContext.inCombat == false
       and ConsoleMenu.PlayerContext.mount == 0
       and ConsoleMenu.PlayerContext.vehicle == false
       and (ConsoleMenu.PlayerContext.softenemy.canAttack == true or ConsoleMenu.PlayerContext.target.canAttack == true)
    then
        context = "precombat"
    elseif ConsoleMenu.PlayerContext.mount == 1 or ConsoleMenu.PlayerContext.mount == 2 then
        context = "mount"
    end

    ConsoleMenu.PlayerContext.lastContext = context
    return context
end

-- Функция переключения страниц панели действий
local function SwitchActionBarPage()
    if ConsoleMenuDB and ConsoleMenuDB.actionBarPageSwitching == 2 then
        return
    end

    if ConsoleMenu.PlayerContext.inCombat == true
       and ConsoleMenu.PlayerContext.vehicle == false
    then
        ChangeActionBarPage(1)
    elseif ConsoleMenu.PlayerContext.inCombat == false
       and ConsoleMenu.PlayerContext.mount == 0
       and ConsoleMenu.PlayerContext.vehicle == false
       and (ConsoleMenu.PlayerContext.softenemy.canAttack == true or ConsoleMenu.PlayerContext.target.canAttack == true)
    then
        ChangeActionBarPage(1)
    elseif ConsoleMenu.PlayerContext.mount == 1 and ConsoleMenu.PlayerContext.inCombat == false then
        -- Обычное средство передвижения
        ChangeActionBarPage(4)
    elseif ConsoleMenu.PlayerContext.mount == 2 then
        -- Полет на драконе
        ChangeActionBarPage(1)
    elseif ConsoleMenu.PlayerContext.inCombat == false
        and ConsoleMenu.PlayerContext.vehicle == false
        and (ConsoleMenu.PlayerContext.softfriend.isPlayer == true or ConsoleMenu.PlayerContext.target.isFriend == true)
    then
        -- Друг в фокусе
        ChangeActionBarPage(3)
    else
        -- Исследование
        ChangeActionBarPage(2)
    end
end

-- Функция инициализации контекстов
function ConsoleMenu:InitializeContexts()
    if not self.ContextsFrame then
        self.ContextsFrame = CreateFrame("Frame")
    end

    self.ContextsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    -- Отслеживание целей и soft-target
    self.ContextsFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
    self.ContextsFrame:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
    self.ContextsFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

    -- Отслеживание входа/выхода из боя
    self.ContextsFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.ContextsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Для отслежтвания полетов на драконе
    self.ContextsFrame:RegisterEvent("UNIT_POWER_BAR_SHOW")
    self.ContextsFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE")
    -- Для отслеживания средств передвижения (не только полеты на драконах)
    self.ContextsFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")


    --  Для отслеживания транспорта
    self.ContextsFrame:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA")
    self.ContextsFrame:RegisterEvent("PLAYER_GAINS_VEHICLE_DATA")

    -- Отслеживание смерти и воскрешения
    self.ContextsFrame:RegisterEvent("PLAYER_DEAD")
    self.ContextsFrame:RegisterEvent("PLAYER_ALIVE")
    self.ContextsFrame:RegisterEvent("PLAYER_UNGHOST")

    -- Отслеживание открытия/закрытия окна интерфейса
    self.ContextsFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    self.ContextsFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")

    ConsoleMenu.PlayerContext = {
        -- Жив ли персонаж
        alive = nil,

        -- Режим боя
        inCombat = nil,

        -- Средство передвижения: 0 = не на средстве передвижения, 1 = обычное средство, 2 = полет на драконе
        mount = nil,

        -- Транспорт:
        vehicle = nil,

        -- Враг и союзник
        enemy = {},
        friend = {},
        target = {},

        -- Наличие окна интерфейса (хеш-таблица для быстрого доступа)
        window = {},

        -- Последний контекст
        lastContext = nil,
    }

    self.ContextsFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            UpdatePlayerAlive()
            UpdatePlayerInCombat()
            UpdatePlayerSoftEnemy()
            UpdatePlayerSoftFriend()
            UpdatePlayerTarget()

            C_Timer.After(1, function()
                UpdatePlayerMount()
                UpdatePlayerVehicle()
                local context = ConsoleMenu:GetPlayerContext()
                if WeakAuras then
                    WeakAuras.ScanEvents("CHANGE_CONTEXT", context)
                end
                SwitchActionBarPage()
            end)
        elseif event == "PLAYER_SOFT_ENEMY_CHANGED" then
            UpdatePlayerSoftEnemy()
        elseif event == "PLAYER_SOFT_FRIEND_CHANGED" then
            UpdatePlayerSoftFriend()
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdatePlayerTarget()
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            UpdatePlayerInCombat()
        elseif event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
            UpdatePlayerMount()
        elseif event == "PLAYER_LOSES_VEHICLE_DATA" or event == "PLAYER_GAINS_VEHICLE_DATA" then
            UpdatePlayerVehicle()
        elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
            UpdatePlayerAlive()
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
            ConsoleMenu:AddWindow(...)
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
            ConsoleMenu:RemoveWindow(...)
        end

        if 
        local context = ConsoleMenu:GetPlayerContext()
        if WeakAuras then
            WeakAuras.ScanEvents("CHANGE_CONTEXT", context)
        end

        SwitchActionBarPage()
    end)
    
    
end
