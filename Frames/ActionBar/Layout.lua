-- Раскладка кнопок: положения по клавишам, видимость страницы и тени групп.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Ячейка относится к текущей странице основной панели.
local function IsSlotOnActiveActionBarPage(slotID)
    if slotID < 1 or slotID > 24 then
        return false
    end
    if not C_ActionBar or not C_ActionBar.GetActionBarPage then
        return true
    end

    local page = C_ActionBar.GetActionBarPage()
    local startSlot = 12 * (page - 1) + 1
    return slotID >= startSlot and slotID < startSlot + 12
end

-- Нужно ли показывать кнопку при текущей дополнительной клавише.
local function IsActionButtonVisible(slotID, btn, activeModifier)
    if ActionBar.ignoredSlot[slotID] or not ActionBar.buttonPositions[btn.mainKey] then
        return false
    end

    -- Подсказка тачпада (слот 12): только при наличии действия и названия
    if ActionBar.slot12Slots[slotID] then
        if not C_ActionBar.HasAction(slotID) then
            return false
        end
        local actionType, id, subType = GetActionInfo(slotID)
        if not ConsoleMenu:GetSlotTitle(actionType, id, subType, slotID) then
            return false
        end
    end

    if slotID >= 1 and slotID <= 24 then
        if activeModifier then
            return false
        end
        return IsSlotOnActiveActionBarPage(slotID)
    end

    if activeModifier then
        return activeModifier == btn.modifierKey
    end

    return false
end

-- Текущая удерживаемая дополнительная клавиша.
local function GetActiveModifier()
    if not IsModifierKeyDown() then
        return nil
    end
    if IsControlKeyDown() then
        return "CTRL"
    end
    if IsShiftKeyDown() then
        return "SHIFT"
    end
    if IsAltKeyDown() then
        return "ALT"
    end
    return nil
end

-- Показ и скрытие теней левой и правой групп кнопок.
local function UpdateActionButtonShadows(activeModifier)
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local PADcount = 0
    local PADDcount = 0

    for slotID, btn in pairs(frame.actionButtons) do
        local position = ActionBar.buttonPositions[btn.mainKey]
        if position and C_ActionBar.HasAction(slotID) and IsActionButtonVisible(slotID, btn, activeModifier) then
            if position[2] == "PADCenter" then
                PADcount = PADcount + 1
            elseif position[2] == "PADDCenter" then
                PADDcount = PADDcount + 1
            end
        end
    end

    if PADcount > 0 then
        ConsoleMenu:AnimatedShow(frame.PADshadow)
    else
        ConsoleMenu:AnimatedHide(frame.PADshadow)
    end

    if PADDcount > 0 then
        ConsoleMenu:AnimatedShow(frame.PADDshadow)
    else
        ConsoleMenu:AnimatedHide(frame.PADDshadow)
    end
end

-- Привязка кнопок к положениям по назначению клавиш.
local function UpdateButtonPositions(slotID)
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    -- Обновление позиции конкретной кнопки (если передан slotID)
    if slotID then
        local btn = frame.actionButtons[slotID]
        if not btn then return end
        
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        local binding = ConsoleMenu:GetCommandBinding(command, ConsoleMenu:IsGamePadActive())
        btn.binding = binding

        local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
        btn.mainKey = mainKey
        btn.modifierKey = modifierKey

        local position = ActionBar.buttonPositions[btn.mainKey]

        if position and not (ActionBar.ignoredSlot[slotID] == true) then
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        end

        ActionBar.UpdateIcon(slotID)

        return
    end

    -- Обновление всех кнопок (если не передан slotID)
    for slotID, btn in pairs(frame.actionButtons) do
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        local binding = ConsoleMenu:GetCommandBinding(command, ConsoleMenu:IsGamePadActive())
        btn.binding = binding

        local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
        btn.mainKey = mainKey
        btn.modifierKey = modifierKey

        local position = ActionBar.buttonPositions[btn.mainKey]
        if position and not (ActionBar.ignoredSlot[slotID] == true) then
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        end

        ActionBar.UpdateIcon(slotID)
    end
end

-- Смена набора кнопок при удержании дополнительной клавиши.
local function UpdateModifierState()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local activeModifier = GetActiveModifier()

    for slotID, btn in pairs(frame.actionButtons) do
        if IsActionButtonVisible(slotID, btn, activeModifier) then
            ConsoleMenu:AnimatedShow(btn)
        else
            ConsoleMenu:AnimatedHide(btn)
        end
    end

    UpdateActionButtonShadows(activeModifier)
end

ActionBar.UpdateButtonPositions = UpdateButtonPositions
ActionBar.UpdateModifierState = UpdateModifierState
