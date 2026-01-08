local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local captionPadding = 4

local titleFontSize = 24
local fontSize = 20
local captionFontSize = 16

local animationDuration = 0.3
local delay = 0.5

local notificationUpdateTimer = nil

local NotificationEventPriority = {
    UI_ERROR_MESSAGE = 1,

    CHAT_MSG_MONEY = 3,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 3,
    CURRENCY_DISPLAY_UPDATE = 3,
    PERKS_PROGRAM_CURRENCY_AWARDED = 3,
    UPDATE_PENDING_MAIL = 2,

    ZONE_CHANGED_NEW_AREA = 2,
    ZONE_CHANGED = 2,
    ZONE_CHANGED_INDOORS = 2,
    UI_INFO_MESSAGE = 2,
}

local NotificationDuration = {
    UI_ERROR_MESSAGE = 3,

    CHAT_MSG_MONEY = 5,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 5,
    CURRENCY_DISPLAY_UPDATE = 5,
    PERKS_PROGRAM_CURRENCY_AWARDED = 5,
    UPDATE_PENDING_MAIL = 10,

    ZONE_CHANGED_NEW_AREA = 5,
    ZONE_CHANGED = 5,
    ZONE_CHANGED_INDOORS = 5,
    UI_INFO_MESSAGE = 5,
}

local ignoredCurrencies = {
    [3372] = true,
}

local deduplicationDuration = 45

-- Функция для добавления уведомлений
function ConsoleMenu:AddNotification(event, message, caption, identifier, value)
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local priority = NotificationEventPriority[event] or 1

    -- Создаем таблицу субтитра
    local notificationData = {
        event = event,
        text = message,
        caption = caption,
        identifier = identifier,
        value = value,
        startTime = GetTime(),
    }

    table.insert(ConsoleMenu.Notifications, notificationData)

    if not notificationUpdateTimer then
        ConsoleMenu:NotificationFrameUpdate()
    elseif notificationUpdateTimer and NotificationEventPriority[event] == 1 then
        ConsoleMenu:NotificationFrameUpdate()
    end

    return
end

-- Функция для очистки Deduplication
local function RemoveOldDeduplication()
    if not ConsoleMenu or not ConsoleMenu.Deduplication then return end
    local currentTime = GetTime()
    for key in pairs(ConsoleMenu.Deduplication) do
        if ConsoleMenu.Deduplication[key] <= currentTime then
            ConsoleMenu.Deduplication[key] = nil
        end
    end
end

-- Функция для получения уведомления с наивысшим приоритетом
local function GetTopPriorityNotification()
    -- Обходим таблицу ConsoleMenu.Notifications с конца
    if not ConsoleMenu or not ConsoleMenu.Notifications or #ConsoleMenu.Notifications == 0 then
        return nil
    end

    local minPriority = nil
    local minNotification = nil

    for i = #ConsoleMenu.Notifications, 1, -1 do
        
        local notification = ConsoleMenu.Notifications[i]

        local duration = NotificationDuration and NotificationDuration[notification.event] or 5

        local priority = NotificationEventPriority and NotificationEventPriority[notification.event] or 1

        if not minPriority or priority < minPriority then
            minPriority = priority
            minNotification = notification
        end
    end

    return minNotification

end

