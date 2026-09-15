-- Contexts.lua
-- Определение режима персонажа и перестроение подсказок под текущую ситуацию.

local ConsoleMenu = _G.ConsoleMenu

-- Заклинания полёта на драконе, которые доступны только в воздухе.
local spellsNeedGliding = {
    [372608] = true,
    [361584] = true,
    [403092] = true,
}

-- Слоты, скрытые на панели действий и показываемые в подсказках в бою.
local combatSlots = { 8, 10, 11, 58 }

-- Окна, которые учитываются как открытый интерфейс, но не переключают общий режим.
local windowsIgnoredByContext = {
    chat = true,
}

-- Типы взаимодействия, для которых есть собственные подсказки.
local handledInteractionTypes = nil

-- Планирование на драконе по данным игры.
local isGliding = false

-- Последнее известное состояние обычного полёта.
local lastKnownFlying = nil

-- Повторяющийся таймер проверки обычного полёта.
local flyingTicker = nil

-- Возвращает таблицу признаков персонажа или пустое значение.
local function GetPlayerContextData()
    return ConsoleMenuFrame and ConsoleMenuFrame.PlayerContext
end

-- Заполняет перечень обрабатываемых типов взаимодействия.
local function EnsureHandledInteractionTypes()
    if handledInteractionTypes or not Enum or not Enum.PlayerInteractionType then
        return
    end

    handledInteractionTypes = {
        [Enum.PlayerInteractionType.Gossip] = true,
        [Enum.PlayerInteractionType.QuestGiver] = true,
        [Enum.PlayerInteractionType.Merchant] = true,
        [Enum.PlayerInteractionType.PlayerChoice] = true,
    }
end

-- Возвращает истину, если шкала событий схватки сейчас показана.
local function IsEncounterTimelineShown()
    return EncounterTimeline and EncounterTimeline:IsShown()
end

-- Останавливает таймер проверки обычного полёта.
local function StopFlyingTicker()
    if flyingTicker then
        flyingTicker:Cancel()
        flyingTicker = nil
    end
end

-- Запускает таймер проверки обычного полёта, если он ещё не запущен.
local function StartFlyingTicker()
    if flyingTicker then
        return
    end

    lastKnownFlying = IsFlying()
    flyingTicker = C_Timer.NewTicker(1, function()
        local contextData = GetPlayerContextData()
        if not contextData or contextData.mount ~= 1 then
            StopFlyingTicker()
            return
        end

        local flying = IsFlying()
        if flying == lastKnownFlying then
            return
        end

        lastKnownFlying = flying
        ConsoleMenu:ApplyContextUIChanges()
    end)
end

-- Обновляет признак жизни с учётом призрака.
local function UpdatePlayerAlive()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    contextData.alive = not UnitIsDeadOrGhost("player")
end

-- Обновляет признак боя.
local function UpdatePlayerInCombat()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    contextData.inCombat = UnitAffectingCombat("player") and true or false
end

-- Обновляет тип средства передвижения и состояние планирования.
local function UpdatePlayerMount()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    local currentlyGliding, canGlide = C_PlayerInfo.GetGlidingInfo()
    isGliding = currentlyGliding and true or false

    if IsMounted() and canGlide then
        contextData.mount = 2
    elseif IsMounted() then
        contextData.mount = 1
    else
        contextData.mount = 0
    end
end

-- Обновляет признак транспорта и полёта на такси.
local function UpdatePlayerVehicle()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    contextData.vehicle = (UnitInVehicle("player") or UnitOnTaxi("player")) and true or false
end

-- Собирает признаки выбранной цели заново.
local function UpdatePlayerTarget()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    if not UnitExists("target") or UnitIsDead("target") then
        contextData.target = {}
        return
    end

    contextData.target = {
        isPlayer = UnitIsPlayer("target"),
        canAttack = UnitCanAttack("player", "target") and true or false,
        isEnemy = UnitIsEnemy("player", "target") and true or false,
        isFriend = UnitIsFriend("player", "target") and true or false,
        canAssist = UnitCanAssist("player", "target") and true or false,
    }
end

