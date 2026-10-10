-- Создание окна панели команд, набор кнопок и обработка событий.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Промежутки ячеек: основная панель, её вторая страница и панели модификаторов.
local slotRanges = {
    { 1, 12 },
    { 13, 24 },
    { 49, 72 },
}

-- Обходит уже созданные кнопки панели.
local function ForEachButton(callback)
    local frame = ActionBar.GetFrame()
    if not frame or not frame.actionButtons then
        return
    end
    for slotID in pairs(frame.actionButtons) do
        callback(slotID)
    end
end

-- Полное обновление значков после входа в мир.
-- Вход персонажа приходит раньше и часто ещё без ячеек, поэтому его не обрабатываем.
local function RefreshEnteredWorld()
    if ActionBar.InvalidateEquippedItemCache then
        ActionBar.InvalidateEquippedItemCache()
    end

    ForEachButton(function(slotID)
        ActionBar.UpdateTexture(slotID)
        ActionBar.UpdateGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
        ActionBar.UpdateCount(slotID)
    end)
    ActionBar.EnableAllRangeChecks()
    ActionBar.UpdateButtonPositions()
    ActionBar.UpdateCooldowns()
    ActionBar.UpdateModifierState()
    ActionBar.UpdateAllUsable()
end

-- Смена геймпада: заново раскладываем кнопки.
local function OnGamePadActive(_, _, ...)
    ConsoleMenu:SetGamePadActive(...)
    ActionBar.UpdateButtonPositions()
    ActionBar.UpdateModifierState()
end

-- Сетка назначения клавиш показывает или прячет пустые кнопки.
local function OnGridChanged()
    ActionBar.UpdateButtonPositions()
    ActionBar.UpdateModifierState()
end

-- Страница панели меняется на следующем кадре, когда клиент уже отдал новые ячейки.
local function OnPageChanged()
    RunNextFrame(ActionBar.UpdatePageVisibility)
end

-- В ячейке сменилось действие: старое число забываем и читаем заряды нового умения.
-- В бою стираем память только если видно, что умение действительно другое.
local function OnSlotChanged(_, _, slotID)
    if not ActionBar.IsInCombat() or ActionBar.ChargeActionChanged(slotID) then
        ActionBar.ForgetChargeCount(slotID)
    end
    ActionBar.UpdateTexture(slotID)
    ActionBar.UpdateButtonPositions(slotID)
    ActionBar.UpdateCooldowns()
    ActionBar.UpdateCount(slotID)
    ActionBar.UpdateModifierState()
    -- Свечение проверяем кадром позже: оверлей ещё не успевает обновиться.
    RunNextFrame(function()
        ActionBar.UpdateGlow(slotID, nil, "ACTIONBAR_SLOT_CHANGED")
    end)
    ActionBar.EnableRangeCheck(slotID, true)
    ActionBar.UpdateUsable(slotID)
    ActionBar.UpdateBoosts()
end

-- Помощник, бой или смена цели: рисунок и дальность могли устареть.
local function OnCombatOrTarget(_, event)
    if C_ActionBar and C_ActionBar.FindAssistedCombatActionButtons then
        local slots = C_ActionBar.FindAssistedCombatActionButtons()
        if slots then
            for _, slotID in pairs(slots) do
                ActionBar.UpdateTexture(slotID)
                ActionBar.UpdateIcon(slotID)
                ActionBar.UpdateCount(slotID)
            end
        end
    end
    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_SOFT_ENEMY_CHANGED" then
        -- Смена цели сбрасывает старую дальность: иначе значок остаётся серым.
        ActionBar.ClearRangeState()
        ActionBar.EnableAllRangeChecks()
        ActionBar.UpdateAllUsable()
        ActionBar.UpdateBoosts()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        -- В бою пустой ответ не стирал число. После боя его перечитываем на всех кнопках.
        ForEachButton(function(slotID)
            ActionBar.UpdateCount(slotID)
        end)
    end
    ActionBar.UpdateBoosts()
end

-- Восстановление умений обновилось на всей панели и в облаке.
local function OnCooldown()
    ActionBar.UpdateCooldowns()
    ActionBar.UpdateBoosts()
end

