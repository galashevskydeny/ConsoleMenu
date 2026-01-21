-- MainActionBar.lua

local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 688
local frameHeight = 196

local buttonSize = 52
local modelSize = 160
local modelOffset = 0.039
local modelScale = 0.017

local paddingPAD = buttonSize * 1.5
local paddingPADD = buttonSize * 1.5

local buttonVerticalPadding = buttonSize * 0.6
local buttonHorizontalPadding = buttonSize * 0.6

local shadowSize = 272

local animationDuration = 0.05

local buttonPositions = {
    PADRSTICK = { "TOP", "PADCenter", "BOTTOM", 0, -buttonVerticalPadding },

    PAD2 = { "LEFT", "PADCenter", "RIGHT", buttonHorizontalPadding, 0 },
    PAD3 = { "RIGHT", "PADCenter", "LEFT", -buttonHorizontalPadding, 0 },
    PAD4 = { "BOTTOM", "PADCenter", "TOP", 0, buttonVerticalPadding },

    PADDUP = { "BOTTOM", "PADDCenter", "TOP", 0, buttonVerticalPadding },
    PADDRIGHT = { "LEFT", "PADDCenter", "RIGHT", buttonHorizontalPadding, 0 },
    PADDLEFT = { "RIGHT", "PADDCenter", "LEFT", -buttonHorizontalPadding, 0 },
    PADDDOWN = { "TOP", "PADDCenter", "BOTTOM", 0, -buttonVerticalPadding },
}

-- Проверка, является ли кулдаун глобальным кулдауном (GCD)
-- ВАЖНО: isOnGCD помечено как NeverSecret = true, поэтому безопасно для чтения
local function IsGlobalCooldown(slotID)
    if not slotID or not C_ActionBar or not C_ActionBar.GetActionCooldown then
        return false;
    end
    
    local cooldownInfo = C_ActionBar.GetActionCooldown(slotID);
    if cooldownInfo and cooldownInfo.isOnGCD then
        return true;
    end
    
    return false;
end

-- Функция обновления текстуры кнопки
local function UpdateActionButtonTexture(slotID)
    
    local frame = ConsoleMenuFrame.ActionBarFrame

    local btn = frame.actionButtons[slotID]
    if not btn or not btn.texture then return end

    local textureFileID = C_ActionBar.GetActionTexture(slotID)
    if issecretvalue(textureFileID) then
        -- Если слот пуст, скрываем кнопку
        btn.texture:SetTexture(nil)
        btn.background:Hide()
        ConsoleMenu:AnimatedHide(btn)
        return
    end

    if textureFileID then
        btn.texture:SetTexture(textureFileID)
        btn.background:Show()
        -- Кнопка будет показана/скрыта в UpdateButtonPositions на основе биндинга
    else
        btn.texture:SetTexture(nil)
        btn.background:Hide()
    end
end

-- Функция обновления состояния иконки (пригодность, цвет, блокировка)
local function UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, notEnoughMana)
    -- Получаем значения пригодности и недостатка маны если не заданы
    if isUsable == nil or notEnoughMana == nil then
        if C_ActionBar and C_ActionBar.IsUsableAction then
            isUsable, notEnoughMana = C_ActionBar.IsUsableAction(slotID)
        else
            isUsable, notEnoughMana = true, false -- fallback
        end
    end

    if isUsable and (not btn.cooldown:IsShown() or btn.cooldown:IsShown() and IsGlobalCooldown(slotID)) then
        btn.texture:SetDesaturated(false)
    elseif notEnoughMana then
        btn.texture:SetDesaturated(true)
    elseif btn.cooldown:IsShown() and not IsGlobalCooldown(slotID) then
        btn.texture:SetDesaturated(true)
    else
        btn.texture:SetDesaturated(true)
    end

    -- Проверка блокировки по уровню
    local isLevelLinkLocked = false
    if C_LevelLink and C_LevelLink.IsActionLocked then
        isLevelLinkLocked = C_LevelLink.IsActionLocked(slotID)
    end

    -- Десатурация и иконка блокировки
    if not btn.texture:IsDesaturated() then
        btn.texture:SetDesaturated(isLevelLinkLocked)
    end
