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

ActionBar.stackCountChange = ActionBar.stackCountChange or {}

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