-- Клиент проверил дальность одной ячейки.
local function OnRangeCheck(_, _, slotID, isInRange, checksRange)
    ActionBar.SetRangeFromEvent(slotID, isInRange, checksRange)
    if not slotID then
        return
    end
    ActionBar.UpdateUsable(slotID)
    if ActionBar.IsBoostSlot(slotID) or ActionBar.IsExtraActionSlot(slotID) then
        ActionBar.UpdateBoosts()
    end
end

-- Свечение готовности заклинания включается или гаснет на его ячейках.
local function OnGlow(_, event, spellID)
    local slots = C_ActionBar.FindSpellActionButtons(spellID)
    if not slots then
        return
    end
    for _, slotID in pairs(slots) do
        ActionBar.UpdateGlow(slotID, spellID, event)
    end
end

-- Рисунок заклинания сменился: обновляем только ячейки этого заклинания.
local function OnSpellIcon(_, _, spellID)
    if spellID and C_ActionBar.FindSpellActionButtons then
        local slots = C_ActionBar.FindSpellActionButtons(spellID)
        if slots then
            for _, slotID in pairs(slots) do
                ActionBar.UpdateTexture(slotID)
            end
        end
    end
    ActionBar.UpdateBoosts()
end

-- Пригодность ячеек пришла списком или требует полного обновления восстановления.
local function OnUsable(_, _, changes)
    if changes then
        for slotID, changeData in pairs(changes) do
            local isUsable, isLackingResources
            if type(changeData) == "table" then
                isUsable = changeData.isUsable
                if isUsable == nil then
                    isUsable = changeData[1]
                end
                isLackingResources = changeData.isLackingResources
                if isLackingResources == nil then
                    isLackingResources = changeData[2]
                end
            else
                -- Плоский формат: значение само по себе означает пригодность.
                isUsable = changeData
            end
            ActionBar.UpdateUsable(slotID, isUsable, isLackingResources)
        end
    else
        ActionBar.UpdateCooldowns()
    end
    ActionBar.UpdateBoosts()
end

-- Число зарядов изменилось на кнопках и в облаке.
local function OnCharges()
    ForEachButton(function(slotID)
        ActionBar.UpdateCount(slotID)
    end)
    ActionBar.UpdateBoosts()
end

-- Дополнительная кнопка действия появилась или исчезла.
local function OnExtraActionBar()
    ActionBar.UpdateModifierState()
end

-- Надетые предметы сменились: старое соответствие рисунка и предмета больше не годится.
local function OnEquipmentChanged()
    if ActionBar.InvalidateEquippedItemCache then
        ActionBar.InvalidateEquippedItemCache()
    end
    ActionBar.UpdateAllUsable()
    ActionBar.UpdateBoosts()
end

-- Событие и что из-за него обновить.
local eventHandlers = {
    PLAYER_ENTERING_WORLD = RefreshEnteredWorld,
    GAME_PAD_ACTIVE_CHANGED = OnGamePadActive,
    ACTIONBAR_SHOWGRID = OnGridChanged,
    ACTIONBAR_HIDEGRID = OnGridChanged,
    ACTIONBAR_PAGE_CHANGED = OnPageChanged,
    ACTIONBAR_SLOT_CHANGED = OnSlotChanged,
    ASSISTED_COMBAT_ACTION_SPELL_CAST = OnCombatOrTarget,
    PLAYER_REGEN_ENABLED = OnCombatOrTarget,
    PLAYER_REGEN_DISABLED = OnCombatOrTarget,
    PLAYER_TARGET_CHANGED = OnCombatOrTarget,
    PLAYER_FOCUS_CHANGED = OnCombatOrTarget,
    PLAYER_SOFT_ENEMY_CHANGED = OnCombatOrTarget,
    ACTIONBAR_UPDATE_COOLDOWN = OnCooldown,
    SPELL_UPDATE_COOLDOWN = OnCooldown,
    ACTIONBAR_UPDATE_STATE = OnCooldown,
    ACTION_RANGE_CHECK_UPDATE = OnRangeCheck,
    MODIFIER_STATE_CHANGED = function()
        ActionBar.UpdateModifierState()
    end,
    SPELL_ACTIVATION_OVERLAY_GLOW_SHOW = OnGlow,
    SPELL_ACTIVATION_OVERLAY_GLOW_HIDE = OnGlow,
    SPELL_UPDATE_ICON = OnSpellIcon,
    ACTIONBAR_UPDATE_USABLE = OnUsable,
    SPELL_UPDATE_CHARGES = OnCharges,
    UPDATE_EXTRA_ACTIONBAR = OnExtraActionBar,
    PLAYER_EQUIPMENT_CHANGED = OnEquipmentChanged,
}

