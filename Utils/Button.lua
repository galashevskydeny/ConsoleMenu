local ConsoleMenu = _G.ConsoleMenu

-- Создание кнопки action bar
function ConsoleMenu:CreateActionButton(parent, slot)
    if not slot then
        return
    end

    -- Локальные переменные для иконки
    local width = 52
    local height = 52
    
    -- Получение информации о слоте
    local actionType, actionID, subType = GetActionInfo(slot)

    if not actionType then
        return
    end
    
    local iconTexture = GetActionTexture(slot)

    if not iconTexture then
        return
    end

    -- Получаем информацию о зарядах способности и кулдауне
    local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetActionCharges(slot)
    
    -- Создание фрейма кнопки
    local button = CreateFrame("Button", nil, parent)
    button.regionType = "actionbutton"
    button.slot = slot
    
    -- Установка размера кнопки
    button:SetSize(width, height)
    
    -- Создание иконки внутри кнопки
    local icon = ConsoleMenu:CreateIcon(button, width, height, iconTexture)
    button.icon = icon
    
    -- Привязываем иконку к центру кнопки
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetSize(width, height)
    
    -- Создаем текстуру фона, которая выпирает на 4 пикселя в каждую сторону
    local bgTexture = button:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
    bgTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
    bgTexture:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Buttons\\plain.png")
    bgTexture:SetAlpha(0.4)
    button.bgTexture = bgTexture

    -- Подписываем кнопку на события обновления панели действий
    button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    button:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    button:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    button:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    button:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    button:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    
    return button
end

