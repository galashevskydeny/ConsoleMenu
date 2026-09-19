local ConsoleMenu = _G.ConsoleMenu
local Nameplates = ConsoleMenu.Nameplates

-- Диапазоны ячеек панели, которые использует консольная схема.
local interruptSlotRanges = {
    { 1, 12 },
    { 13, 24 },
    { 49, 72 },
}

-- Верхний цвет вертикального градиента значка кнопки.
local iconGradientTop = CreateColor(0xF3 / 255, 0xE8 / 255, 0xA1 / 255, 1)
-- Нижний цвет вертикального градиента значка кнопки.
local iconGradientBottom = CreateColor(0xD1 / 255, 0xB3 / 255, 0x62 / 255, 1)

-- Найденный слот прерывающего заклинания.
local interruptSlot = nil
-- Привязка кнопки для найденного слота.
local interruptBinding = nil
-- Слот, для которого включена проверка дальности.
local rangeCheckSlot = nil

-- Скрытый кадр перезарядки: в бою длительность секретна, видимость кадра — нет.
local cooldownTrackerHost = CreateFrame("Frame", nil, UIParent)
cooldownTrackerHost:SetSize(1, 1)
cooldownTrackerHost:SetAlpha(0)
cooldownTrackerHost:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
cooldownTrackerHost:Show()

local cooldownTracker = CreateFrame("Cooldown", nil, cooldownTrackerHost, "CooldownFrameTemplate")
cooldownTracker:SetAllPoints()
cooldownTracker:SetDrawBling(false)
cooldownTracker:SetDrawSwipe(false)
cooldownTracker:SetDrawEdge(false)
cooldownTracker:Hide()

-- Заливает текстуру значка вертикальным градиентом.
local function ApplyIconGradient(texture)
    texture:SetGradient("VERTICAL", iconGradientBottom, iconGradientTop)
end

-- Проверяет, задана ли кнопка геймпада для эмуляции модификатора.
local function IsEmulatedGamePadButton(value)
    return value and value ~= "" and string.upper(value) ~= "NONE"
end

-- Проверяет, есть ли пригодная текстура для клавиши.
local function HasUsableTexture(textureInfo)
    return textureInfo and textureInfo.texture and textureInfo.texture ~= ""
end

-- Подставляет кнопку геймпада вместо модификатора, если она задана в настройках.
local function ResolveModifierKey(modifierKey)
    if not ConsoleMenu:IsGamePadActive() or not modifierKey then
        return modifierKey
    end

    local cvarName
    if modifierKey == "SHIFT" then
        cvarName = "GamePadEmulateShift"
    elseif modifierKey == "CTRL" then
        cvarName = "GamePadEmulateCtrl"
    elseif modifierKey == "ALT" then
        cvarName = "GamePadEmulateAlt"
    else
        return modifierKey
    end

    local emulated = GetCVar(cvarName)
    if IsEmulatedGamePadButton(emulated) and HasUsableTexture(ConsoleMenu.Textures[emulated]) then
        return emulated
    end

    return modifierKey
end

-- Проверяет, можно ли нарисовать подсказку по привязке.
local function CanShowKeyBinding(binding)
    if not binding then
        return false
    end

    local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
    modifierKey = ResolveModifierKey(modifierKey)

    if modifierKey then
        return HasUsableTexture(ConsoleMenu.Textures[mainKey]) and HasUsableTexture(ConsoleMenu.Textures[modifierKey])
    end

    return HasUsableTexture(ConsoleMenu.Textures[mainKey])
end

-- Возвращает привязку кнопки для слота панели.
local function GetSlotBinding(slotID)
    if not slotID or not ConsoleMenu.GetBindingCommandBySlotID then
        return nil
    end

    local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
    if not command then
        return nil
    end

    return ConsoleMenu:GetCommandBinding(command, ConsoleMenu:IsGamePadActive())
end