end

-- Функция обновления отображения пригодности кнопки
local function UpdateActionButtonUsable(slotID, isUsable, notEnoughMana)
    local frame = ConsoleMenuFrame.ActionBarFrame
    local btn = frame.actionButtons[slotID]
    if not btn or not btn.texture then return end
    
    UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, notEnoughMana)
end

-- Функция обновления отображения Glow модели
local function UpdateActionButtonGlow(slotID, spellID, event)

    if event ~= "PLAYER_ENTERING_WORLD" then
        print("UpdateActionButtonGlow", slotID, spellID, event)
    end

    local frame = ConsoleMenuFrame.ActionBarFrame
    local btn = frame.actionButtons[slotID]
    if not btn then return end

    -- Фрейм для отображения M2 модели
    if not btn.Glow then
        btn.Glow = CreateFrame("PlayerModel", nil, btn)
        btn.Glow:SetSize(modelSize, modelSize)
        btn.Glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.Glow:SetFrameStrata(btn:GetFrameStrata())
        btn.Glow:SetFrameLevel(btn:GetFrameLevel() - 1)
        btn.Glow:SetModel(5201375)
        btn.Glow:SetParent(btn)
        btn.Glow:SetKeepModelOnHide(true)
        btn.Glow:SetAnimation(1)

        btn.Glow:SetTransform(
            CreateVector3D(modelOffset, modelOffset, 0),
            CreateVector3D(0, 0, 0),
            modelScale
        )
        btn.Glow:SetAlpha(1.0)
        btn.Glow:Show()

        ConsoleMenu:InitFadeAnimations(btn.Glow, animationDuration)
    end

    -- Если spellID не передан, пытаемся получить его из слота
    if not spellID then
        local actionType, id, _ = GetActionInfo(slotID)
        
        -- Если это не заклинание и не макрос, скрываем glow
        if actionType ~= "spell" and actionType ~= "macro" then
            ConsoleMenu:AnimatedHide(btn.Glow)
            return
        end

        spellID = id
    end

    -- Если spellID найден, проверяем актуальное состояние overlay
    if spellID then
        local isSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
        if isSpellOverlayed then
            ConsoleMenu:AnimatedShow(btn.Glow)
        else
            ConsoleMenu:AnimatedHide(btn.Glow)
        end
    else
        ConsoleMenu:AnimatedHide(btn.Glow)
    end
end

-- Функция обновления кулдаунов и доступности для всех кнопок
local function UpdateActionButtonCooldowns()
    local frame = ConsoleMenuFrame.ActionBarFrame

    for slotID, btn in pairs(frame.actionButtons) do
        -- Используем CooldownFrame для автоматической обработки secret values
        if btn.cooldown then
            local cooldownInfo = C_ActionBar.GetActionCooldown(slotID)
            if cooldownInfo then
                -- CooldownFrame:SetCooldown может принимать secret values напрямую
                btn.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.modRate)
            else
                btn.cooldown:Hide()
            end

            RunNextFrame(function()
                UpdateActionButtonTextureDesaturation(btn, slotID)
            end)

        end
    end
end

-- Функция отображения и скрытия теней групп кнопок
local function UpdateActionButtonShadows(modifierKey)
    local frame = ConsoleMenuFrame.ActionBarFrame

    local PADcount = 0
    local PADDcount = 0

    for slotID, btn in pairs(frame.actionButtons) do
        local mainKey = btn.mainKey
        local position = buttonPositions[mainKey]
        if position and (not modifierKey or (modifierKey and modifierKey == btn.modifierKey)) then
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