-- Функция для группировки уведомлений
local function GetGroupedNotification(notification)

    if not notification then return end

    if notification.event == "UI_ERROR_MESSAGE" then
        -- Удаляем все уведомления с таким же текстом или просроченные ошибки
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].text == notification.text or (GetTime() - ConsoleMenu.Notifications[i].startTime > NotificationDuration[notification.event]) then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end

        -- Если уведомление просрочено, не игнорируем
        if GetTime() - notification.startTime > NotificationDuration[notification.event] then return end

        
    elseif notification.event == "CHAT_MSG_MONEY" then
        -- Удаляем отображаемое уведомление
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
    elseif notification.event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        -- Используем подход из WeakAura: паттерн с %D (не-цифра) для правильного разделения
        -- %D гарантирует, что мы находим число, окруженное не-цифрами, что игнорирует числа в форматировании WoW
        local previousText, value, nextText = notification.text:match("^(.*%D)([%+%-]?%d+)(%D*)$")
        
        if not previousText or not value or not nextText then
            return notification
        end
        
        local sum = 0
        for i = #ConsoleMenu.Notifications, 1, -1 do
            local n = ConsoleMenu.Notifications[i]
            if n.event == notification.event then
                local nPreviousText, nValue, nNextText = n.text:match("^(.*%D)([%+%-]?%d+)(%D*)$")
                if nPreviousText == previousText and nNextText == nextText and nValue then
                    sum = sum + (tonumber(nValue) or 0)
                    table.remove(ConsoleMenu.Notifications, i)
                end
            end
        end
        notification.value = sum
        notification.text = previousText .. sum .. nextText

    elseif notification.event == "CURRENCY_DISPLAY_UPDATE" then
        -- Просуммировать value всех записей с notification.identifier и удалить
        if not notification.identifier then return end

        local sum = 0
        for i = #ConsoleMenu.Notifications, 1, -1 do
            local n = ConsoleMenu.Notifications[i]
            if n.event == notification.event and n.identifier == notification.identifier and n.value then
                sum = sum + n.value
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
        notification.value = sum
        
        local info = C_CurrencyInfo.GetCurrencyInfo(notification.identifier)
        
        if info and info.name then
            local title = _G["PROFESSIONS_CRAFT_OUTPUT_TITLE"]
            local msg = string.format("%s %s x%d.", title, info.name, sum)
            notification.text = msg
        end

    elseif notification.event == "PERKS_PROGRAM_CURRENCY_AWARDED" then

        -- Удаляем отображаемое уведомление
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
        
        local info = C_CurrencyInfo.GetBasicCurrencyInfo(notification.identifier)
        local title = _G["PROFESSIONS_CRAFT_OUTPUT_TITLE"]
        notification.text = string.format("%s %s x%d.", title, info.name, notification.value)

    elseif notification.event == "UPDATE_PENDING_MAIL" then

        -- Удаляем все уведомления с таким же событием
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].event == notification.event then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
    elseif notification.event == "ZONE_CHANGED_NEW_AREA" or notification.event == "ZONE_CHANGED" or notification.event == "ZONE_CHANGED_INDOORS" then
        local zoneText = GetMinimapZoneText()
        notification.text = zoneText

        -- Удаляем все уведомления о смене области или изучении новой области
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].event == "ZONE_CHANGED_NEW_AREA" or ConsoleMenu.Notifications[i].event == "ZONE_CHANGED" or ConsoleMenu.Notifications[i].event == "ZONE_CHANGED_INDOORS" or (ConsoleMenu.Notifications[i].event == "UI_INFO_MESSAGE" and ConsoleMenu.Notifications[i].identifier == 408 and ConsoleMenu.Notifications[i].text == zoneText) then
                if ConsoleMenu.Notifications[i].event == "UI_INFO_MESSAGE" and ConsoleMenu.Notifications[i].identifier == 408 and ConsoleMenu.Notifications[i].text == zoneText then
                    notification.caption = ConsoleMenu.Notifications[i].caption
                end

                table.remove(ConsoleMenu.Notifications, i)
            end
        end

        if ConsoleMenu.Deduplication[zoneText] and GetTime() <= ConsoleMenu.Deduplication[zoneText] then return end

    elseif notification.event == "UI_INFO_MESSAGE" then

        -- Удаляем отображаемое уведомление
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end

    end

    return notification
end

