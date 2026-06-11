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
    ConsoleMenuFrame.PlayerContext.alive = not UnitIsDead("player") or true
end

local function UpdatePlayerInCombat()
    ConsoleMenuFrame.PlayerContext.inCombat = UnitAffectingCombat("player") or false
end

local function UpdatePlayerMount()
    local _, canGlide, _ = C_PlayerInfo.GetGlidingInfo()
    if IsMounted() and canGlide then
        ConsoleMenuFrame.PlayerContext.mount = 2
    elseif IsMounted() and not canGlide then
        ConsoleMenuFrame.PlayerContext.mount = 1
    else
        ConsoleMenuFrame.PlayerContext.mount = 0
    end 
end

local function UpdatePlayerVehicle()
    ConsoleMenuFrame.PlayerContext.vehicle = UnitInVehicle('player') or UnitOnTaxi('player')
end

local function UpdatePlayerTarget()
    if not UnitExists("target") or UnitIsDead("target") then
        ConsoleMenuFrame.PlayerContext.target = {}
    elseif UnitCanAttack("player", "target") then
        ConsoleMenuFrame.PlayerContext.target.isPlayer = UnitIsPlayer("target")
        ConsoleMenuFrame.PlayerContext.target.canAttack = true
        ConsoleMenuFrame.PlayerContext.target.isEnemy = UnitIsEnemy("player", "target")
        ConsoleMenuFrame.PlayerContext.target.isFriend = UnitIsFriend("player", "target")
        ConsoleMenuFrame.PlayerContext.target.canAssist = UnitCanAssist("player", "target")
    end
end

local function UpdatePlayerSoftEnemy()
    if not UnitExists("softenemy") then
        ConsoleMenuFrame.PlayerContext.softenemy = {}
    elseif UnitCanAttack("player", "softenemy") then
        ConsoleMenuFrame.PlayerContext.softenemy.isPlayer = UnitIsPlayer("softenemy")
        ConsoleMenuFrame.PlayerContext.softenemy.canAttack = UnitCanAttack("player", "softenemy")
    end
end

local function UpdatePlayerSoftFriend()
    if not UnitExists("softfriend") then
        ConsoleMenuFrame.PlayerContext.softfriend = {}
    elseif UnitCanAssist("player", "softfriend") then
        ConsoleMenuFrame.PlayerContext.softfriend.isPlayer = UnitIsPlayer("softfriend")
        ConsoleMenuFrame.PlayerContext.softfriend.canAssist = UnitCanAssist("player", "softfriend")
    end
end

local function UpdatePlayerIsInsideHouseOrPlot()
    ConsoleMenuFrame.PlayerContext.housing.IsInsidePlot = C_Housing.IsInsidePlot()
    ConsoleMenuFrame.PlayerContext.housing.IsInsideHouse = C_Housing.IsInsideHouse()
    ConsoleMenuFrame.PlayerContext.housing.currentEditMode = C_HouseEditor.GetActiveHouseEditorMode()
end

-- Работа с хэш-таблицей для отслеживания открытых окон
function ConsoleMenu:AddWindow(type)
    if not ConsoleMenuFrame.PlayerContext or not ConsoleMenuFrame.PlayerContext.window then
        return
    end
    
    ConsoleMenuFrame.PlayerContext.window[type] = true
    
    for i, window in pairs(ConsoleMenuFrame.PlayerContext.window) do
        if i ~= type then
            ConsoleMenuFrame.PlayerContext.window[i] = nil
        end
    end
end

function ConsoleMenu:RemoveWindow(type)
    if not ConsoleMenuFrame.PlayerContext or not ConsoleMenuFrame.PlayerContext.window then
        return
    end

    if type == 0 then
        for type, window in pairs(ConsoleMenuFrame.PlayerContext.window) do
            ConsoleMenuFrame.PlayerContext.window[type] = nil
        end
    else
        ConsoleMenuFrame.PlayerContext.window[type] = nil
    end

end

function ConsoleMenu:HasWindows()
    if not ConsoleMenuFrame.PlayerContext or not ConsoleMenuFrame.PlayerContext.window then
        return false
    end
    for _ in pairs(ConsoleMenuFrame.PlayerContext.window) do
        return true
    end
    return false
end