-- Функция обновления позиций кнопок
local function UpdateButtonPositions(slotID)
    local frame = ConsoleMenuFrame.ActionBarFrame

    -- Обновление позиции конкретной кнопки (если передан slotID)
    if slotID then
        local btn = frame.actionButtons[slotID]
        if not btn then return end
        
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        local binding = ConsoleMenu:GetCommandBinding(command)
        btn.binding = binding
        
        -- Всегда записываем mainKey: если есть дефис - извлекаем, если нет - весь binding
        local mainKey = binding and string.match(binding, ".-%-(.+)$")
        btn.mainKey = mainKey or binding
        btn.modifierKey = binding and string.match(binding, "^(.+)%-[^%-]+$")

        local position = buttonPositions[btn.mainKey]

        if position then
            ConsoleMenu:AnimatedShow(btn)
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        else
            ConsoleMenu:AnimatedHide(btn)
        end

        UpdateActionButtonShadows()

        return
    end

    -- Обновление всех кнопок (если не передан slotID)
    for slotID, btn in pairs(frame.actionButtons) do
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        local binding = ConsoleMenu:GetCommandBinding(command)
        btn.binding = binding
        
        -- Всегда записываем mainKey: если есть дефис - извлекаем, если нет - весь binding
        local mainKey = binding and string.match(binding, ".-%-(.+)$")
        btn.mainKey = mainKey or binding
        btn.modifierKey = binding and string.match(binding, "^(.+)%-[^%-]+$")

        local position = buttonPositions[btn.mainKey]
        if position then
            ConsoleMenu:AnimatedShow(btn)
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        else
            ConsoleMenu:AnimatedHide(btn)
        end
    end

    UpdateActionButtonShadows()
end

-- Функция обновления набора иконок в зависимости от состояния модификаторов
local function UpdateModifierState(modifierKey)
    local frame = ConsoleMenuFrame.ActionBarFrame

    for slotID, btn in pairs(frame.actionButtons) do
        if modifierKey == btn.modifierKey then
            ConsoleMenu:AnimatedShow(btn)
        else
            ConsoleMenu:AnimatedHide(btn)
        end
    end

    UpdateActionButtonShadows(modifierKey)
end

