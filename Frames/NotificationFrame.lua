local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local fontSize = 20
local animationDuration = 0.3
local delay = 0.5

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

local ignoredCurrencies = {
    [3372] = true,
}

-- Функция для добавления уведомлений
function ConsoleMenu:AddNotification(event, message, identifier, value)
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local priority = NotificationEventPriority[event] or 1

    -- Создаем таблицу субтитра
    local notificationData = {
        text = message,
        event = event,
        identifier = identifier,
        startTime = GetTime(),
        value = value,
    }

    table.insert(ConsoleMenu.Notifications, notificationData)

    if not notificationUpdateTimer then
        ConsoleMenu:NotificationFrameUpdate()
    end

    return
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
        -- Удаляем все уведомления с таким же текстом, как у notification
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].text == notification.text or (GetTime() - ConsoleMenu.Notifications[i].startTime > NotificationDuration[notification.event]) then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
        return notification
    elseif notification.event == "CHAT_MSG_MONEY" then
        return notification
    elseif notification.event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        -- Используем подход из WeakAura: паттерн с %D (не-цифра) для правильного разделения
        -- %D гарантирует, что мы находим число, окруженное не-цифрами, что игнорирует числа в форматировании WoW
        local previousText, value, nextText = notification.text:match("^(.*%D)([%+%-]?%d+)(%D*)$")
        
        print("previousText: ", previousText, " value: ", value, " nextText: ", nextText)
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

        return notification
    elseif notification.event == "CURRENCY_DISPLAY_UPDATE" then
        -- просуммировать value всех записей с notification.identifier и удалить
        if notification.identifier then
            local sum = 0
            for i = #ConsoleMenu.Notifications, 1, -1 do
                local n = ConsoleMenu.Notifications[i]
                if n.event == notification.event and n.identifier == notification.identifier and n.value then
                    sum = sum + n.value
                    table.remove(ConsoleMenu.Notifications, i)
                end
            end
            -- Создаем новый notification с суммированным value
            notification.value = sum
            
            local info = C_CurrencyInfo.GetCurrencyInfo(notification.identifier)
            
            if info and info.name then
                local msg = string.format("Получено: %s x%d.", info.name, sum)
                notification.text = msg
            end

            return notification
        end
    elseif notification.event == "PERKS_PROGRAM_CURRENCY_AWARDED" then
        local info = C_CurrencyInfo.GetBasicCurrencyInfo(notification.identifier)
        notification.text = string.format("Получено: %s x%d.", info.name, notification.value)
        return notification
    end
end

-- Функция для обновления NotificationFrame
function ConsoleMenu:NotificationFrameUpdate()
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local notification = GetTopPriorityNotification()
    notification = GetGroupedNotification(notification)

    if notification then
        ConsoleMenuFrame.NotificationFrame.Text:SetText(notification.text)
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.NotificationFrame.Text)

        local duration = NotificationDuration and NotificationDuration[notification.event] or 5
    
        if duration then
            if notificationUpdateTimer then
                notificationUpdateTimer:Cancel()
            end

            notificationUpdateTimer = C_Timer.NewTimer(duration, function()
                notificationUpdateTimer = nil
                -- Скрываем текущее уведомление с анимацией
                ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame.Text)
                -- Ждем окончания анимации исчезновения перед проверкой следующего уведомления
                C_Timer.After(animationDuration + delay, function()
                    -- После отображения проверяем, есть ли еще уведомления в очереди
                    ConsoleMenu:NotificationFrameUpdate()
                end)
            end)
        end
    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame.Text)

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
        ConsoleMenu:InitFadeAnimations(frame.Text, animationDuration)
    end

    frame:RegisterEvent("UI_ERROR_MESSAGE")
    frame:RegisterEvent("CHAT_MSG_MONEY")
    frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("PERKS_PROGRAM_CURRENCY_AWARDED")

    local function OnNotificationEvent(self, event, ...)
        if event == "UI_ERROR_MESSAGE" then

            if InCombatLockdown() then return end

            local _, errorMessage = ...
            ConsoleMenu:AddNotification(event, errorMessage)
        elseif event == "CURRENCY_DISPLAY_UPDATE" then
            local currencyID, quantity, quantityChange, quantityGainSource, destroyReason = ...

            if ignoredCurrencies[currencyID] then return end

            if quantityChange and quantityChange > 0 then
                ConsoleMenu:AddNotification(event, nil, currencyID, quantityChange)
            end
        elseif event == "PERKS_PROGRAM_CURRENCY_AWARDED" then
            local value = ...
            ConsoleMenu:AddNotification(event, nil, 2032, value)
        else
            local msg = ...
            ConsoleMenu:AddNotification(event, msg)
        end
    end

    frame:SetScript("OnEvent", OnNotificationEvent)
end