-- Функция для обновления NotificationFrame
function ConsoleMenu:NotificationFrameUpdate()
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local notification = GetTopPriorityNotification()

    if ConsoleMenuFrame.NotificationFrame:IsShown() and notification and NotificationEventPriority[notification.event] ~= 1 then
        C_Timer.After(animationDuration + delay, function()
            ConsoleMenu:NotificationFrameUpdate()
        end)
        return
    end

    notification = GetGroupedNotification(notification)

    if notification then
        ConsoleMenuFrame.NotificationFrame.Text:SetText(notification.text)

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.QueueStatusToastFrame)
        
        C_Timer.After(animationDuration + delay, function()
            ConsoleMenu:AnimatedShow(ConsoleMenuFrame.NotificationFrame)
        end)

        local event = notification.event

        if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or (event == "UI_INFO_MESSAGE" and notification.identifier == 408) then
            ConsoleMenu.Deduplication[notification.text] = GetTime() + deduplicationDuration
        end

        local frame = ConsoleMenuFrame.NotificationFrame
        if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or (event == "UI_INFO_MESSAGE" and notification.identifier == 408) then
            frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        else
            frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        end

        if notification.caption then
            frame.Caption:SetText(notification.caption)
            frame.Caption:Show()
        else
            frame.Caption:Hide()
        end

        local duration = NotificationDuration[notification.event] or 5
    
        if duration then
            if notificationUpdateTimer then
                notificationUpdateTimer:Cancel()
            end

            notificationUpdateTimer = C_Timer.NewTimer(duration, function()
                notificationUpdateTimer = nil
                -- Скрываем текущее уведомление с анимацией
                ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)
                -- Ждем окончания анимации исчезновения перед проверкой следующего уведомления
                C_Timer.After(animationDuration + delay, function()
                    -- После отображения проверяем, есть ли еще уведомления в очереди
                    ConsoleMenu:NotificationFrameUpdate()
                end)
            end)
        end
    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)

        C_Timer.After(animationDuration + delay, function()
            ConsoleMenu:QueueStatusToastFrameUpdate()
        end)

        if notificationUpdateTimer then
            notificationUpdateTimer:Cancel()
            notificationUpdateTimer = nil
        end

    end
end