-- Собирает признаки мягкого врага заново.
local function UpdatePlayerSoftEnemy()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    if not UnitExists("softenemy") then
        contextData.softenemy = {}
        return
    end

    contextData.softenemy = {
        isPlayer = UnitIsPlayer("softenemy"),
        canAttack = UnitCanAttack("player", "softenemy") and true or false,
    }
end

-- Собирает признаки мягкого союзника заново.
local function UpdatePlayerSoftFriend()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    if not UnitExists("softfriend") then
        contextData.softfriend = {}
        return
    end

    contextData.softfriend = {
        isPlayer = UnitIsPlayer("softfriend"),
        canAssist = UnitCanAssist("player", "softfriend") and true or false,
    }
end

-- Обновляет признаки нахождения в доме и на участке.
local function UpdatePlayerIsInsideHouseOrPlot()
    local contextData = GetPlayerContextData()
    if not contextData or not contextData.housing then
        return
    end

    if not C_Housing or not C_HouseEditor then
        contextData.housing.IsInsidePlot = false
        contextData.housing.IsInsideHouse = false
        contextData.housing.currentEditMode = nil
        return
    end

    contextData.housing.IsInsidePlot = C_Housing.IsInsidePlot()
    contextData.housing.IsInsideHouse = C_Housing.IsInsideHouse()
    contextData.housing.currentEditMode = C_HouseEditor.GetActiveHouseEditorMode()
end

-- Возвращает истину, если персонаж сейчас в воздухе для текущего средства.
local function IsPlayerAirborne()
    local contextData = GetPlayerContextData()
    if contextData and contextData.mount == 2 then
        return isGliding
    end

    return IsFlying() and true or false
end

-- Возвращает истину, если слот панели заполнен действием.
local function SlotHasAction(slot)
    return C_ActionBar.HasAction(slot)
end

-- Возвращает истину, если слот на собственной перезарядке, а не на общем кулдауне.
local function IsSlotOnCooldown(slot)
    local info = C_ActionBar.GetActionCooldown(slot)
    if not info or issecretvalue(info) then
        return false
    end

    local duration = info.duration
    local isEnabled = info.isEnabled
    if issecretvalue(duration) or issecretvalue(isEnabled) then
        return false
    end

    if not isEnabled or duration <= 0 then
        return false
    end

    if info.isOnGCD and not issecretvalue(info.isOnGCD) then
        return false
    end

    return true
end

-- Добавляет подсказку, если число зарядов скрыто или не равно нулю.
local function AddKeysItemIfCountAllows(binding, title, count)
    if not title or not binding then
        return
    end

    if issecretvalue(count) then
        ConsoleMenu:AddKeysFrameItem(binding, title, count)
        return
    end

    if count ~= "0" then
        ConsoleMenu:AddKeysFrameItem(binding, title, count)
    end
end

-- Меняет страницу панели действий, если текущая страница другая.
local function SetActionBarPageIfNeeded(page)
    if C_ActionBar.GetActionBarPage() ~= page then
        C_ActionBar.SetActionBarPage(page)
    end
end

-- Запоминает открытое окно, не затирая остальные.
function ConsoleMenu:AddWindow(windowType)
    local contextData = GetPlayerContextData()
    if not contextData or not contextData.window then
        return
    end

    contextData.window[windowType] = true
end

-- Снимает отметку окна. Нуль очищает весь перечень.
function ConsoleMenu:RemoveWindow(windowType)
    local contextData = GetPlayerContextData()
    if not contextData or not contextData.window then
        return
    end

    if windowType == 0 then
        for key in pairs(contextData.window) do
            contextData.window[key] = nil
        end
        return
    end

    contextData.window[windowType] = nil
end

-- Возвращает истину, если открыто окно, влияющее на общий режим.
function ConsoleMenu:HasWindows()
    local contextData = GetPlayerContextData()
    if not contextData or not contextData.window then
        return false
    end

    for windowType in pairs(contextData.window) do
        if not windowsIgnoredByContext[windowType] then
            return true
        end
    end

    return false
end

