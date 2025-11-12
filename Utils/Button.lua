local ConsoleMenu = _G.ConsoleMenu

-- Локальная функция для получения информации о кулдауне слота действия
local function GetActionButtonCooldownInfo(slot)
    if not slot then
        return false
    end

    local actionType, id, subtype = GetActionInfo(slot)

    if actionType == "macro" then
        if subtype == "spell" then
            actionType = "spell"
        end
    end

    if actionType == "spell" then
        local cd = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(id)
        if not cd or cd.isEnabled == false or cd.duration == 0 then
            return false
        end

        local gcd = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(61304)
        local isGCD = false
        if gcd and gcd.duration and gcd.duration > 0 then
            if math.abs(cd.duration - gcd.duration) < 0.05 and math.abs(cd.startTime - gcd.startTime) < 0.05 then
                isGCD = true
            end
        end
        if isGCD then
            return false
        end

        local expiration = cd.startTime + cd.duration
        return cd.duration, expiration
    end

    if actionType == "item" then
        local start, duration, enable
        if C_Item and C_Item.GetItemCooldown then
            start, duration, enable = C_Item.GetItemCooldown(id)
        else
            start, duration, enable = GetItemCooldown(id)
        end
        if enable == 0 or duration == 0 then
            return false
        end
        return duration, start + duration
    end

    return
end


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
    local texture = GetActionTexture(slot)
    local text = GetActionText(slot)
    local actionCooldownDuration, actionCooldownExpiration = GetActionButtonCooldownInfo(slot)

    -- Используем текстуру по умолчанию, если слот пустой
    if not texture then
        texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    
    -- Создаем кнопку всегда, даже если слот пустой

    -- Получаем информацию о зарядах способности и кулдауне
    local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetActionCharges(slot)
    
    -- Создание фрейма кнопки
    local button = CreateFrame("Button", nil, parent)
    button.regionType = "actionbutton"
    button.slot = slot
    
    -- Установка размера кнопки
    button:SetSize(width, height)
    
    -- Создание иконки внутри кнопки
    local iconData = {
        parent = button,
        width = width,
        height = height,
        displayIcon = texture
    }
    
    -- Добавляем данные о кулдауне, если они есть
    if actionCooldownDuration and actionCooldownDuration ~= false and actionCooldownExpiration and actionCooldownExpiration ~= false then
        iconData.duration = actionCooldownDuration
        iconData.expiration = actionCooldownExpiration
    end
    
    local icon = ConsoleMenu:CreateIcon(iconData)
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

    button:SetScript("OnEvent", function(self, event, ...)
        -- Получаем свежую информацию о кулдауне слота
        local actionCooldownDuration, actionCooldownExpiration = GetActionButtonCooldownInfo(self.slot)
        -- Обновляем иконку с новыми данными о кулдауне
        local updateData = {}
        if actionCooldownDuration and actionCooldownDuration ~= false and actionCooldownExpiration and actionCooldownExpiration ~= false then
            updateData.duration = actionCooldownDuration
            updateData.expiration = actionCooldownExpiration
        else
            updateData.duration = nil
            updateData.expiration = nil
        end
        ConsoleMenu:ModifyIcon(self.icon, updateData)
    end)
    
    return button
end