-- Функция для инициализации NotificationFrame
function ConsoleMenu:SetNotificationFrame()

    if not ConsoleMenu.Notifications then
        ConsoleMenu.Notifications = {}
    end

    if not ConsoleMenu.Deduplication then
        ConsoleMenu.Deduplication = {}
    end

    if not ConsoleMenuFrame.NotificationFrame then
        local frame = CreateFrame("Frame", "NotificationFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.NotificationFrame = frame
    end

    local frame = ConsoleMenuFrame.NotificationFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 48, -48)
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)
    frame:Hide()

    -- Текст уведомления
    if not frame.Text then
        frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        frame.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Text:SetJustifyH("LEFT")
        frame.Text:SetText("")
        frame.Text:SetNonSpaceWrap(true)
        frame.Text:Show()
        frame.Text:SetWordWrap(true)
    end

    -- Текст уведомления
    if not frame.Caption then
        frame.Caption = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Caption:SetPoint("TOPLEFT", frame.Text, "BOTTOMLEFT", 0, -captionPadding)
        frame.Caption:SetPoint("TOPRIGHT", frame.Text, "BOTTOMRIGHT", 0, -captionPadding)
        frame.Caption:SetFont("Fonts\\FRIZQT___CYR.TTF", captionFontSize, "")
        frame.Caption:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        frame.Caption:SetJustifyH("LEFT")
        frame.Caption:SetText("")
        frame.Caption:SetNonSpaceWrap(true)
        frame.Caption:Hide()
        frame.Caption:SetWordWrap(true)
    end

    frame:RegisterEvent("UI_ERROR_MESSAGE")

    frame:RegisterEvent("CHAT_MSG_MONEY")
    frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("PERKS_PROGRAM_CURRENCY_AWARDED")
    frame:RegisterEvent("UPDATE_PENDING_MAIL")

    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    frame:RegisterEvent("UI_INFO_MESSAGE")

    local function OnNotificationEvent(self, event, ...)

        if event == "UI_ERROR_MESSAGE" then

            -- Если выбран стандартный стиль ошибок интерфейса
            if ConsoleMenuDB.errorsFrameStyle == 1 then return end
            
            if InCombatLockdown() then return end

            local _, errorMessage = ...

            if ConsoleMenuFrame.NotificationFrame:IsShown() and errorMessage == ConsoleMenuFrame.NotificationFrame.Text:GetText() then return end
            
            ConsoleMenu:AddNotification(event, errorMessage)
        elseif event == "CURRENCY_DISPLAY_UPDATE" then

            -- Если выбран стандартный стиль оповещений о получении валюты
            if ConsoleMenuDB.currencyDisplayUpdateStyle == 1 then return end

            local currencyID, quantity, quantityChange, quantityGainSource, destroyReason = ...

            if ignoredCurrencies[currencyID] then return end

            if quantityChange and quantityChange > 0 then
                ConsoleMenu:AddNotification(event, nil, nil, currencyID, quantityChange)
            end
        elseif event == "PERKS_PROGRAM_CURRENCY_AWARDED" then

            -- Если выбран стандартный стиль оповещений о получении валюты
            if ConsoleMenuDB.currencyDisplayUpdateStyle == 1 then return end

            local value = ...
            ConsoleMenu:AddNotification(event, nil, nil, 2032, value)
        elseif event == "UPDATE_PENDING_MAIL" then

            -- Если выбран стандартный стиль оповещений о получении почты
            if ConsoleMenuDB.mailDisplayUpdateStyle == 1 then return end

            if HasNewMail() then
                C_Timer.After(2, function()
                    ConsoleMenu:AddNotification(event, HAVE_MAIL)
                end)
            end
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then

            -- Если выбран стандартный стиль оповещений о смене области
            if ConsoleMenuDB.zoneTextFrameStyle == 1 then return end

            local zoneText = GetMinimapZoneText()
            if ConsoleMenu.Deduplication[zoneText] and GetTime() <= ConsoleMenu.Deduplication[zoneText] then return end

            ConsoleMenu:AddNotification(event)
        elseif event == "UI_INFO_MESSAGE" then

            local messageType, message = ...

            if messageType == 408 then
                -- Если выбран стандартный стиль оповещений о смене области
                if ConsoleMenuDB.zoneTextFrameStyle == 1 then return end
            end

            if messageType ~= 408 then return end

            local zoneText = message:match(":%s*(.+)")
            local caption = message:match("^([^:]+):")

            if ConsoleMenuFrame.NotificationFrame:IsShown() and zoneText == ConsoleMenuFrame.NotificationFrame.Text:GetText() then

                -- Случай, когда уведомление о смене области уже отображается и во время отображения появляется новое уведомление об изучении этой области
                ConsoleMenuFrame.NotificationFrame.Caption:SetText(caption)
                ConsoleMenuFrame.NotificationFrame.Caption:Show()
                ConsoleMenuFrame.NotificationFrame.fadeOut:Stop()

                local duration = NotificationDuration[event] or 5
    
                if duration then
                    if notificationUpdateTimer then
                        notificationUpdateTimer:Cancel()
                    end
        
                    notificationUpdateTimer = C_Timer.NewTimer(duration, function()
                        notificationUpdateTimer = nil
                        -- Скрываем текущее уведомление с анимацией
                        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)
                        -- Ждем окончания анимации исчезновения перед проверкой следующего уведомления
                        C_Timer.After(animationDuration + delay, function()
                            -- После отображения проверяем, есть ли еще уведомления в очереди
                            ConsoleMenu:NotificationFrameUpdate()
                        end)
                    end)
                end
            else
                ConsoleMenu:AddNotification(event, zoneText, caption, messageType)
            end
        
        else
            local msg = ...
            ConsoleMenu:AddNotification(event, msg)
        end

        RemoveOldDeduplication()
    end

    frame:SetScript("OnEvent", OnNotificationEvent)
end