-- Включает слежение за дальностью найденного слота.
local function UpdateRangeCheck(slotID)
    if not C_ActionBar or not C_ActionBar.EnableActionRangeCheck then
        rangeCheckSlot = slotID
        return
    end

    if rangeCheckSlot and rangeCheckSlot ~= slotID then
        pcall(C_ActionBar.EnableActionRangeCheck, rangeCheckSlot, false)
    end

    if slotID then
        pcall(C_ActionBar.EnableActionRangeCheck, slotID, true)
    end

    rangeCheckSlot = slotID
end

-- Ищет слот прерывающего заклинания с рисуемой кнопкой.
function Nameplates.RefreshInterruptSlot()
    local foundSlot = nil
    local foundBinding = nil

    if C_ActionBar and C_ActionBar.IsInterruptAction then
        for _, range in ipairs(interruptSlotRanges) do
            for slotID = range[1], range[2] do
                local hasAction = C_ActionBar.HasAction and C_ActionBar.HasAction(slotID)
                if hasAction then
                    local ok, isInterrupt = pcall(C_ActionBar.IsInterruptAction, slotID)
                    if ok and isInterrupt then
                        local binding = GetSlotBinding(slotID)
                        if CanShowKeyBinding(binding) then
                            foundSlot = slotID
                            foundBinding = binding
                            break
                        end
                    end
                end
            end
            if foundSlot then
                break
            end
        end
    end

    interruptSlot = foundSlot
    interruptBinding = foundBinding
    UpdateRangeCheck(interruptSlot)
    Nameplates.UpdateInterruptCooldown()
end

-- Разбирает таблицу изменений доступности так же, как панель действий.
local function ParseUsableChange(changeData)
    if type(changeData) == "table" then
        local isUsable = changeData.isUsable
        if isUsable == nil then
            isUsable = changeData[1]
        end
        return isUsable
    end

    return changeData
end

-- Передаёт длительность слота в скрытый кадр, не читая секретные числа.
function Nameplates.UpdateInterruptCooldown()
    if not interruptSlot or not C_ActionBar or not C_ActionBar.GetActionCooldownDuration then
        cooldownTracker:Clear()
        cooldownTracker:Hide()
        return
    end

    local duration = C_ActionBar.GetActionCooldownDuration(interruptSlot)
    if duration then
        cooldownTracker:SetCooldownFromDurationObject(duration)
    else
        cooldownTracker:Clear()
        cooldownTracker:Hide()
    end
end

-- Возвращает истину, если слот на собственной перезарядке, а не на общем восстановлении.
local function IsInterruptOnOwnCooldown()
    if not interruptSlot or not cooldownTracker:IsShown() then
        return false
    end

    if not C_ActionBar or not C_ActionBar.GetActionCooldown then
        return true
    end

    local cooldownInfo = C_ActionBar.GetActionCooldown(interruptSlot)
    if cooldownInfo and cooldownInfo.isOnGCD then
        return false
    end

    return true
end

-- Возвращает, можно ли сейчас применить прерывание в слоте.
local function IsInterruptUsable(usableOverride)
    if usableOverride ~= nil then
        return usableOverride and true or false
    end

    if not interruptSlot or not C_ActionBar or not C_ActionBar.IsUsableAction then
        return false
    end

    local isUsable = C_ActionBar.IsUsableAction(interruptSlot)
    return isUsable and true or false
end

-- Возвращает, находится ли существо в зоне действия прерывания.
local function IsInterruptInRange(unit)
    if not interruptSlot or not unit then
        return false
    end

    if not C_ActionBar or not C_ActionBar.IsActionInRange then
        return true
    end

    local ok, isInRange = pcall(C_ActionBar.IsActionInRange, interruptSlot, unit)
    return ok and isInRange == true
end

