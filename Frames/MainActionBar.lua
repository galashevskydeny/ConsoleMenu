-- MainActionBar.lua

local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 688
local frameHeight = 196

local buttonSize = 52
local modelSize = 160
local modelOffset = 0.039
local modelScale = 0.017
-- Изначальный modelOffset подбирался на экране MacBook Pro (примерно 16:10).
local modelReferenceAspect = 16 / 10

local iconSize = 28
local stackCountSize = 24
local stackCountOffset = 8
local stackCountShadowOffsef = 12
local fontSize = 14

local paddingPAD = buttonSize * 1.5
local paddingPADD = buttonSize * 1.5

local buttonVerticalPadding = buttonSize * 0.6
local buttonHorizontalPadding = buttonSize * 0.6

local shadowSize = 320

local animationDuration = 0.05
local gamePadActive = false

local buttonPositions = {
    PADRSTICK = { "TOP", "PADCenter", "BOTTOM", 0, -buttonVerticalPadding },
    PADLSTICK = { "TOP", "PADDCenter", "BOTTOM", 0, -buttonVerticalPadding },

    PAD2 = { "LEFT", "PADCenter", "RIGHT", buttonHorizontalPadding, 0 },
    PAD3 = { "RIGHT", "PADCenter", "LEFT", -buttonHorizontalPadding, 0 },
    PAD4 = { "BOTTOM", "PADCenter", "TOP", 0, buttonVerticalPadding },

    PADDUP = { "BOTTOM", "PADDCenter", "TOP", 0, buttonVerticalPadding },
    PADDRIGHT = { "LEFT", "PADDCenter", "RIGHT", buttonHorizontalPadding, 0 },
    PADDLEFT = { "RIGHT", "PADDCenter", "LEFT", -buttonHorizontalPadding, 0 },
    PADDDOWN = { "TOP", "PADDCenter", "BOTTOM", 0, -buttonVerticalPadding },
}

local ignoredSlot = {
    [8] = true,
    [53] = true,
    [65] = true,
    [10] = true,
}

local stackCountChange = {}

-- Компенсация смещения под aspect ratio экрана,
-- чтобы glow-эффект PlayerModel оставался по центру кнопки.
local function GetGlowTransformOffset()
    local width, height = GetPhysicalScreenSize()
    if not width or not height or height == 0 then
        return modelOffset
    end

    local currentAspect = width / height
    if currentAspect <= 0 then
        return modelOffset
    end

    return modelOffset * (modelReferenceAspect / currentAspect)
end

-- Масштаб glow также нормализуем относительно эталонного aspect,
-- чтобы размер эффекта не "плавал" между экранами.
local function GetGlowTransformScale()
    local width, height = GetPhysicalScreenSize()
    if not width or not height or height == 0 then
        return modelScale
    end

    local currentAspect = width / height
    if currentAspect <= 0 then
        return modelScale
    end

    return modelScale * (modelReferenceAspect / currentAspect)
end

function ConsoleMenu:GetButtonPositions()
    return buttonPositions
end

function ConsoleMenu:IsSlotIgnored(slotID)
    return ignoredSlot[slotID]
end

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

-- Функция обновления иконки бинда
local function UpdateActionButtonIcon(slotID)
    local frame = ConsoleMenuFrame.ActionBarFrame
    local btn = frame.actionButtons[slotID]
    if not btn or not btn.Icon or not btn.Icon.Texture or not btn.mainKey then return end
    local mainKey = btn.mainKey

    -- Для пустых слотов иконку бинда не показываем.
    if not C_ActionBar.HasAction(slotID) then
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    local shouldShowIcon = (
        mainKey == "PADRSTICK" or
        mainKey == "PADLSTICK" or
        mainKey == "4" or
        mainKey == "5"
    )

    if not shouldShowIcon then
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    -- Обновление иконки
    local textureInfo = ConsoleMenu.Textures and ConsoleMenu.Textures[mainKey]
    local texture = textureInfo and textureInfo.texture
    if not texture or texture == "" then
        -- Во время боя биндинг/текстура могут обновляться неатомарно.
        -- Не трогаем текущую иконку, чтобы не получать неверное мигание.
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        ConsoleMenu:AnimatedHide(btn.Icon)
        return
    end

    btn.Icon.Texture:SetTexture(texture)
    ConsoleMenu:AnimatedShow(btn.Icon)
end