-- Функция получения контекста
function ConsoleMenu:GetPlayerContext()

    local context = "exploring"

    if self:HasWindows() then
        context = "window"
    elseif ConsoleMenuFrame.PlayerContext.alive == false then
        context = "soul"
    elseif ConsoleMenuFrame.PlayerContext.inCombat == true
       and ConsoleMenuFrame.PlayerContext.mount == 0
       and ConsoleMenuFrame.PlayerContext.vehicle == false
    then
        context = "combat"
    elseif ConsoleMenuFrame.PlayerContext.inCombat == false
       and ConsoleMenuFrame.PlayerContext.mount == 0
       and ConsoleMenuFrame.PlayerContext.vehicle == false
       and (ConsoleMenuFrame.PlayerContext.softenemy.canAttack == true or ConsoleMenuFrame.PlayerContext.target.canAttack == true)
    then
        context = "precombat"
    elseif ConsoleMenuFrame.PlayerContext.mount == 1 or ConsoleMenuFrame.PlayerContext.mount == 2 then
        context = "mount"
    elseif ConsoleMenuFrame.PlayerContext.housing.IsInsidePlot or ConsoleMenuFrame.PlayerContext.housing.IsInsideHouse then
        context = "housing"
    end

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

    if ConsoleMenuFrame.PlayerContext.inCombat == true
       and ConsoleMenuFrame.PlayerContext.vehicle == false
    then
        ChangeActionBarPage(1)
    elseif ConsoleMenuFrame.PlayerContext.inCombat == false
       and ConsoleMenuFrame.PlayerContext.mount == 0
       and ConsoleMenuFrame.PlayerContext.vehicle == false
       and (ConsoleMenuFrame.PlayerContext.softenemy.canAttack == true or ConsoleMenuFrame.PlayerContext.target.canAttack == true)
    then
        ChangeActionBarPage(1)
    elseif ConsoleMenuFrame.PlayerContext.mount == 1 and ConsoleMenuFrame.PlayerContext.inCombat == false then
        -- Обычное средство передвижения
        ChangeActionBarPage(4)
    elseif ConsoleMenuFrame.PlayerContext.mount == 2 then
        -- Полет на драконе
        ChangeActionBarPage(1)
    elseif ConsoleMenuFrame.PlayerContext.inCombat == false
        and ConsoleMenuFrame.PlayerContext.vehicle == false
        and (ConsoleMenuFrame.PlayerContext.softfriend.isPlayer == true or ConsoleMenuFrame.PlayerContext.target.isFriend == true)
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
            local info = C_ActionBar.GetActionCooldown(slot)

            if actionType and id and command and info and not info.isActive then
                local title = ConsoleMenu:GetSlotTitle(actionType, id)
                local binding = ConsoleMenu:GetCommandBinding(command)

                if title and binding and isUsable then
                    if issecretvalue(count) then
                        ConsoleMenu:AddKeysFrameItem(binding, title, count)
                    else
                        -- Добавляем элемент, если стаков не 0 и заклинание пригодно к использованию
                        if count ~= "0" then
                            ConsoleMenu:AddKeysFrameItem(binding, title, count)
                        end
                    end
                end
            end
        end

        if UnitExists("softinteract") then
            ConsoleMenu:SetInteractBinding("softinteract")
        end

        ConsoleMenu:UpdateKeysFrame()

        if context == ConsoleMenuFrame.PlayerContext.lastContext then
            return
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        ConsoleMenu:PlayFadeIn(ObjectiveTrackerFrame)
        ConsoleMenu:AnimatedShow(Minimap)
        PlayerFrame:SetAlpha(0)

    elseif context == "window" then

        if ConsoleMenuFrame.PlayerContext.window[3] or ConsoleMenuFrame.PlayerContext.window[4] then
            ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
            ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")

            if ConsoleMenuFrame.SubtitleFrame.CurrentSubtitle and ConsoleMenuFrame.SubtitleFrame.CurrentSubtitle.lastLine == false then
                ConsoleMenu:AddKeysFrameItem("PAD4", "Пропустить")
            end

            ConsoleMenu:HideChatFrame()
        elseif ConsoleMenuFrame.PlayerContext.window["fasttravel"] then
            ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
            ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")
            ConsoleMenu:AddKeysFrameItem("PADDLEFTRIGHT", "Переключение вкладок")

            ConsoleMenu:HideChatFrame()

        elseif ConsoleMenuFrame.PlayerContext.window["playerchoice"] then
            ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
            ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")
            
            ConsoleMenu:HideChatFrame()
        elseif ConsoleMenuFrame.PlayerContext.window["panel"] then
            ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
            ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")
            ConsoleMenu:AddKeysFrameItem("PADDLEFTRIGHT", "Переключение вкладок")

            ConsoleMenu:HideChatFrame()
        end

        ConsoleMenu:UpdateKeysFrame()

        if context == ConsoleMenuFrame.PlayerContext.lastContext then
            return
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        PlayerFrame:SetAlpha(0)

    elseif context == "mount" then
        local page = 4

        if GetActionBarPage() ~= 4 then
            page = 11
        end

        if page == 4 then
            gliding = IsFlying()
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
            if cooldownInfo and cooldownInfo.isActive then
                isOnCooldown = cooldownInfo.isActive
            end

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
                    local title = ConsoleMenu:GetSlotTitle(actionType, id)
                    local binding = ConsoleMenu:GetCommandBinding(command)
    
                    if title and binding then
                        if issecretvalue(count) then
                            ConsoleMenu:AddKeysFrameItem(binding, title, count)
                        else
                            -- Добавляем элемент, если стаков не 0 и заклинание пригодно к использованию
                            if count ~= "0" then
                                ConsoleMenu:AddKeysFrameItem(binding, title, count)
                            end
                        end
                    end
                end
            end
        end

        if UnitIsInteractable("softinteract")  then
            ConsoleMenu:DeleteKeysFrameItem("PAD1")
            ConsoleMenu:AddKeysFrameItem("PAD1", "Взаимодействие")
        end

        ConsoleMenu:UpdateKeysFrame()

        if context == ConsoleMenuFrame.PlayerContext.lastContext then
            return
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        PlayerFrame:SetAlpha(0)

        if page == 4 then
            C_Timer.After(0.5, function()
                ConsoleMenu:ApplyContextUIChanges()
            end)
        end

    elseif context == "combat" or context == "precombat" then
        local page = 1
        local startSlot = 12 * (page - 1) + 1
        local lastSlot = startSlot + 11

        local positions = ConsoleMenu:GetButtonPositions()

        for slot = startSlot, lastSlot do
            local command = ConsoleMenu:GetBindingCommandBySlotID(slot)
            local binding = ConsoleMenu:GetCommandBinding(command)
            local ignoredSlot = ConsoleMenu:IsSlotIgnored(slot)

            if command and binding then

                local actionType, id, subType = GetActionInfo(slot)
                local isUsable, isLackingResources = C_ActionBar.IsUsableAction(slot)
                local count = C_ActionBar.GetActionDisplayCount(slot)
                local info = C_ActionBar.GetActionCooldown(slot)

                if actionType and id and info and not info.isActive then
                    local title = ConsoleMenu:GetSlotTitle(actionType, id)
    
                    if title and binding and isUsable and ignoredSlot then
                        if issecretvalue(count) then
                            ConsoleMenu:AddKeysFrameItem(binding, title, count)
                        else
                            -- Добавляем элемент, если стаков не 0 и заклинание пригодно к использованию
                            if count ~= "0" then
                                ConsoleMenu:AddKeysFrameItem(binding, title, count)
                            end
                        end
                    end
                end
            end
        end

        if UnitIsInteractable("softinteract") and context == "combat" then
            ConsoleMenu:AddKeysFrameItem("SHIFT-PAD1", "Взаимодействие")
        elseif UnitIsInteractable("softinteract") and context == "precombat" then
            ConsoleMenu:AddKeysFrameItem("PAD1", "Взаимодействие")
        end

        ConsoleMenu:UpdateKeysFrame()

        if context == ConsoleMenuFrame.PlayerContext.lastContext then
            return
        end

        if EncounterTimeline:IsShown() then
            ConsoleMenu:PlayFadeOut(ObjectiveTrackerFrame)
            ConsoleMenu:AnimatedHide(Minimap)
        else
            ConsoleMenu:PlayFadeIn(ObjectiveTrackerFrame)
            ConsoleMenu:AnimatedShow(Minimap)
        end
        
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.CombatFrame)
        PlayerFrame:SetAlpha(1)

    elseif context == "housing" then

        if ConsoleMenuFrame.PlayerContext.housing.currentEditMode == 0 then
            if ConsoleMenuFrame.PlayerContext.housing.IsInsideHouse then
                ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти из дома")
            end

            ConsoleMenu:AddKeysFrameItem("PAD3", "Редактирование")
        else
            if ConsoleMenuFrame.PlayerContext.housing.IsInsideHouse then
            end
        end

        ConsoleMenu:UpdateKeysFrame()

        if context == ConsoleMenuFrame.PlayerContext.lastContext then
            return
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        ConsoleMenu:PlayFadeOut(ObjectiveTrackerFrame)
        ConsoleMenu:AnimatedHide(Minimap)
        PlayerFrame:SetAlpha(0)
            
    end

    ConsoleMenuFrame.PlayerContext.lastContext = context