-- Возвращает истину, если индикатор принадлежит цели или софт-цели.
function Nameplates.IsInterruptHintUnit(unit)
    if not unit then
        return false
    end

    local isTarget = UnitExists("target") and UnitIsUnit(unit, "target")
    local isSoftEnemy = UnitExists("softenemy") and UnitIsUnit(unit, "softenemy")
    return isTarget or isSoftEnemy
end

-- Раскладывает значок кнопки или сочетания кнопок на подсказке.
local function ApplyInterruptHintIcon(hint)
    if not hint or not interruptBinding then
        return false
    end

    local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(interruptBinding)
    modifierKey = ResolveModifierKey(modifierKey)

    local iconSize = Nameplates.interruptHintSize
    local plusSize = Nameplates.interruptHintPlusSize
    local innerPadding = Nameplates.interruptHintInnerPadding

    if modifierKey then
        local mainTextureInfo = ConsoleMenu.Textures[mainKey]
        local modifierTextureInfo = ConsoleMenu.Textures[modifierKey]
        if not HasUsableTexture(mainTextureInfo) or not HasUsableTexture(modifierTextureInfo) then
            return false
        end

        hint.PlusTexture:Show()
        hint.ModifierTexture:Show()

        local width = iconSize * 2 + plusSize + innerPadding * 2 + innerPadding
        hint:SetSize(width, iconSize)

        hint.Background:SetTexture(ConsoleMenu.Backgrounds["PAIR"])
        hint.MainTexture:ClearAllPoints()
        hint.MainTexture:SetPoint("RIGHT", hint, "RIGHT", -innerPadding, 0)
        hint.MainTexture:SetSize(iconSize, iconSize)
        hint.MainTexture:SetTexture(mainTextureInfo.texture)

        hint.PlusTexture:ClearAllPoints()
        hint.PlusTexture:SetPoint("RIGHT", hint.MainTexture, "LEFT", -innerPadding / 2, 0)
        hint.PlusTexture:SetSize(plusSize, plusSize)

        hint.ModifierTexture:ClearAllPoints()
        hint.ModifierTexture:SetPoint("RIGHT", hint.PlusTexture, "LEFT", -innerPadding / 2, 0)
        hint.ModifierTexture:SetSize(iconSize, iconSize)
        hint.ModifierTexture:SetTexture(modifierTextureInfo.texture)
        return true
    end

    local textureInfo = ConsoleMenu.Textures[mainKey]
    if not HasUsableTexture(textureInfo) then
        return false
    end

    hint.PlusTexture:Hide()
    hint.ModifierTexture:Hide()
    hint:SetSize(iconSize, iconSize)

    hint.Background:SetTexture(textureInfo.background)
    hint.MainTexture:ClearAllPoints()
    hint.MainTexture:SetAllPoints()
    hint.MainTexture:SetTexture(textureInfo.texture)
    return true
end

-- Создаёт значок кнопки прерывания справа от полосы чтения.
function Nameplates.CreateInterruptHint(parent)
    local hint = CreateFrame("Frame", nil, parent)
    local iconSize = Nameplates.interruptHintSize
    hint:SetSize(iconSize, iconSize)
    hint:SetPoint("LEFT", parent, "RIGHT", Nameplates.castIconSpacing, 0)
    hint:SetFrameLevel(parent:GetFrameLevel() + 5)
    hint:Hide()

    hint.Background = hint:CreateTexture(nil, "BACKGROUND")
    hint.Background:SetAllPoints()

    hint.MainTexture = hint:CreateTexture(nil, "ARTWORK")
    hint.MainTexture:SetAllPoints()
    ApplyIconGradient(hint.MainTexture)

    hint.PlusTexture = hint:CreateTexture(nil, "ARTWORK")
    hint.PlusTexture:SetSize(Nameplates.interruptHintPlusSize, Nameplates.interruptHintPlusSize)
    hint.PlusTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plus.png")
    ApplyIconGradient(hint.PlusTexture)
    hint.PlusTexture:Hide()

    hint.ModifierTexture = hint:CreateTexture(nil, "ARTWORK")
    hint.ModifierTexture:SetSize(iconSize, iconSize)
    ApplyIconGradient(hint.ModifierTexture)
    hint.ModifierTexture:Hide()

    return hint
