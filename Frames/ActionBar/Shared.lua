-- Общие сведения панели команд: размеры, положения кнопок и скрытые ячейки.

local ConsoleMenu = _G.ConsoleMenu

ConsoleMenu.ActionBar = ConsoleMenu.ActionBar or {}

local ActionBar = ConsoleMenu.ActionBar

ActionBar.frameWidth = 688
ActionBar.frameHeight = 196

ActionBar.buttonSize = 52
ActionBar.modelSize = 160
ActionBar.modelOffset = 0.039
ActionBar.modelScale = 0.017
-- Изначальный отступ модели подбирался на экране MacBook Pro (примерно 16:10).
ActionBar.modelReferenceAspect = 16 / 10

ActionBar.iconSize = 28
ActionBar.stackCountSize = 24
ActionBar.stackCountOffset = 8
ActionBar.stackCountShadowOffsef = 12
ActionBar.fontSize = 14

ActionBar.paddingPAD = ActionBar.buttonSize * 1.5
ActionBar.paddingPADD = ActionBar.buttonSize * 1.5

ActionBar.buttonVerticalPadding = ActionBar.buttonSize * 0.6
ActionBar.buttonHorizontalPadding = ActionBar.buttonSize * 0.6

ActionBar.slot12ContainerWidth = 190
ActionBar.slot12ContainerHeight = 70
ActionBar.slot12LabelFontSize = 16
-- Отступ иконки от края фона = вертикальный зазор (фон круга 60 при высоте 70)
ActionBar.slot12IconPadding = (ActionBar.slot12ContainerHeight - (ActionBar.buttonSize + 8)) / 2
ActionBar.slot12LabelGap = ActionBar.slot12IconPadding + 6
ActionBar.slot12LabelEdgePadding = ActionBar.slot12IconPadding
ActionBar.slot12LabelRightPadding = ActionBar.slot12IconPadding + 12
-- Высота верхнего ряда значков с учётом внутреннего отступа панельки тачпада.
ActionBar.topRowOffsetY = ActionBar.buttonVerticalPadding + ActionBar.buttonSize / 2 + ActionBar.slot12IconPadding

ActionBar.shadowSize = 320
-- Ареол правой группы чуть крупнее, пока в свёрнутом облаке есть дополнительное действие.
ActionBar.shadowSizeWithExtra = 384

ActionBar.animationDuration = 0.05

ActionBar.buttonPositions = {
    PADRSTICK = { "TOP", "PADCenter", "BOTTOM", 0, -ActionBar.buttonVerticalPadding },
    PADLSTICK = { "TOP", "PADDCenter", "BOTTOM", 0, -ActionBar.buttonVerticalPadding },

    PAD2 = { "LEFT", "PADCenter", "RIGHT", ActionBar.buttonHorizontalPadding, 0 },
    PAD3 = { "RIGHT", "PADCenter", "LEFT", -ActionBar.buttonHorizontalPadding, 0 },
    PAD4 = { "BOTTOM", "PADCenter", "TOP", 0, ActionBar.buttonVerticalPadding },

    PADDUP = { "BOTTOM", "PADDCenter", "TOP", 0, ActionBar.buttonVerticalPadding },
    PADDRIGHT = { "LEFT", "PADDCenter", "RIGHT", ActionBar.buttonHorizontalPadding, 0 },
    PADDLEFT = { "RIGHT", "PADDCenter", "LEFT", -ActionBar.buttonHorizontalPadding, 0 },
    PADDDOWN = { "TOP", "PADDCenter", "BOTTOM", 0, -ActionBar.buttonVerticalPadding },

    -- Сенсорная панель DualSense: по центру, на высоте верхнего ряда крестовины и лицевых кнопок
    PAD6 = { "CENTER", "ActionBarFrame", "CENTER", 0, ActionBar.topRowOffsetY },
    PADBACK = { "CENTER", "ActionBarFrame", "CENTER", 0, ActionBar.topRowOffsetY },
}

-- Слоты ACTIONBUTTON12 / MULTIACTIONBAR*BUTTON12
ActionBar.slot12Slots = {
    [12] = true,
    [24] = true,
    [60] = true,
    [72] = true,
}

ActionBar.ignoredSlot = {
    [8] = true,
    [20] = true,
    [53] = true,
}

-- Ячейки второй панели на крестовине: вверх, вправо, вниз, влево.
ActionBar.boostSlots = {
    { slotID = 66, key = "UP" },
    { slotID = 67, key = "RIGHT" },
    { slotID = 68, key = "DOWN" },
    { slotID = 69, key = "LEFT" },
}