end

-- Функция инициализации контекстов
function ConsoleMenu:InitializeContexts()

    local frame = ConsoleMenuFrame

    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")

    -- Отслеживание целей и soft-target
    frame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
    frame:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")

    -- Отслеживание входа/выхода из боя
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Для отслеживания средств передвижения
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("UNIT_POWER_BAR_SHOW")
    frame:RegisterEvent("UNIT_POWER_BAR_HIDE")

    -- Для отслеживания полетов
    frame:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")

    --  Для отслеживания транспорта
    frame:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA")
    frame:RegisterEvent("PLAYER_GAINS_VEHICLE_DATA")

    -- Отслеживание смерти и воскрешения
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_UNGHOST")

    -- Отслеживание открытия/закрытия окна интерфейса
    frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")

    -- Отслеживание изменения пригодности к использованию и количества зарядов заклинаний
    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

    -- Отслеживание пребывания в доме
    frame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    frame:RegisterEvent("HOUSING_BASIC_MODE_SELECTED_TARGET_CHANGED")
    frame:RegisterEvent("HOUSING_DECOR_PRECISION_SUBMODE_CHANGED")
    frame:RegisterEvent("HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED")
    frame:RegisterEvent("HOUSE_EDITOR_AVAILABILITY_CHANGED")
    frame:RegisterEvent("HOUSE_INFO_UPDATED")
    frame:RegisterEvent("CURRENT_HOUSE_INFO_RECIEVED")
    frame:RegisterEvent("HOUSE_PLOT_ENTERED")
    frame:RegisterEvent("HOUSE_PLOT_EXITED")

    -- Отслеживание открытия диалогов
    frame:RegisterEvent("SPELL_CONFIRMATION_PROMPT")
    frame:RegisterEvent("SPELL_CONFIRMATION_TIMEOUT")

    ConsoleMenuFrame.PlayerContext = {
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

        -- Находится ли в доме
        housing = {},
    }

    frame:SetScript("OnEvent", function(self, event, ...)

        if event == "PLAYER_ENTERING_WORLD" then
            UpdatePlayerAlive()
            UpdatePlayerInCombat()
            UpdatePlayerSoftEnemy()
            UpdatePlayerSoftFriend()
            UpdatePlayerTarget()

            C_Timer.After(0.5, function()
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
            C_Timer.After(0.5, function()
                UpdatePlayerMount()
                SwitchActionBarPage()
            end)
        elseif event == "PLAYER_IS_GLIDING_CHANGED" then
            gliding = ...
        elseif event == "PLAYER_LOSES_VEHICLE_DATA" or event == "PLAYER_GAINS_VEHICLE_DATA" then
            UpdatePlayerVehicle()
        elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
            UpdatePlayerAlive()
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
            ConsoleMenu:AddWindow(...)
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
            ConsoleMenu:RemoveWindow(...)
        elseif event == "HOUSE_EDITOR_MODE_CHANGED" or event == "HOUSING_BASIC_MODE_SELECTED_TARGET_CHANGED" or event == "HOUSING_DECOR_PRECISION_SUBMODE_CHANGED" or event == "HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED" or event == "HOUSE_EDITOR_AVAILABILITY_CHANGED" or event == "HOUSE_INFO_UPDATED" or event == "CURRENT_HOUSE_INFO_RECIEVED" or event == "HOUSE_PLOT_ENTERED" or event == "HOUSE_PLOT_EXITED" then
            UpdatePlayerIsInsideHouseOrPlot()
        elseif event == "SPELL_CONFIRMATION_PROMPT" then
            ConsoleMenu:AddWindow("staticpopup")
        elseif event == "SPELL_CONFIRMATION_TIMEOUT" then
            ConsoleMenu:RemoveWindow("staticpopup")
        end

        ConsoleMenu:ApplyContextUIChanges()  

        SwitchActionBarPage()
    end)
    
end
