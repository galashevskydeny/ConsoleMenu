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

ActionBar.shadowSize = 320

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

    -- Тачпад DualSense: слот 12 и эквиваленты на других страницах / модификаторах
    PAD6 = { "BOTTOM", "ActionBarFrame", "BOTTOM", 0, 0 },
    PADBACK = { "BOTTOM", "ActionBarFrame", "BOTTOM", 0, 0 },
}

-- Слоты ACTIONBUTTON12 / MULTIACTIONBAR*BUTTON12
ActionBar.slot12Slots = {
    [12] = true,
    [24] = true,
    [60] = true,
    [72] = true,
}

ActionBar.slot12ContainerWidth = 190
ActionBar.slot12ContainerHeight = 70
ActionBar.slot12LabelFontSize = 16
-- Отступ иконки от края фона = вертикальный зазор (фон круга 60 при высоте 70)
ActionBar.slot12IconPadding = (ActionBar.slot12ContainerHeight - (ActionBar.buttonSize + 8)) / 2
ActionBar.slot12LabelGap = ActionBar.slot12IconPadding + 6
ActionBar.slot12LabelEdgePadding = ActionBar.slot12IconPadding
ActionBar.slot12LabelRightPadding = ActionBar.slot12IconPadding + 12

ActionBar.ignoredSlot = {
    [8] = true,
    [20] = true,
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
-- PAD4 сверху, PAD2 справа, PAD1 снизу, PAD3 слева.
ActionBar.boostExpandPositions = {
    { x = 0, y = ActionBar.boostExpandOffset },
    { x = ActionBar.boostExpandOffset, y = 0 },
    { x = 0, y = -ActionBar.boostExpandOffset },
    { x = -ActionBar.boostExpandOffset, y = 0 },
}
ActionBar.boostFloatRadius = 1.784592
ActionBar.boostFloatSpeeds = { 0.2992, 0.39168, 0.26112, 0.34272 }
ActionBar.boostFloatPhases = { 0.2, 1.7, 3.4, 4.9 }
ActionBar.boostExpandDuration = 0.4 * (2 / 3)
ActionBar.boostCollapseDuration = ActionBar.boostExpandDuration
ActionBar.boostArcBulge = 36
ActionBar.boostCooldownProgress = 0.72

ActionBar.stackCountChange = ActionBar.stackCountChange or {}

-- Ячейка живёт в облаке усилений, а не на левой крестовине.
function ActionBar.IsBoostSlot(slotID)
    return ActionBar.boostSlotLookup[slotID] == true
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