ActionBar.boostSlotLookup = {
    [66] = true,
    [67] = true,
    [68] = true,
    [69] = true,
}

-- Облако чуть крупнее обычного умения; после разворота значки садятся на PAD4, PAD2, PAD1 и PAD3.
ActionBar.boostClusterSize = 200
ActionBar.boostCloudSizes = { 34, 39.95, 28.05, 32.3 }
ActionBar.boostExpandOffset = ActionBar.buttonVerticalPadding + ActionBar.buttonSize / 2
-- Покой у правого рычага. Крупные ближе к центру, мелкие дальше, чтобы силуэт читался кругом.
-- Стороны нарочно не совпадают с разворотом, чтобы значки перелетали крест-накрест.
ActionBar.boostCloudOffsets = {
    { x = -9.867, y = -5.6925 - ActionBar.boostExpandOffset },
    { x = -3.795, y = 6.578 - ActionBar.boostExpandOffset },
    { x = 13.156, y = 7.59 - ActionBar.boostExpandOffset },
    { x = 6.325, y = -11.0055 - ActionBar.boostExpandOffset },
}
-- Точки покоя четырёх значков, когда в центре облака дополнительное действие.
-- На 15% ближе к центру, чтобы облако было кучнее.
ActionBar.boostCloudOffsetsWithExtra = {
    { x = -20.968, y = -12.096 - ActionBar.boostExpandOffset },
    { x = -8.065, y = 13.978 - ActionBar.boostExpandOffset },
    { x = 21.25, y = 12.257 - ActionBar.boostExpandOffset },
    { x = 13.441, y = -23.387 - ActionBar.boostExpandOffset },
}
-- В присутствии дополнительного действия остальные значки чуть мельче, но ближе к его размеру.
ActionBar.boostCloudSizesWithExtra = { 27.88, 32.76, 23.0, 26.49 }
-- PAD4 сверху, PAD2 справа, PAD1 снизу, PAD3 слева.
ActionBar.boostExpandPositions = {
    { x = 0, y = ActionBar.boostExpandOffset },
    { x = ActionBar.boostExpandOffset, y = 0 },
    { x = 0, y = -ActionBar.boostExpandOffset },
    { x = -ActionBar.boostExpandOffset, y = 0 },
}
-- Дополнительная кнопка действия: самый крупный значок в центре облака.
ActionBar.boostExtraCloudSize = 46
-- Покой у правого рычага, посадка в центре панели — в координатах самой панели.
ActionBar.boostExtraRestX = ActionBar.frameWidth / 2 - ActionBar.paddingPAD
ActionBar.boostExtraRestY = -ActionBar.boostExpandOffset
ActionBar.boostExtraExpandX = 0
ActionBar.boostExtraExpandY = 0
ActionBar.boostExtraFloatSpeed = 0.33
ActionBar.boostExtraFloatPhase = 2.55
ActionBar.boostFloatRadius = 1.784592
ActionBar.boostFloatSpeeds = { 0.2992, 0.39168, 0.26112, 0.34272 }
ActionBar.boostFloatPhases = { 0.2, 1.7, 3.4, 4.9 }
ActionBar.boostExpandDuration = 0.4 * (2 / 3)
ActionBar.boostCollapseDuration = ActionBar.boostExpandDuration
ActionBar.boostLayoutDuration = 0.4
ActionBar.boostArcBulge = 36
ActionBar.boostCooldownProgress = 0.72
-- Подпись и буква L у дополнительного действия появляются чуть раньше полной посадки.
ActionBar.boostExtraCaptionProgress = 0.78
ActionBar.boostHintFadeProgress = 0.35
-- Подсказка правого рычага на краю более широкого облака: чуть правее и выше, но не слишком далеко вправо.
ActionBar.boostHintExtraOffsetX = 6
ActionBar.boostHintExtraOffsetY = 8
-- Буква L на дополнительной кнопке действия: чуть дальше от центра, но ближе исходного угла.
ActionBar.boostExtraKeyOffsetX = 5
ActionBar.boostExtraKeyOffsetY = 5

ActionBar.stackCountChange = ActionBar.stackCountChange or {}