-- Функция создания кнопки
local function CreateSpellBarButtonFrame(parent, slotID)
    local buttonFrame = CreateFrame("Frame", "ActionButton" .. slotID, parent)
    parent["ActionButton" .. slotID] = buttonFrame

    buttonFrame:SetSize(buttonSize, buttonSize)
    ConsoleMenu:InitFadeAnimations(buttonFrame, animationDuration)

    local textureFileID = C_ActionBar.GetActionTexture(slotID)
    if issecretvalue(textureFileID) then return end

    -- Добавляем фон под иконку, тоже текстура (создаем первым, чтобы был ниже)
    local background = buttonFrame:CreateTexture(nil, "BACKGROUND")
    local backgroundSize = buttonSize + 8
    background:SetPoint("CENTER", buttonFrame, "CENTER", 0, 0)
    background:SetSize(backgroundSize, backgroundSize)
    background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pad-background.png")
    background:SetVertexColor(0, 0, 0, 0.4)
    buttonFrame.background = background

    local texture = buttonFrame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(buttonFrame)
    if textureFileID then
        texture:SetTexture(textureFileID)
    end
    
    -- Создаём маску для текстуры
    local mask = buttonFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    
    -- Сохраняем ссылку на текстуру в buttonFrame
    buttonFrame.texture = texture
    
    -- Создаём CooldownFrame для автоматической обработки кулдаунов
    local cooldown = CreateFrame("Cooldown", nil, buttonFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(buttonFrame)    
    cooldown:SetDrawBling(false)
    cooldown:SetDrawSwipe(false)
    cooldown:SetDrawEdge(false)

    
    buttonFrame.cooldown = cooldown
    
    buttonFrame.cooldown:HookScript("OnHide", function()
        -- Кулдаун исчез
        RunNextFrame(function()
            UpdateActionButtonTextureDesaturation(buttonFrame, slotID)
        end)
    end)

    buttonFrame.cooldown:SetScript("OnCooldownDone", function()
        -- Кулдаун закончился
        RunNextFrame(function()
            UpdateActionButtonTextureDesaturation(buttonFrame, slotID)
        end)
    end)

    buttonFrame:Show()
    return buttonFrame
end

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

    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, 48)
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    if not frame.PADCenter then
        frame.PADCenter = CreateFrame("Frame", "PADCenter", frame)
        frame.PADCenter:SetPoint("RIGHT", frame, "RIGHT", -paddingPAD, 0)
        frame.PADCenter:SetSize(1, 1)
    end

    if not frame.PADDCenter then
        frame.PADDCenter = CreateFrame("Frame", "PADDCenter", frame)
        frame.PADDCenter:SetPoint("LEFT", frame, "LEFT", paddingPADD, 0)
        frame.PADDCenter:SetSize(1, 1)
    end

    if not frame.PADshadow then
        frame.PADshadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.PADshadow:SetPoint("CENTER", frame.PADCenter, "CENTER", 0, 0)
        frame.PADshadow:SetSize(shadowSize, shadowSize)
        frame.PADshadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        ConsoleMenu:InitFadeAnimations(frame.PADshadow, animationDuration)
    end

    if not frame.PADDshadow then
        frame.PADDshadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.PADDshadow:SetPoint("CENTER", frame.PADDCenter, "CENTER", 0, 0)
        frame.PADDshadow:SetSize(shadowSize, shadowSize)
        frame.PADDshadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        ConsoleMenu:InitFadeAnimations(frame.PADDshadow, animationDuration)
    end

    frame.actionButtons = {}

    for slotID = 1, 12 do
        local btn = CreateSpellBarButtonFrame(frame, slotID)
        btn.slotID = slotID
        frame.actionButtons[slotID] = btn
    end

    for slotID = 49, 72 do
        local btn = CreateSpellBarButtonFrame(frame, slotID)
        btn.slotID = slotID
        frame.actionButtons[slotID] = btn
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGIN")

    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SHOWGRID")
    frame:RegisterEvent("ACTIONBAR_HIDEGRID")

    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")

    frame:RegisterEvent("MODIFIER_STATE_CHANGED")

    frame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")

    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")

    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")

    local function OnActionBarEvent(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
            for slotID = 1, 12 do
                UpdateActionButtonTexture(slotID)
                UpdateActionButtonGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
            end
            for slotID = 49, 72 do
                UpdateActionButtonTexture(slotID)
                UpdateActionButtonGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
            end
            UpdateButtonPositions()
            UpdateActionButtonCooldowns()
            UpdateModifierState()
        elseif event == "GAME_PAD_ACTIVE_CHANGED" or event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
            UpdateButtonPositions()
            UpdateModifierState()
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            local slotID = ...
            UpdateActionButtonTexture(slotID)
            UpdateButtonPositions(slotID)
            UpdateActionButtonCooldowns()
            -- Используем RunNextFrame для отложенной проверки glow, чтобы дать overlay системе время обновиться
            RunNextFrame(function()
                UpdateActionButtonGlow(slotID, nil, "ACTIONBAR_SLOT_CHANGED")
            end)
            UpdateActionButtonUsable(slotID)
        elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_STATE" or event == "ACTIONBAR_UPDATE_USABLE" then
            UpdateActionButtonCooldowns()
        elseif event == "MODIFIER_STATE_CHANGED" then
            if not IsModifierKeyDown() then
                UpdateModifierState()
            elseif IsControlKeyDown() then
                UpdateModifierState("CTRL")
            elseif IsShiftKeyDown() then
                UpdateModifierState("SHIFT")
            elseif IsAltKeyDown() then
                UpdateModifierState("ALT")
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            local spellID = ...
            local slots = C_ActionBar.FindSpellActionButtons(spellID)
            for _, slotID in pairs(slots) do
                UpdateActionButtonGlow(slotID, spellID, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            local spellID = ...
            local slots = C_ActionBar.FindSpellActionButtons(spellID)
            for _, slotID in pairs(slots) do
                UpdateActionButtonGlow(slotID, spellID, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
            end
        elseif event == "ACTIONBAR_UPDATE_USABLE" then
            local changes = ...
            for slotID, isUsable, notEnoughMana in pairs(changes) do
                UpdateActionButtonUsable(slotID, isUsable, notEnoughMana)
            end
        end
    end

    frame:SetScript("OnEvent", OnActionBarEvent)

end