-- Создание панели команд и подписка на события ячеек.
function ConsoleMenu:InitializeMainActionBar()
    if ConsoleMenuDB.actionBarStyle == 1 then
        return
    end

    if not C_ActionBar.GetActionCooldown or not C_ActionBar.GetActionTexture then
        return
    end

    if ConsoleMenuFrame.ActionBarFrame and ConsoleMenuFrame.ActionBarFrame.buttonsReady then
        return
    end

    if not ConsoleMenuFrame.ActionBarFrame then
        ConsoleMenuFrame.ActionBarFrame = CreateFrame("Frame", nil, ConsoleMenuFrame)
    end

    local frame = ConsoleMenuFrame.ActionBarFrame

    frame:SetSize(ActionBar.frameWidth, ActionBar.frameHeight)
    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, 48)
    ConsoleMenu:InitFadeAnimations(frame, ActionBar.animationDuration)
    if frame.SetClipsChildren then
        frame:SetClipsChildren(false)
    end

    if not frame.PADCenter then
        frame.PADCenter = CreateFrame("Frame", nil, frame)
        frame.PADCenter:SetPoint("RIGHT", frame, "RIGHT", -ActionBar.paddingPAD, 0)
        frame.PADCenter:SetSize(1, 1)
    end

    if not frame.PADDCenter then
        frame.PADDCenter = CreateFrame("Frame", nil, frame)
        frame.PADDCenter:SetPoint("LEFT", frame, "LEFT", ActionBar.paddingPADD, 0)
        frame.PADDCenter:SetSize(1, 1)
    end

    if not frame.PADshadow then
        frame.PADshadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.PADshadow:SetPoint("CENTER", frame.PADCenter, "CENTER", 0, 0)
        frame.PADshadow:SetSize(ActionBar.shadowSize, ActionBar.shadowSize)
        frame.PADshadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        ConsoleMenu:InitFadeAnimations(frame.PADshadow, ActionBar.animationDuration)
    end

    if not frame.PADDshadow then
        frame.PADDshadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.PADDshadow:SetPoint("CENTER", frame.PADDCenter, "CENTER", 0, 0)
        frame.PADDshadow:SetSize(ActionBar.shadowSize, ActionBar.shadowSize)
        frame.PADDshadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        ConsoleMenu:InitFadeAnimations(frame.PADDshadow, ActionBar.animationDuration)
    end

    frame.actionButtons = {}

    for rangeIndex = 1, #slotRanges do
        local firstSlot = slotRanges[rangeIndex][1]
        local lastSlot = slotRanges[rangeIndex][2]
        for slotID = firstSlot, lastSlot do
            local btn = ActionBar.CreateButton(frame, slotID)
            if btn then
                btn.slotID = slotID
                frame.actionButtons[slotID] = btn
            end
        end
    end

    ActionBar.CreateBoosts(frame)
    ActionBar.EnableAllRangeChecks()

    -- Стандартная рамка скрывается с задержкой: облако обновляем, когда кнопка реально исчезла.
    if ExtraActionBarFrame and not ExtraActionBarFrame.consoleMenuBoostHooked then
        ExtraActionBarFrame.consoleMenuBoostHooked = true
        ExtraActionBarFrame:HookScript("OnShow", function()
            ActionBar.UpdateBoosts()
        end)
        ExtraActionBarFrame:HookScript("OnHide", function()
            ActionBar.UpdateBoosts()
        end)
    end

    for eventName in pairs(eventHandlers) do
        frame:RegisterEvent(eventName)
    end

    frame:SetScript("OnEvent", function(self, event, ...)
        local handler = eventHandlers[event]
        if handler then
            handler(self, event, ...)
        end
    end)

    frame.buttonsReady = true
end
