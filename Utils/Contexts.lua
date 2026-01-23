-- Contexts.lua

local ConsoleMenu = _G.ConsoleMenu
local gliding = false

-- Список заклинаний, которые требуют находится в воздухе для использования
local spellsNeedGliding = {
    [372608] = true,
    [361584] = true,
    [403092] = true,
}

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
    if not UnitExists("target") or UnitIsDead("target") then
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
    
    for i, window in pairs(self.PlayerContext.window) do
        if i ~= type then
            self.PlayerContext.window[i] = nil
        end
    end
end

function ConsoleMenu:RemoveWindow(type)
    if not self.PlayerContext or not self.PlayerContext.window then
        return
    end

    if type == 0 then
        for type, window in pairs(self.PlayerContext.window) do
            self.PlayerContext.window[type] = nil
        end
    else
        self.PlayerContext.window[type] = nil
    end

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
    
    if InCombatLockdown and InCombatLockdown() then
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
        if PlayerIsInCombat() then
            ChangeActionBarPage(1)
        else
            ChangeActionBarPage(2)
        end
    end
end

function ConsoleMenu:ApplyContextUIChanges()

    local context = ConsoleMenu:GetPlayerContext()
    ConsoleMenu:ResetKeysItems()

    if context == "exploring" then
        local page = GetActionBarPage()
        local startSlot = 12 * (page - 1) + 1
        local lastSlot = startSlot + 11

        for slot = startSlot, lastSlot do
            local actionType, id, subType = GetActionInfo(slot)
            local command = ConsoleMenu:GetBindingCommandBySlotID(slot)
            local isUsable, isLackingResources = C_ActionBar.IsUsableAction(slot)
            local count = C_ActionBar.GetActionDisplayCount(slot)

            if actionType and id and command then
                local title = ConsoleMenu:GetSlotTitle(actionType, id)
                local binding = ConsoleMenu:GetCommandBinding(command)

                if title and binding and isUsable then
                    ConsoleMenu:AddKeysFrameItem(binding, title, count)
                end
            end
        end

        if UnitExists("softinteract") then
            ConsoleMenu:SetInteractBinding("softinteract")
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)

    elseif context == "window" then

        if ConsoleMenu.PlayerContext.window[3] or ConsoleMenu.PlayerContext.window[4] then
            ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
            ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")

            if ConsoleMenuFrame.SubtitleFrame.CurrentSubtitle and ConsoleMenuFrame.SubtitleFrame.CurrentSubtitle.lastLine == false then
                ConsoleMenu:AddKeysFrameItem("PAD4", "Пропустить")
            end

            ConsoleMenu:HideChatFrame()
        elseif ConsoleMenu.PlayerContext.window["fasttravel"] then
            ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
            ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")
            ConsoleMenu:AddKeysFrameItem("PADDLEFTRIGHT", "Переключение вкладок")

            ConsoleMenu:HideChatFrame()
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
    elseif context == "mount" then
        local page = 4

        if GetActionBarPage() ~= 4 then
            page = 11
        end

        local startSlot = 12 * (page - 1) + 1
        local lastSlot = startSlot + 11

        for slot = startSlot, lastSlot do
            local actionType, id, subType = GetActionInfo(slot)
            local command = ConsoleMenu:GetBindingCommandBySlotID(slot)

            local isUsable, isLackingResources = C_ActionBar.IsUsableAction(slot)
            local count = C_ActionBar.GetActionDisplayCount(slot)
            local spellId = C_ActionBar.GetSpell(slot)
            local cooldownInfo = C_ActionBar.GetActionCooldown(slot)

            -- Подмена привязки взлета вверх на прыжок 
            if spellId == 372610 then command = "JUMP" end

            -- Проверяем кулдаун из cooldownInfo
            local isOnCooldown = false

            -- Проверяем, нужно ли показывать заклинание
            local shouldShow = false
            if isOnCooldown then
                -- Заклинание на кулдауне - не показываем
                shouldShow = false
            elseif spellId == 0 then
                -- Не заклинание (макрос или пустой слот)
                shouldShow = not gliding
            elseif spellsNeedGliding[spellId] then
                -- Заклинание требует планирования - показываем только если планируем
                shouldShow = (gliding == true)
            else
                -- Обычное заклинание - показываем всегда
                shouldShow = true
            end

            if shouldShow then
                if actionType and id and command and isUsable then
                    local actionType, id, subType = GetActionInfo(slot)
                    local title = ConsoleMenu:GetSlotTitle(actionType, id)
                    local binding = ConsoleMenu:GetCommandBinding(command)
    
                    if title and binding then
                        ConsoleMenu:AddKeysFrameItem(binding, title, count)
                    end
                end
            end
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
    elseif context == "combat" or context == "precombat" then
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.ActionBarFrame)
    end

    ConsoleMenu:UpdateKeysFrame()
end

-- Функция инициализации контекстов
function ConsoleMenu:InitializeContexts()
    if not self.ContextsFrame then
        self.ContextsFrame = CreateFrame("Frame")
    end

    self.ContextsFrame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    self.ContextsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.ContextsFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")

    -- Отслеживание целей и soft-target
    self.ContextsFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
    self.ContextsFrame:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
    self.ContextsFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

    -- Отслеживание входа/выхода из боя
    self.ContextsFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.ContextsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Для отслеживания средств передвижения
    self.ContextsFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self.ContextsFrame:RegisterEvent("UNIT_POWER_BAR_SHOW")
    self.ContextsFrame:RegisterEvent("UNIT_POWER_BAR_HIDE")
    -- Для отслеживания полетов
    self.ContextsFrame:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")

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

    -- Отслеживание изменения пригодности к использованию и количества зарядов заклинаний
    self.ContextsFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    self.ContextsFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    self.ContextsFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    self.ContextsFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self.ContextsFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    self.ContextsFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

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
        elseif event == "PLAYER_IS_GLIDING_CHANGED" then
            gliding = ...
        end

        ConsoleMenu:ApplyContextUIChanges()  

        SwitchActionBarPage()
    end)
    
end