end

-- Показывает или скрывает подсказку прерывания на полосе чтения.
-- Непрерываемость читается прозрачностью родительской полосы, а не ветвлением.
function Nameplates.UpdateInterruptHint(large, unit, _, usableOverride)
    local hint = large and large.interruptHint
    if not hint then
        return
    end

    if not unit or not interruptSlot then
        hint:Hide()
        return
    end

    if not Nameplates.IsInterruptHintUnit(unit) then
        hint:Hide()
        return
    end

    if not IsInterruptUsable(usableOverride) then
        hint:Hide()
        return
    end

    if IsInterruptOnOwnCooldown() then
        hint:Hide()
        return
    end

    if not IsInterruptInRange(unit) then
        hint:Hide()
        return
    end

    if not ApplyInterruptHintIcon(hint) then
        hint:Hide()
        return
    end

    hint:Show()
end

-- Обновляет подсказки на всех показанных индикаторах.
function Nameplates.RefreshInterruptHints(usableOverride)
    if not Nameplates.ForEachActiveDisplay then
        return
    end

    Nameplates.ForEachActiveDisplay(function(display)
        if display.isEnemy and display.castLarge then
            Nameplates.UpdateInterruptHint(display.castLarge, display.unit, nil, usableOverride)
        end
    end)
end

-- Заново ищет слот прерывания и обновляет подсказки.
function Nameplates.RefreshInterruptState(usableOverride)
    Nameplates.RefreshInterruptSlot()
    Nameplates.RefreshInterruptHints(usableOverride)
end

-- Берёт доступность из события панели, если оно относится к слоту прерывания.
local function UsableOverrideFromChanges(changes)
    if not changes or not interruptSlot then
        return nil
    end

    local changeData = changes[interruptSlot]
    if changeData == nil then
        return nil
    end

    return ParseUsableChange(changeData)
end

-- Подписывается на события слотов, заклинаний, цели и дальности.
function Nameplates.RegisterInterruptEvents()
    local frame = Nameplates.interruptEventFrame
    if not frame then
        frame = CreateFrame("Frame")
        Nameplates.interruptEventFrame = frame
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    frame:RegisterEvent("SPELL_UPDATE_ICON")
    frame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")

    cooldownTracker:SetScript("OnCooldownDone", function()
        Nameplates.RefreshInterruptHints()
    end)
    cooldownTracker:HookScript("OnHide", function()
        Nameplates.RefreshInterruptHints()
    end)

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
            Nameplates.RefreshInterruptState()
        elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" then
            Nameplates.RefreshInterruptState()
        elseif event == "ACTIONBAR_UPDATE_STATE" or event == "SPELL_UPDATE_ICON" then
            Nameplates.RefreshInterruptState()
        elseif event == "ACTIONBAR_UPDATE_USABLE" then
            local changes = ...
            local usableOverride = UsableOverrideFromChanges(changes)
            Nameplates.RefreshInterruptHints(usableOverride)
        elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
            Nameplates.UpdateInterruptCooldown()
            Nameplates.RefreshInterruptHints()
        elseif event == "ACTION_RANGE_CHECK_UPDATE" then
            local slot = ...
            if not interruptSlot or slot == interruptSlot then
                Nameplates.RefreshInterruptHints()
            end
        elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_SOFT_ENEMY_CHANGED" then
            Nameplates.RefreshInterruptHints()
        elseif event == "GAME_PAD_ACTIVE_CHANGED" then
            ConsoleMenu:SetGamePadActive(...)
            Nameplates.RefreshInterruptState()
        end
    end)

    Nameplates.RefreshInterruptState()
end