-- Возвращает имя текущего режима персонажа.
function ConsoleMenu:GetPlayerContext()
    local contextData = GetPlayerContextData()
    if not contextData then
        return "exploring"
    end

    local target = contextData.target or {}
    local softenemy = contextData.softenemy or {}
    local housing = contextData.housing or {}

    if self:HasWindows() then
        return "window"
    end

    if contextData.alive == false then
        return "soul"
    end

    if contextData.inCombat == true
        and contextData.mount == 0
        and contextData.vehicle == false
    then
        return "combat"
    end

    if contextData.inCombat == false
        and contextData.mount == 0
        and contextData.vehicle == false
        and (softenemy.canAttack == true or target.canAttack == true)
    then
        return "precombat"
    end

    if contextData.mount == 1 or contextData.mount == 2 then
        return "mount"
    end

    if housing.IsInsidePlot or housing.IsInsideHouse then
        return "housing"
    end

    return "exploring"
end

-- Переключает страницу панели действий под текущий режим.
local function SwitchActionBarPage()
    if ConsoleMenuDB and ConsoleMenuDB.actionBarPageSwitching == 2 then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        return
    end

    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    local target = contextData.target or {}
    local softenemy = contextData.softenemy or {}
    local softfriend = contextData.softfriend or {}

    if contextData.inCombat == true and contextData.vehicle == false then
        local currentPage = C_ActionBar.GetActionBarPage()
        if currentPage ~= 1 and currentPage ~= 2 then
            SetActionBarPageIfNeeded(1)
        end
    elseif contextData.inCombat == false
        and contextData.mount == 0
        and contextData.vehicle == false
        and (softenemy.canAttack == true or target.canAttack == true)
    then
        local currentPage = C_ActionBar.GetActionBarPage()
        if currentPage ~= 1 and currentPage ~= 2 then
            SetActionBarPageIfNeeded(1)
        end
    elseif contextData.mount == 1 and contextData.inCombat == false then
        SetActionBarPageIfNeeded(4)
    elseif contextData.mount == 2 then
        SetActionBarPageIfNeeded(1)
    elseif contextData.inCombat == false
        and contextData.vehicle == false
        and (softfriend.isPlayer == true or target.isFriend == true)
    then
        SetActionBarPageIfNeeded(3)
    else
        if PlayerIsInCombat() then
            SetActionBarPageIfNeeded(1)
        else
            SetActionBarPageIfNeeded(3)
        end
    end
end

-- Добавляет подсказку по скрытому боевому слоту.
local function AddCombatSlotKeysFrameItem(slot)
    if not SlotHasAction(slot) then
        return
    end

    local command = ConsoleMenu:GetBindingCommandBySlotID(slot)
    local binding = ConsoleMenu:GetCommandBinding(command, ConsoleMenu:IsGamePadActive())
    local ignoredSlot = ConsoleMenu:IsSlotIgnored(slot)

    if not command or not binding or not ignoredSlot then
        return
    end

    if IsSlotOnCooldown(slot) then
        return
    end

    local actionType, id, subType = GetActionInfo(slot)
    if not actionType or not id then
        return
    end

    local isUsable = C_ActionBar.IsUsableAction(slot)
    local count = C_ActionBar.GetActionDisplayCount(slot)
    local title = ConsoleMenu:GetSlotTitle(actionType, id, subType, slot)

    if title and isUsable then
        AddKeysItemIfCountAllows(binding, title, count)
    end
end

-- Показывает подсказки страницы исследования.
local function ApplyExploringKeys()
    local page = C_ActionBar.GetActionBarPage()
    local startSlot = 12 * (page - 1) + 1
    local lastSlot = startSlot + 11

    for slot = startSlot, lastSlot do
        if SlotHasAction(slot) and not IsSlotOnCooldown(slot) then
            local actionType, id, subType = GetActionInfo(slot)
            local command = ConsoleMenu:GetBindingCommandBySlotID(slot)
            local isUsable = C_ActionBar.IsUsableAction(slot)
            local count = C_ActionBar.GetActionDisplayCount(slot)

            if actionType and id and command and isUsable then
                local title = ConsoleMenu:GetSlotTitle(actionType, id, subType, slot)
                local binding = ConsoleMenu:GetCommandBinding(command, ConsoleMenu:IsGamePadActive())
                AddKeysItemIfCountAllows(binding, title, count)
            end
        end
    end

    if UnitExists("softinteract") then
        ConsoleMenu:SetInteractBinding("softinteract")
    end
