local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local fontSize = 20

local notificationUpdateTimer = nil


local NotificationEventPriority = {
    UI_ERROR_MESSAGE = 1,
    CHAT_MSG_MONEY = 2,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 2,
    CURRENCY_DISPLAY_UPDATE = 2,
    PERKS_PROGRAM_CURRENCY_AWARDED = 2
}

local NotificationDuration = {
    UI_ERROR_MESSAGE = 5,
    CHAT_MSG_MONEY = 5,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 5,
    CURRENCY_DISPLAY_UPDATE = 5,
    PERKS_PROGRAM_CURRENCY_AWARDED = 5
}

-- Функция для добавления уведомлений
function ConsoleMenu:AddNotification(event, message, identifier)
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    print("AddNotification: ", event, " ", message)

    local priority = NotificationEventPriority[event] or 1

    -- Создаем таблицу субтитра
    local notificationData = {
        text = message,
        event = event,
        combined = false,
        identifier = identifier,
    }

    if event == "UI_ERROR_MESSAGE" then
        notificationData.combined = true
        table.insert(ConsoleMenu.Notifications, notificationData)
        ConsoleMenu:NotificationFrameUpdate()
    else
        table.insert(ConsoleMenu.Notifications, notificationData)
        -- Через секунду запускаем объединение уведомлений
        C_Timer.After(2, function()
            ConsoleMenu:CombineNotifications(event, identifier)
        end)
    end

    return
end

-- Функция для объединения и суммирования схожих уведомлений внутри ConsoleMenu.Notifications
function ConsoleMenu:CombineNotifications(event, identifier)
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    if not event then return end

    if event == "UI_ERROR_MESSAGE" then return end

    -- Группируем уведомления по типу
    local notificationsForEvent = {}
    for _, notification in ipairs(ConsoleMenu.Notifications) do
        if notification.event == event and not notification.combined and notification.identifier == identifier then
            -- Разбиваем текст на части: previousText, value, nextText
            local previousText, value, nextText = notification.text:match("^(.-)([%+%-]?%d+)(.*)$")
            if previousText and value and nextText then
                table.insert(notificationsForEvent, {
                    previousText = previousText,
                    value = tonumber(value),
                    nextText = nextText
                })
            else
                notification.combined = true
            end
        end
    end

    if #notificationsForEvent == 0 then
        -- Нет уведомлений для объединения
        return
    elseif #notificationsForEvent == 1 then
        -- Только одно уведомление для объединения, которому надо просто сменить маркировку на combined = true
        for _, notification in ipairs(ConsoleMenu.Notifications) do
            notification.combined = true
        end
    else
        -- Объединяем уведомления этого типа
        local combinedValue = 0
        for i = 1, #notificationsForEvent do
            combinedValue = combinedValue + notificationsForEvent[i].value
        end

        -- Удаляем все уведомления с этим event
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].event == event then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end

        -- Добавляем новое уведомление
        table.insert(ConsoleMenu.Notifications, {
            text = notificationsForEvent[1].previousText .. combinedValue .. notificationsForEvent[1].nextText,
            event = event,
            combined = true,
        })
    end

    ConsoleMenu:NotificationFrameUpdate()
    return
end

-- Функция для получения уведомления с максимальным приоритетом
local function GetTopPriorityCombinedNotification()
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return nil
    end

    local lowestNotification = nil
    local lowestPriority = nil
    local lowestIndex = nil

    for i = #ConsoleMenu.Notifications, 1, -1 do
        local notification = ConsoleMenu.Notifications[i]
        if notification.combined == true then
            local event = notification.event
            local priority = NotificationEventPriority and NotificationEventPriority[event] or 1
            if lowestPriority == nil or priority < lowestPriority then
                lowestPriority = priority
                lowestNotification = notification
                lowestIndex = i
            end
        end
    end

    if lowestIndex then
        table.remove(ConsoleMenu.Notifications, lowestIndex)
    end

    return lowestNotification
end

-- Функция для обновления NotificationFrame
function ConsoleMenu:NotificationFrameUpdate()
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local notification = GetTopPriorityCombinedNotification()

    if notification then
        ConsoleMenuFrame.NotificationFrame.Text:SetText(notification.text)
        ConsoleMenuFrame.NotificationFrame.Text:Show()

        local duration = NotificationDuration and NotificationDuration[notification.event] or 5
    
        if duration then
            if notificationUpdateTimer then
                notificationUpdateTimer:Cancel()
            end

            notificationUpdateTimer =  C_Timer.NewTimer(duration, function()
                ConsoleMenu:NotificationFrameUpdate()
            end)
        end
    else
        ConsoleMenuFrame.NotificationFrame.Text:SetText("")
        ConsoleMenuFrame.NotificationFrame.Text:Hide()

        if notificationUpdateTimer then
            notificationUpdateTimer:Cancel()
            notificationUpdateTimer = nil
        end

        notificationUpdateTimer = C_Timer.NewTimer(1, function()
            ConsoleMenu:NotificationFrameUpdate()
        end)
    end
end


-- Функция для инициализации NotificationFrame
function ConsoleMenu:SetNotificationFrame()

    if ConsoleMenuDB.notificationFrame == 2 then
        return
    end

    if not ConsoleMenu.Notifications then
        ConsoleMenu.Notifications = {}
    end

    if not ConsoleMenuFrame.NotificationFrame then
        local frame = CreateFrame("Frame", "NotificationFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.NotificationFrame = frame
    end

    local frame = ConsoleMenuFrame.NotificationFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 48, -48)

    -- Текст уведомления
    if not frame.Text then
        frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "OUTLINE")
        frame.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Text:SetJustifyH("LEFT")
        frame.Text:SetText("")
        frame.Text:SetNonSpaceWrap(true)
        frame.Text:SetWordWrap(true)
        frame.Text:Hide()
    end

    frame:RegisterEvent("UI_ERROR_MESSAGE")
    frame:RegisterEvent("CHAT_MSG_MONEY")
    frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("PERKS_PROGRAM_CURRENCY_AWARDED")

    local function OnNotificationEvent(self, event, ...)
        if event == "UI_ERROR_MESSAGE" then
            local _, errorMessage = ...
            ConsoleMenu:AddNotification(event, errorMessage)
        elseif event == "CURRENCY_DISPLAY_UPDATE" then
            local currencyID, quantity, quantityChange, quantityGainSource, destroyReason = ...
            local info
            if currencyID then
                info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
            end
            
            if info and info.name then
                -- Только добавляем, если изменение количества больше 0
                if quantityChange and quantityChange > 0 then
                    local msg = string.format("Получено: %s x%d.", info.name, quantityChange)
                    ConsoleMenu:AddNotification(event, msg, currencyID)
                end
            end
        elseif event == "PERKS_PROGRAM_CURRENCY_AWARDED" then
            local value = ...
            local info = C_CurrencyInfo.GetBasicCurrencyInfo(2032)
            local msg = string.format("Получено: %s x%d.", info.name, value)
            ConsoleMenu:AddNotification(event, msg, 2032)
        else
            local msg = ...
            ConsoleMenu:AddNotification(event, msg)
        end
    end

    frame:SetScript("OnEvent", OnNotificationEvent)
end