-- Функция обновления текстуры кнопки
local function UpdateActionButtonTexture(slotID)
    
    local frame = ConsoleMenuFrame.ActionBarFrame

    local btn = frame.actionButtons[slotID]
    if not btn or not btn.texture then return end

    local textureFileID = nil

    -- Однокнопочный помощник (Assisted Combat): иконка должна соответствовать заклинанию, которое будет применено
    if C_ActionBar and C_ActionBar.IsAssistedCombatAction and C_ActionBar.IsAssistedCombatAction(slotID) then
        if C_AssistedCombat and C_Spell then
            -- В бою — следующее заклинание в ротации; вне боя — текущее заклинание помощника
            local spellID = C_AssistedCombat.GetNextCastSpell and C_AssistedCombat.GetNextCastSpell(true)

            if spellID then
                textureFileID = C_Spell.GetSpellTexture(spellID)
            end
        end
    end

    if not textureFileID then
        textureFileID = C_ActionBar.GetActionTexture(slotID)
    end

    if issecretvalue(textureFileID) then
        -- Во время боя API может вернуть secret-значение.
        -- В этом случае не трогаем текущее состояние кнопки, чтобы не терять иконки.
        return
    end

    if textureFileID then
        btn.texture:SetTexture(textureFileID)
        btn.background:Show()
        -- Кнопка будет показана/скрыта в UpdateButtonPositions на основе биндинга
    else
        -- В бою API иногда временно возвращает nil даже для заполненного слота.
        -- В этом случае сохраняем текущую иконку, чтобы она не исчезала визуально.
        if InCombatLockdown and InCombatLockdown() and C_ActionBar.HasAction(slotID) then
            return
        end

        btn.texture:SetTexture(nil)
        btn.background:Hide()
        if btn.StackCount then
            ConsoleMenu:AnimatedHide(btn.StackCount)
        end
        if btn.Icon then
            ConsoleMenu:AnimatedHide(btn.Icon)
        end
    end

end

-- Функция обновления состояния иконки (пригодность, цвет, блокировка)
local function UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, isLackingResources)
    -- Получаем значения пригодности и недостатка маны если не заданы
    if isUsable == nil or isLackingResources == nil then
        if C_ActionBar and C_ActionBar.IsUsableAction then
            isUsable, isLackingResources = C_ActionBar.IsUsableAction(slotID)
        else
            isUsable, isLackingResources = true, false -- fallback
        end
    end

    if isUsable and (not btn.cooldown:IsShown() or btn.cooldown:IsShown() and IsGlobalCooldown(slotID)) then
        btn.texture:SetDesaturated(false)
    elseif isLackingResources then
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
local function UpdateActionButtonUsable(slotID, isUsable, isLackingResources)
    local frame = ConsoleMenuFrame.ActionBarFrame
    local btn = frame.actionButtons[slotID]
    if not btn or not btn.texture then return end
    
    UpdateActionButtonTextureDesaturation(btn, slotID, isUsable, isLackingResources)
end

-- Функция обновления отображения Glow модели
local function UpdateActionButtonGlow(slotID, spellID, event)

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

        btn.Glow:SetAlpha(1.0)
        btn.Glow:Show()

        ConsoleMenu:InitFadeAnimations(btn.Glow, animationDuration)
    end

    -- Переустанавливаем transform на каждом обновлении:
    -- это удерживает визуальный центр при разном соотношении сторон и смене разрешения.
    local transformOffset = GetGlowTransformOffset()
    btn.Glow:SetTransform(
        CreateVector3D(transformOffset, transformOffset, 0),
        CreateVector3D(0, 0, 0),
        GetGlowTransformScale()
    )

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
        if btn.cooldown then
            local info = C_ActionBar.GetActionCooldown(slotID)

            if info and info.isActive then
                local duration = C_ActionBar.GetActionCooldownDuration(slotID)

                btn.cooldown:SetCooldownFromDurationObject(duration)
                btn.cooldown:Show()
            else
                btn.cooldown:Clear()
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
        if position and (not modifierKey or (modifierKey and modifierKey == btn.modifierKey)) and C_ActionBar.HasAction(slotID) then
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
        local binding = ConsoleMenu:GetCommandBinding(command, gamePadActive)
        btn.binding = binding
        
        -- Всегда записываем mainKey: если есть дефис - извлекаем, если нет - весь binding
        local mainKey = binding and string.match(binding, ".-%-(.+)$")
        btn.mainKey = mainKey or binding
        btn.modifierKey = binding and string.match(binding, "^(.+)%-[^%-]+$")

        local position = buttonPositions[btn.mainKey]

        if position and not (ignoredSlot[slotID] == true) then
            ConsoleMenu:AnimatedShow(btn)
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        else
            ConsoleMenu:AnimatedHide(btn)
        end

        UpdateActionButtonIcon(slotID)
        UpdateActionButtonShadows()

        return
    end

    -- Обновление всех кнопок (если не передан slotID)
    for slotID, btn in pairs(frame.actionButtons) do
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        local binding = ConsoleMenu:GetCommandBinding(command, gamePadActive)
        btn.binding = binding
        
        -- Всегда записываем mainKey: если есть дефис - извлекаем, если нет - весь binding
        local mainKey = binding and string.match(binding, ".-%-(.+)$")
        btn.mainKey = mainKey or binding
        btn.modifierKey = binding and string.match(binding, "^(.+)%-[^%-]+$")

        local position = buttonPositions[btn.mainKey]
        if position and not (ignoredSlot[slotID] == true) then
            ConsoleMenu:AnimatedShow(btn)
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        else
            ConsoleMenu:AnimatedHide(btn)
        end

        UpdateActionButtonIcon(slotID)
    end

    UpdateActionButtonShadows()