end

-- Показывает подсказки открытого окна интерфейса.
local function ApplyWindowKeys(contextData)
    local window = contextData.window
    local interactionType = Enum and Enum.PlayerInteractionType

    if interactionType and (window[interactionType.Gossip] or window[interactionType.QuestGiver]) then
        ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
        ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")

        if ConsoleMenu:CanRepeatCurrentSubtitles() then
            ConsoleMenu:AddKeysFrameItem("PAD3", "Повторить")
        end
        if ConsoleMenu:CanSkipCurrentSubtitle() then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Пропустить")
        end

        ConsoleMenu:HideChatFrame()
        if ConsoleMenu.Compass then
            ConsoleMenu.Compass:SetContextHidden(true)
        end
    elseif interactionType and window[interactionType.Merchant] then
        C_Timer.After(0.1, function()
            local current = GetPlayerContextData()
            if current and current.window and interactionType and current.window[interactionType.Merchant] then
                ConsoleMenu:ShowItemListFrame()
            end
        end)

        ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
        ConsoleMenu:AddKeysFrameItem("PADDLEFTRIGHT", "Переключение вкладок")
        ConsoleMenu:UpdateItemListFrameKeysFrame()

        ConsoleMenu:PlayFadeOut(ObjectiveTrackerFrame)
        ConsoleMenu:AnimatedHide(Minimap)
        if ConsoleMenu.Compass then
            ConsoleMenu.Compass:SetContextHidden(true)
        end
    elseif window["fasttravel"] then
        ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
        ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")
        ConsoleMenu:AddKeysFrameItem("PADDLEFTRIGHT", "Переключение вкладок")

        ConsoleMenu:HideChatFrame()
    elseif (interactionType and window[interactionType.PlayerChoice]) or window["playerchoice"] then
        ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
        ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")

        ConsoleMenu:HideChatFrame()
    elseif window["panel"] then
        ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
        ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")
        ConsoleMenu:AddKeysFrameItem("PADDLEFTRIGHT", "Переключение вкладок")

        ConsoleMenu:HideChatFrame()
    elseif window["staticpopup"] then
        ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти")
        ConsoleMenu:AddKeysFrameItem("PAD1", "Выбрать")
    end
end

-- Показывает подсказки средств передвижения.
local function ApplyMountKeys(contextData)
    local page = 4
    if C_ActionBar.GetActionBarPage() ~= 4 then
        page = 11
    end

    local airborne = IsPlayerAirborne()
    local startSlot = 12 * (page - 1) + 1
    local lastSlot = startSlot + 11

    for slot = startSlot, lastSlot do
        if SlotHasAction(slot) then
            local actionType, id, subType = GetActionInfo(slot)
            local command = ConsoleMenu:GetBindingCommandBySlotID(slot)
            local isUsable = C_ActionBar.IsUsableAction(slot)
            local count = C_ActionBar.GetActionDisplayCount(slot)
            local spellId = C_ActionBar.GetSpell(slot)

            if spellId == 372610 then
                command = "JUMP"
            end

            local shouldShow = false
            if IsSlotOnCooldown(slot) then
                shouldShow = false
            elseif spellId == 0 then
                shouldShow = not airborne
            elseif spellsNeedGliding[spellId] then
                shouldShow = airborne == true
            else
                shouldShow = true
            end

            if shouldShow and actionType and id and command and isUsable then
                local title = ConsoleMenu:GetSlotTitle(actionType, id, subType, slot)
                local binding = ConsoleMenu:GetCommandBinding(command, ConsoleMenu:IsGamePadActive())
                AddKeysItemIfCountAllows(binding, title, count)
            end
        end
    end

    if UnitIsInteractable("softinteract") then
        ConsoleMenu:DeleteKeysFrameItem("PADRTRIGGER")
        ConsoleMenu:AddKeysFrameItem("PADRTRIGGER", "Взаимодействие")
    end

    if contextData.mount == 1 then
        StartFlyingTicker()
    else
        StopFlyingTicker()
    end
end

