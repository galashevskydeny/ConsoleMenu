-- Создание окна панели команд, набор кнопок и обработка событий.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Создание панели команд и подписка на события ячеек.
function ConsoleMenu:InitializeMainActionBar()

    if ConsoleMenuDB.actionBarStyle == 1 then return end

    if not C_ActionBar.GetActionCooldown or not C_ActionBar.GetActionTexture then
        return
    end

    -- Создаём родительский фрейм для кнопок (если его ещё нет)
    if not ConsoleMenuFrame.ActionBarFrame then
        ConsoleMenuFrame.ActionBarFrame = CreateFrame("Frame", "ActionBarFrame", ConsoleMenuFrame)
    end

    local frame = ConsoleMenuFrame.ActionBarFrame

    frame:SetSize(ActionBar.frameWidth, ActionBar.frameHeight)
    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, 48)
    ConsoleMenu:InitFadeAnimations(frame, ActionBar.animationDuration)

    if not frame.PADCenter then
        frame.PADCenter = CreateFrame("Frame", "PADCenter", frame)
        frame.PADCenter:SetPoint("RIGHT", frame, "RIGHT", -ActionBar.paddingPAD, 0)
        frame.PADCenter:SetSize(1, 1)
    end

    if not frame.PADDCenter then
        frame.PADDCenter = CreateFrame("Frame", "PADDCenter", frame)
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

    for slotID = 1, 12 do
        local btn = ActionBar.CreateButton(frame, slotID)
        if btn then
            btn.slotID = slotID
            frame.actionButtons[slotID] = btn
        end
    end

    for slotID = 13, 24 do
        local btn = ActionBar.CreateButton(frame, slotID)
        if btn then
            btn.slotID = slotID
            frame.actionButtons[slotID] = btn
        end
    end

    for slotID = 49, 72 do
        local btn = ActionBar.CreateButton(frame, slotID)
        if btn then
            btn.slotID = slotID
            frame.actionButtons[slotID] = btn
        end
    end

    ActionBar.CreateBoosts(frame)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGIN")

    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SHOWGRID")
    frame:RegisterEvent("ACTIONBAR_HIDEGRID")

    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")

    frame:RegisterEvent("MODIFIER_STATE_CHANGED")

    frame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")

    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    frame:RegisterEvent("SPELL_UPDATE_ICON")

    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")

    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("ASSISTED_COMBAT_ACTION_SPELL_CAST")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")

    -- Обработка событий панели: значки, восстановление, свечение и видимость.
    local function OnActionBarEvent(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
            for slotID = 1, 12 do
                ActionBar.UpdateTexture(slotID)
                ActionBar.UpdateGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
                ActionBar.UpdateCount(slotID)
                
            end
            for slotID = 13, 24 do
                ActionBar.UpdateTexture(slotID)
                ActionBar.UpdateGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
                ActionBar.UpdateCount(slotID)
                
            end
            for slotID = 49, 72 do
                ActionBar.UpdateTexture(slotID)
                ActionBar.UpdateGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
                ActionBar.UpdateCount(slotID)
                
            end
            ActionBar.UpdateButtonPositions()
            ActionBar.UpdateCooldowns()
            ActionBar.UpdateBoosts()
            ActionBar.UpdateModifierState()
        elseif event == "GAME_PAD_ACTIVE_CHANGED" then
            ConsoleMenu:SetGamePadActive(...)
            ActionBar.UpdateButtonPositions()
            ActionBar.UpdateModifierState()
        elseif event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
            ActionBar.UpdateButtonPositions()
            ActionBar.UpdateModifierState()
        elseif event == "ACTIONBAR_PAGE_CHANGED" then
            RunNextFrame(ActionBar.UpdatePageVisibility)
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            local slotID = ...
            ActionBar.UpdateTexture(slotID)
            ActionBar.UpdateButtonPositions(slotID)
            ActionBar.UpdateCooldowns()
            ActionBar.UpdateCount(slotID)
            
            ActionBar.UpdateModifierState()
            -- Используем RunNextFrame для отложенной проверки glow, чтобы дать overlay системе время обновиться
            RunNextFrame(function()
                ActionBar.UpdateGlow(slotID, nil, "ACTIONBAR_SLOT_CHANGED")
            end)
            ActionBar.UpdateUsable(slotID)
            ActionBar.UpdateBoosts()
        elseif event == "ASSISTED_COMBAT_ACTION_SPELL_CAST" or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_SOFT_ENEMY_CHANGED" then
            -- Смена заклинания помощника или вход/выход из боя — обновляем иконки (в бою = следующее, вне боя = текущее)
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
            ActionBar.UpdateBoosts()
        elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_STATE" then
            ActionBar.UpdateCooldowns()
            ActionBar.UpdateBoosts()
        elseif event == "ACTION_RANGE_CHECK_UPDATE" then
            local slotID = ...
            if slotID then
                ActionBar.UpdateUsable(slotID)
            end
            ActionBar.UpdateBoosts()
        elseif event == "MODIFIER_STATE_CHANGED" then
            ActionBar.UpdateModifierState()
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            local spellID = ...
            local slots = C_ActionBar.FindSpellActionButtons(spellID)
            if slots then
                for _, slotID in pairs(slots) do
                    ActionBar.UpdateGlow(slotID, spellID, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            local spellID = ...
            local slots = C_ActionBar.FindSpellActionButtons(spellID)
            if slots then
                for _, slotID in pairs(slots) do
                    ActionBar.UpdateGlow(slotID, spellID, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
                end
            end
        elseif event == "SPELL_UPDATE_ICON" then
            -- Иконка может смениться позже свечения, в том числе при окончании прока.
            for slotID in pairs(frame.actionButtons or {}) do
                ActionBar.UpdateTexture(slotID)
            end
            ActionBar.UpdateBoosts()
        elseif event == "ACTIONBAR_UPDATE_USABLE" then
            local changes = ...
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
                        -- Поддержка плоского формата: значение = isUsable.
                        isUsable = changeData
                    end

                    ActionBar.UpdateUsable(slotID, isUsable, isLackingResources)
                end
            else
                ActionBar.UpdateCooldowns()
            end
            ActionBar.UpdateBoosts()
        elseif event == "SPELL_UPDATE_CHARGES" then
            for slotID = 1, 12 do
                ActionBar.UpdateCount(slotID)
                
            end
            for slotID = 13, 24 do
                ActionBar.UpdateCount(slotID)
                
            end
            for slotID = 49, 72 do
                ActionBar.UpdateCount(slotID)
                
            end
            ActionBar.UpdateBoosts()
        end
    end

    frame:SetScript("OnEvent", OnActionBarEvent)

end