end

-- Функция обновления набора иконок в зависимости от состояния модификаторов
local function UpdateModifierState()
    local frame = ConsoleMenuFrame.ActionBarFrame
    local modifierKey

    if not IsModifierKeyDown() then
        modifierKey = nil
    elseif IsControlKeyDown() then
        modifierKey = "CTRL"
    elseif IsShiftKeyDown() then
        modifierKey = "SHIFT"
    elseif IsAltKeyDown() then
        modifierKey = "ALT"
    end

    for slotID, btn in pairs(frame.actionButtons) do
        if modifierKey == btn.modifierKey then
            ConsoleMenu:AnimatedShow(btn)
        else
            ConsoleMenu:AnimatedHide(btn)
        end
    end

    UpdateActionButtonShadows(modifierKey)
end

local function UpdateActionButtonCount(slotID)
    local frame = ConsoleMenuFrame.ActionBarFrame
    local btn = frame.actionButtons[slotID]
    if not btn or not btn.StackCount or not btn.StackCount.Text then return end

    local count = C_ActionBar.GetActionDisplayCount(slotID)

    if count and issecretvalue(count) then
        -- Во время боя count может быть secret-значением.
        -- Обновляем только текст, но не меняем видимость фрейма,
        -- чтобы не возвращать баг с "вечным" фоном стаков.
        btn.StackCount.Text:SetText(count)
        return
    end

    if (count and count ~= "" and count ~= "0" and count ~= 0) or stackCountChange[slotID] then
        btn.StackCount.Text:SetText(count)
        stackCountChange[slotID] = true
        ConsoleMenu:AnimatedShow(btn.StackCount)
    else
        btn.StackCount.Text:SetText("")
        ConsoleMenu:AnimatedHide(btn.StackCount)
    end
end