-- Показывает подсказки боя и подготовки к бою.
local function ApplyCombatKeys(context)
    for _, slot in ipairs(combatSlots) do
        AddCombatSlotKeysFrameItem(slot)
    end

    if UnitIsInteractable("softinteract") and context == "combat" then
        ConsoleMenu:AddKeysFrameItem("SHIFT-PADRTRIGGER", "Взаимодействие")
    elseif UnitIsInteractable("softinteract") and context == "precombat" then
        ConsoleMenu:AddKeysFrameItem("PADRTRIGGER", "Взаимодействие")
    end
end

-- Показывает подсказки жилья.
local function ApplyHousingKeys(contextData)
    local noneMode = Enum and Enum.HouseEditorMode and Enum.HouseEditorMode.None
    if contextData.housing.currentEditMode == noneMode or contextData.housing.currentEditMode == 0 then
        if contextData.housing.IsInsideHouse then
            ConsoleMenu:AddKeysFrameItem("PAD2", "Выйти из дома")
        end

        ConsoleMenu:AddKeysFrameItem("PAD3", "Редактирование")
    end
end

-- Скрывает индикаторы, пока открыто окно диалога или задания.
local function SyncNameplatesWithGossip(contextData)
    local nameplates = ConsoleMenu.Nameplates
    if not nameplates or not nameplates.SetContextHidden then
        return
    end

    local window = contextData.window
    local interactionType = Enum and Enum.PlayerInteractionType
    local gossipOpen = interactionType
        and window
        and (window[interactionType.Gossip] or window[interactionType.QuestGiver])
    nameplates.SetContextHidden(gossipOpen and true or false)
end

-- Перестраивает подсказки и видимость панелей под текущий режим.
function ConsoleMenu:ApplyContextUIChanges()
    local contextData = GetPlayerContextData()
    if not contextData then
        return
    end

    local context = ConsoleMenu:GetPlayerContext()
    SyncNameplatesWithGossip(contextData)

    if context == "mount" and contextData.mount == 1 then
        StartFlyingTicker()
    else
        StopFlyingTicker()
    end

    ConsoleMenu:ResetKeysItems()

    if context == "exploring" then
        ApplyExploringKeys()
        ConsoleMenu:UpdateKeysFrame()

        if context == contextData.lastContext then
            return
        end

        ConsoleMenu:HideItemListFrame()
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        ConsoleMenu:AnimatedHide(PersonalResourceDisplayFrame)
        ConsoleMenu:PlayFadeIn(ObjectiveTrackerFrame)
        ConsoleMenu:AnimatedShow(Minimap)
        if ConsoleMenu.Compass then
            ConsoleMenu.Compass:SetContextHidden(false)
        end
    elseif context == "window" then
        ApplyWindowKeys(contextData)
        ConsoleMenu:UpdateKeysFrame()

        if context == contextData.lastContext then
            return
        end

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        ConsoleMenu:AnimatedHide(PersonalResourceDisplayFrame)
    elseif context == "mount" then
        ApplyMountKeys(contextData)
        ConsoleMenu:UpdateKeysFrame()

        if context == contextData.lastContext then
            return
        end

        ConsoleMenu:HideItemListFrame()
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        ConsoleMenu:AnimatedHide(PersonalResourceDisplayFrame)
    elseif context == "combat" or context == "precombat" then
        ApplyCombatKeys(context)
        ConsoleMenu:UpdateKeysFrame()
        ConsoleMenu:AnimatedShow(PersonalResourceDisplayFrame)

        if context == contextData.lastContext then
            return
        end

        if IsEncounterTimelineShown() then
            ConsoleMenu:PlayFadeOut(ObjectiveTrackerFrame)
            ConsoleMenu:AnimatedHide(Minimap)
        else
            ConsoleMenu:PlayFadeIn(ObjectiveTrackerFrame)
            ConsoleMenu:AnimatedShow(Minimap)
        end
        if ConsoleMenu.Compass then
            ConsoleMenu.Compass:SetContextHidden(context == "combat" or IsEncounterTimelineShown())
        end

        ConsoleMenu:HideItemListFrame()
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.CombatFrame)
    elseif context == "housing" then
        ApplyHousingKeys(contextData)
        ConsoleMenu:UpdateKeysFrame()

        if context == contextData.lastContext then
            return
        end

        ConsoleMenu:HideItemListFrame()
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        ConsoleMenu:AnimatedHide(PersonalResourceDisplayFrame)
        ConsoleMenu:PlayFadeOut(ObjectiveTrackerFrame)
        ConsoleMenu:AnimatedHide(Minimap)
        if ConsoleMenu.Compass then
            ConsoleMenu.Compass:SetContextHidden(true)
        end
    elseif context == "soul" then
        ConsoleMenu:UpdateKeysFrame()

        if context == contextData.lastContext then
            return
        end

        ConsoleMenu:HideItemListFrame()
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.ActionBarFrame)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.CombatFrame)
        ConsoleMenu:AnimatedHide(PersonalResourceDisplayFrame)
        ConsoleMenu:PlayFadeOut(ObjectiveTrackerFrame)
        ConsoleMenu:AnimatedShow(Minimap)
        if ConsoleMenu.Compass then
            ConsoleMenu.Compass:SetContextHidden(true)
        end
    end

    contextData.lastContext = context