-- Пиктограмма клавиши поверх умения: тень как у счётчика зарядов, без подложки стика.
function ActionBar.ApplyKeyGlyphStyle(iconFrame, size)
    if not iconFrame then
        return
    end

    local glyphSize = size or ActionBar.stackCountSize
    iconFrame:SetSize(glyphSize, glyphSize)
    if iconFrame.Background then
        iconFrame.Background:Hide()
    end
    if iconFrame.Shadow then
        iconFrame.Shadow:ClearAllPoints()
        iconFrame.Shadow:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -ActionBar.stackCountShadowOffsef, ActionBar.stackCountShadowOffsef)
        iconFrame.Shadow:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", ActionBar.stackCountShadowOffsef, -ActionBar.stackCountShadowOffsef)
        iconFrame.Shadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        iconFrame.Shadow:Show()
    end
end

-- Ячейка живёт в облаке усилений, а не на левой крестовине.
function ActionBar.IsBoostSlot(slotID)
    return ActionBar.boostSlotLookup[slotID] == true
end

-- Номер ячейки стандартной дополнительной кнопки действия.
function ActionBar.GetExtraActionSlotID()
    local button = _G.ExtraActionButton1
    if button then
        if button.action and button.action ~= 0 then
            return button.action
        end
        if button.CalculateAction then
            local action = button:CalculateAction()
            if action and action ~= 0 then
                return action
            end
        end
    end
    return 217
end

-- Ячейка относится к дополнительной кнопке действия.
function ActionBar.IsExtraActionSlot(slotID)
    if not slotID then
        return false
    end
    return slotID == ActionBar.GetExtraActionSlotID() or slotID == 139 or slotID == 217
end

-- Дополнительная кнопка действия сейчас заполнена и должна быть на панели.
function ActionBar.HasExtraAction()
    -- Показ стандартной рамки — самый устойчивый признак, в том числе при скрытых значениях.
    if ExtraActionBarFrame and ExtraActionBarFrame.IsShown and ExtraActionBarFrame:IsShown() then
        return true
    end

    if not C_ActionBar then
        return false
    end

    if C_ActionBar.HasExtraActionBar then
        local ok, shown = pcall(C_ActionBar.HasExtraActionBar)
        if ok then
            -- Скрытое значение нельзя считать отсутствием кнопки.
            if shown ~= nil and issecretvalue and issecretvalue(shown) then
                return true
            end
            if shown == true then
                return true
            end
        end
    end

    local slotID = ActionBar.GetExtraActionSlotID()
    if not C_ActionBar.HasAction then
        return false
    end

    local ok, hasAction = pcall(C_ActionBar.HasAction, slotID)
    if not ok then
        return false
    end
    -- Скрытое значение нельзя считать пустой ячейкой.
    if hasAction ~= nil and issecretvalue and issecretvalue(hasAction) then
        return true
    end
    return hasAction == true
end

-- Окно панели, если оно уже создано вместе с набором кнопок.
function ActionBar.GetFrame()
    local root = _G.ConsoleMenuFrame
    if not root then
        return nil
    end
    local frame = root.ActionBarFrame
    if not frame or not frame.actionButtons then
        return nil
    end
    return frame
end

-- Кнопка ячейки, если окно панели и сама кнопка существуют.
function ActionBar.GetButton(slotID)
    local frame = ActionBar.GetFrame()
    if not frame or not slotID then
        return nil
    end
    return frame.actionButtons[slotID]
end

-- Компенсация смещения под соотношение сторон экрана,
-- чтобы свечение модели оставалось по центру кнопки.
function ActionBar.GetGlowTransformOffset()
    local width, height = GetPhysicalScreenSize()
    if not width or not height or height == 0 then
        return ActionBar.modelOffset
    end

    local currentAspect = width / height
    if currentAspect <= 0 then
        return ActionBar.modelOffset
    end

    return ActionBar.modelOffset * (ActionBar.modelReferenceAspect / currentAspect)
end

-- Масштаб свечения также нормализуем относительно эталонного соотношения сторон,
-- чтобы размер эффекта не плавал между экранами.
function ActionBar.GetGlowTransformScale()
    local width, height = GetPhysicalScreenSize()
    if not width or not height or height == 0 then
        return ActionBar.modelScale
    end

    local currentAspect = width / height
    if currentAspect <= 0 then
        return ActionBar.modelScale
    end

    return ActionBar.modelScale * (ActionBar.modelReferenceAspect / currentAspect)
end

-- Положения кнопок панели по клавишам контроллера.
function ConsoleMenu:GetButtonPositions()
    return ActionBar.buttonPositions
end

-- Признак скрытой ячейки, которую панель не показывает.
function ConsoleMenu:IsSlotIgnored(slotID)
    return ActionBar.ignoredSlot[slotID]
end