-- Функция создания кнопки
local function CreateSpellBarButtonFrame(parent, slotID)
    local buttonFrame = CreateFrame("Frame", "ActionButton" .. slotID, parent)
    parent["ActionButton" .. slotID] = buttonFrame

    buttonFrame:SetSize(buttonSize, buttonSize)
    ConsoleMenu:InitFadeAnimations(buttonFrame, animationDuration)

    local textureFileID = C_ActionBar.GetActionTexture(slotID)
    if issecretvalue(textureFileID) then
        -- Не считаем слот пустым: просто отложим установку текстуры.
        textureFileID = nil
    end

    -- Добавляем фон под иконку, тоже текстура (создаем первым, чтобы был ниже)
    local background = buttonFrame:CreateTexture(nil, "BACKGROUND")
    local backgroundSize = buttonSize + 8
    background:SetPoint("CENTER", buttonFrame, "CENTER", 0, 0)
    background:SetSize(backgroundSize, backgroundSize)
    background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\pad-background.png")
    background:SetVertexColor(0, 0, 0, 1)
    buttonFrame.background = background

    local texture = buttonFrame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(buttonFrame)
    if textureFileID then
        texture:SetTexture(textureFileID)
        local edge = 3 / buttonSize
        texture:SetTexCoord(edge, 1 - edge, edge, 1 - edge)
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

    -- Счетчик стаков
    if not buttonFrame.StackCount then
        buttonFrame.StackCount = CreateFrame("Frame", "ActionButtonStackCount" .. slotID, buttonFrame)
        buttonFrame.StackCount:SetSize(stackCountSize, stackCountSize)
        buttonFrame.StackCount:SetPoint("BOTTOMRIGHT", buttonFrame.texture, "BOTTOMRIGHT", stackCountOffset, -stackCountOffset)
        ConsoleMenu:InitFadeAnimations(buttonFrame.StackCount, animationDuration)

        buttonFrame.StackCount:Hide()

        -- Фон счетчика
        if not buttonFrame.StackCount.Background then
            buttonFrame.StackCount.Background = buttonFrame.StackCount:CreateTexture(nil, "ARTWORK")
            buttonFrame.StackCount.Background:SetAllPoints()
            buttonFrame.StackCount.Background:SetAlpha(0.5)

            local texture = ConsoleMenu.Backgrounds["PAD"]
            buttonFrame.StackCount.Background:SetTexture(texture)
        end

        -- Тень счетчика
        if not buttonFrame.StackCount.Shadow then
            buttonFrame.StackCount.Shadow = buttonFrame.StackCount:CreateTexture(nil, "BACKGROUND")
            buttonFrame.StackCount.Shadow:SetPoint("TOPLEFT", buttonFrame.StackCount.Background, "TOPLEFT", -stackCountShadowOffsef, stackCountShadowOffsef)
            buttonFrame.StackCount.Shadow:SetPoint("BOTTOMRIGHT", buttonFrame.StackCount.Background, "BOTTOMRIGHT", stackCountShadowOffsef, -stackCountShadowOffsef)

            local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"
            buttonFrame.StackCount.Shadow:SetTexture(texture)
        end

        -- Текст счетчика
        if not buttonFrame.StackCount.Text then
            buttonFrame.StackCount.Text = buttonFrame.StackCount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            buttonFrame.StackCount.Text:SetAllPoints()
            buttonFrame.StackCount.Text:SetJustifyH("CENTER")
            buttonFrame.StackCount.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
            buttonFrame.StackCount.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
            buttonFrame.StackCount.Text:SetText("")
        end
    end

    -- Иконка клавиши
    if not buttonFrame.Icon then
        buttonFrame.Icon = CreateFrame("Frame", "ActionButtonIcon" .. slotID, buttonFrame)
        buttonFrame.Icon:SetSize(iconSize, iconSize)
        buttonFrame.Icon:SetPoint("TOPRIGHT", buttonFrame.texture, "TOPRIGHT", stackCountOffset, stackCountOffset)
        ConsoleMenu:InitFadeAnimations(buttonFrame.Icon, animationDuration)

        buttonFrame.Icon:Hide()

        --Иконка бинда
        if not buttonFrame.Icon.Texture then
            buttonFrame.Icon.Texture = buttonFrame.Icon:CreateTexture(nil, "ARTWORK")
            buttonFrame.Icon.Texture:SetAllPoints()
            buttonFrame.Icon.Texture:SetAlpha(1)

            local texture = ConsoleMenu.Backgrounds["PAD"]
            buttonFrame.Icon.Texture:SetTexture(texture)
        end

        -- Фон
        if not buttonFrame.Icon.Background then
            buttonFrame.Icon.Background = buttonFrame.Icon:CreateTexture(nil, "BACKGROUND")
            buttonFrame.Icon.Background:SetAllPoints()
            buttonFrame.Icon.Background:SetAlpha(0.75)

            local texture = ConsoleMenu.Backgrounds["STICK"]
            buttonFrame.Icon.Background:SetTexture(texture)
        end

        --Тень
        if not buttonFrame.Icon.Shadow then
            buttonFrame.Icon.Shadow = buttonFrame.Icon:CreateTexture(nil, "BACKGROUND")
            buttonFrame.Icon.Shadow:SetPoint("TOPLEFT", buttonFrame.Icon.Background, "TOPLEFT", -stackCountShadowOffsef, stackCountShadowOffsef)
            buttonFrame.Icon.Shadow:SetPoint("BOTTOMRIGHT", buttonFrame.Icon.Background, "BOTTOMRIGHT", stackCountShadowOffsef, -stackCountShadowOffsef)

            local texture = "Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png"
            buttonFrame.Icon.Shadow:SetTexture(texture)
        end
    end

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
        if btn then
            btn.slotID = slotID
            frame.actionButtons[slotID] = btn
        end
    end

    for slotID = 49, 72 do
        local btn = CreateSpellBarButtonFrame(frame, slotID)
        if btn then
            btn.slotID = slotID
            frame.actionButtons[slotID] = btn
        end
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGIN")

    frame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SHOWGRID")
    frame:RegisterEvent("ACTIONBAR_HIDEGRID")

    frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")

    frame:RegisterEvent("MODIFIER_STATE_CHANGED")

    frame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")

    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")

    frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")

    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("ASSISTED_COMBAT_ACTION_SPELL_CAST")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")

    local function OnActionBarEvent(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
            for slotID = 1, 12 do
                UpdateActionButtonTexture(slotID)
                UpdateActionButtonGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
                UpdateActionButtonCount(slotID)
                
            end
            for slotID = 49, 72 do
                UpdateActionButtonTexture(slotID)
                UpdateActionButtonGlow(slotID, nil, "PLAYER_ENTERING_WORLD")
                UpdateActionButtonCount(slotID)
                
            end
            UpdateButtonPositions()
            UpdateActionButtonCooldowns()
            UpdateModifierState()
        elseif event == "GAME_PAD_ACTIVE_CHANGED" then
            gamePadActive = ...
            UpdateButtonPositions()
            UpdateModifierState()
        elseif event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
            UpdateButtonPositions()
            UpdateModifierState()
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            local slotID = ...
            UpdateActionButtonTexture(slotID)
            UpdateButtonPositions(slotID)
            UpdateActionButtonCooldowns()
            UpdateActionButtonCount(slotID)
            
            UpdateModifierState()
            -- Используем RunNextFrame для отложенной проверки glow, чтобы дать overlay системе время обновиться
            RunNextFrame(function()
                UpdateActionButtonGlow(slotID, nil, "ACTIONBAR_SLOT_CHANGED")
            end)
            UpdateActionButtonUsable(slotID)
        elseif event == "ASSISTED_COMBAT_ACTION_SPELL_CAST" or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_SOFT_ENEMY_CHANGED" then
            -- Смена заклинания помощника или вход/выход из боя — обновляем иконки (в бою = следующее, вне боя = текущее)
            if C_ActionBar and C_ActionBar.FindAssistedCombatActionButtons then
                local slots = C_ActionBar.FindAssistedCombatActionButtons()
                if slots then
                    for _, slotID in pairs(slots) do
                        UpdateActionButtonTexture(slotID)
                        UpdateActionButtonIcon(slotID)
                        UpdateActionButtonCount(slotID)
                        
                    end
                end
            end
        elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_STATE" then
            UpdateActionButtonCooldowns()
        elseif event == "MODIFIER_STATE_CHANGED" then
            UpdateModifierState()
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            local spellID = ...
            local slots = C_ActionBar.FindSpellActionButtons(spellID)
            if slots then
                for _, slotID in pairs(slots) do
                    UpdateActionButtonGlow(slotID, spellID, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            local spellID = ...
            local slots = C_ActionBar.FindSpellActionButtons(spellID)
            if slots then
                for _, slotID in pairs(slots) do
                    UpdateActionButtonGlow(slotID, spellID, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
                end
            end
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

                    UpdateActionButtonUsable(slotID, isUsable, isLackingResources)
                end
            else
                UpdateActionButtonCooldowns()
            end
        elseif event == "SPELL_UPDATE_CHARGES" then
            for slotID = 1, 12 do
                UpdateActionButtonCount(slotID)
                
            end
            for slotID = 49, 72 do
                UpdateActionButtonCount(slotID)
                
            end
        end
    end

    frame:SetScript("OnEvent", OnActionBarEvent)

end

function ConsoleMenu:GetSlotTitle(actionType, id)
    if actionType == "macro" then
        if C_Macro and C_Macro.GetMacroSpell then
            local spellID = C_Macro.GetMacroSpell(id)
            if spellID then
                actionType = "spell"
                id = spellID
            end
        end
    end
    
    if actionType == "spell" then
        local spell = Spell:CreateFromSpellID(id)
        
        local name = spell:GetSpellName()
        return name
    end
    
    if actionType == "item" then
        local name = C_Item.GetItemNameByID(id)
        return name
    end
    
    if actionType == "macro" then
        local name = C_Macro.GetMacroName(id)
        return name
    end

    if actionType == "summonmount" then

        -- 268435455 - избранный маунт
        if id ~= 268435455 then
            local name = C_MountJournal.GetMountInfoByID(id)
            return name
        else
            return "Избранный маунт"
        end
    end

    if actionType == "outfit" then
        local info = C_TransmogOutfitInfo.GetOutfitInfo(id)
        return info.name
    end

end