end

-- Обновляет подсказки без смены страницы панели.
local function RefreshUI()
    ConsoleMenu:ApplyContextUIChanges()
end

-- Обновляет подсказки и страницу панели действий.
local function RefreshUIAndActionBar()
    ConsoleMenu:ApplyContextUIChanges()
    SwitchActionBarPage()
end

-- Обновляет признаки при входе в мир.
local function HandlePlayerEnteringWorld()
    UpdatePlayerAlive()
    UpdatePlayerInCombat()
    UpdatePlayerSoftEnemy()
    UpdatePlayerSoftFriend()
    UpdatePlayerTarget()
    UpdatePlayerIsInsideHouseOrPlot()
    RefreshUI()

    C_Timer.After(0.5, function()
        UpdatePlayerMount()
        UpdatePlayerVehicle()
        RefreshUIAndActionBar()
    end)
end

-- Регистрирует события и создаёт таблицу признаков персонажа.
function ConsoleMenu:InitializeContexts()
    local frame = ConsoleMenuFrame
    EnsureHandledInteractionTypes()

    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")

    frame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
    frame:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
    frame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")

    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")

    frame:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA")
    frame:RegisterEvent("PLAYER_GAINS_VEHICLE_DATA")

    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_UNGHOST")

    frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")

    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

    frame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    frame:RegisterEvent("HOUSING_BASIC_MODE_SELECTED_TARGET_CHANGED")
    frame:RegisterEvent("HOUSING_DECOR_PRECISION_SUBMODE_CHANGED")
    frame:RegisterEvent("HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED")
    frame:RegisterEvent("HOUSE_EDITOR_AVAILABILITY_CHANGED")
    frame:RegisterEvent("HOUSE_INFO_UPDATED")
    frame:RegisterEvent("CURRENT_HOUSE_INFO_RECIEVED")
    frame:RegisterEvent("HOUSE_PLOT_ENTERED")
    frame:RegisterEvent("HOUSE_PLOT_EXITED")

    frame:RegisterEvent("SPELL_CONFIRMATION_PROMPT")
    frame:RegisterEvent("SPELL_CONFIRMATION_TIMEOUT")
    frame:RegisterEvent("ENCOUNTER_TIMELINE_STATE_UPDATED")

    ConsoleMenuFrame.PlayerContext = {
        -- Жив ли персонаж, включая состояние призрака.
        alive = nil,

        -- Находится ли персонаж в бою.
        inCombat = nil,

        -- Средство передвижения: 0 — нет, 1 — обычное, 2 — полёт на драконе.
        mount = nil,

        -- Находится ли персонаж в транспорте или на такси.
        vehicle = nil,

        -- Признаки выбранной цели.
        target = {},

        -- Признаки мягкого врага.
        softenemy = {},

        -- Признаки мягкого союзника.
        softfriend = {},

        -- Открытые окна интерфейса.
        window = {},

        -- Последний выбранный режим.
        lastContext = nil,

        -- Признаки дома и участка.
        housing = {},
    }

    if hooksecurefunc then
        hooksecurefunc("StaticPopup_OnHide", function()
            local contextData = GetPlayerContextData()
            if contextData and contextData.window and contextData.window["staticpopup"] then
                ConsoleMenu:RemoveWindow("staticpopup")
                RefreshUI()
            end
        end)
    end

    frame:SetScript("OnEvent", function(_, event, ...)
        EnsureHandledInteractionTypes()

        if event == "GAME_PAD_ACTIVE_CHANGED" then
            ConsoleMenu:SetGamePadActive(...)
            RefreshUI()
        elseif event == "PLAYER_ENTERING_WORLD" then
            HandlePlayerEnteringWorld()
        elseif event == "PLAYER_SOFT_ENEMY_CHANGED" then
            UpdatePlayerSoftEnemy()
            RefreshUIAndActionBar()
        elseif event == "PLAYER_SOFT_FRIEND_CHANGED" then
            UpdatePlayerSoftFriend()
            RefreshUIAndActionBar()
        elseif event == "PLAYER_SOFT_INTERACT_CHANGED" then
            RefreshUI()
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdatePlayerTarget()
            RefreshUIAndActionBar()
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            UpdatePlayerInCombat()
            RefreshUIAndActionBar()
        elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
            UpdatePlayerMount()
            UpdatePlayerVehicle()
            RefreshUI()
            C_Timer.After(0.5, function()
                UpdatePlayerMount()
                UpdatePlayerVehicle()
                RefreshUIAndActionBar()
            end)
        elseif event == "PLAYER_IS_GLIDING_CHANGED" then
            isGliding = ... and true or false
            RefreshUI()
        elseif event == "PLAYER_LOSES_VEHICLE_DATA" or event == "PLAYER_GAINS_VEHICLE_DATA" then
            local unitTarget = ...
            if unitTarget == "player" then
                UpdatePlayerVehicle()
                RefreshUIAndActionBar()
            end
        elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
            UpdatePlayerAlive()
            RefreshUIAndActionBar()
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
            local shownType = ...
            local types = Enum and Enum.PlayerInteractionType
            local taxiType = types and (types.TaxiNode or types.Taxi)
            if taxiType and shownType == taxiType then
                if types.Gossip then
                    ConsoleMenu:RemoveWindow(types.Gossip)
                end
                RefreshUI()
                return
            end
            if handledInteractionTypes and handledInteractionTypes[shownType] then
                ConsoleMenu:AddWindow(shownType)
                RefreshUI()
            end
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
            local interactionType = ...
            if handledInteractionTypes and handledInteractionTypes[interactionType] then
                ConsoleMenu:RemoveWindow(interactionType)
                RefreshUI()
            end
        elseif event == "HOUSE_EDITOR_MODE_CHANGED"
            or event == "HOUSING_BASIC_MODE_SELECTED_TARGET_CHANGED"
            or event == "HOUSING_DECOR_PRECISION_SUBMODE_CHANGED"
            or event == "HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED"
            or event == "HOUSE_EDITOR_AVAILABILITY_CHANGED"
            or event == "HOUSE_INFO_UPDATED"
            or event == "CURRENT_HOUSE_INFO_RECIEVED"
            or event == "HOUSE_PLOT_ENTERED"
            or event == "HOUSE_PLOT_EXITED"
        then
            UpdatePlayerIsInsideHouseOrPlot()
            RefreshUIAndActionBar()
        elseif event == "SPELL_CONFIRMATION_PROMPT" then
            ConsoleMenu:AddWindow("staticpopup")
            RefreshUI()
        elseif event == "SPELL_CONFIRMATION_TIMEOUT" then
            ConsoleMenu:RemoveWindow("staticpopup")
            RefreshUI()
        elseif event == "ACTIONBAR_PAGE_CHANGED" then
            RefreshUI()
        elseif event == "ACTIONBAR_UPDATE_USABLE"
            or event == "SPELL_UPDATE_CHARGES"
            or event == "ACTIONBAR_UPDATE_COOLDOWN"
            or event == "SPELL_UPDATE_COOLDOWN"
            or event == "ACTIONBAR_UPDATE_STATE"
            or event == "ACTIONBAR_SLOT_CHANGED"
        then
            RefreshUI()
        elseif event == "ENCOUNTER_TIMELINE_STATE_UPDATED" then
            local contextData = GetPlayerContextData()
            if contextData then
                contextData.lastContext = nil
            end
            RefreshUI()
        end
    end)
end
