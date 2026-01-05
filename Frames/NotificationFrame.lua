local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56

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
}

local NotificationDuration = {
    UI_ERROR_MESSAGE = 3,
    CHAT_MSG_MONEY = 5,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 5,
    CURRENCY_DISPLAY_UPDATE = 5,
    PERKS_PROGRAM_CURRENCY_AWARDED = 5,
    UPDATE_PENDING_MAIL = 10,
    ZONE_CHANGED_NEW_AREA = 3,
    ZONE_CHANGED = 3,
    ZONE_CHANGED_INDOORS = 3,
}

local ignoredCurrencies = {
    [3372] = true,
}

local deduplicationDuration = 30

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
        -- Удаляем все уведомления с таким же текстом, как у notification
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].text == notification.text or (GetTime() - ConsoleMenu.Notifications[i].startTime > NotificationDuration[notification.event]) then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end

        -- Если уведомление просрочено, не игнорируем
        if GetTime() - notification.startTime > NotificationDuration[notification.event] then return end

        return notification
    elseif notification.event == "CHAT_MSG_MONEY" then
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
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
                local title = _G["PROFESSIONS_CRAFT_OUTPUT_TITLE"]
                local msg = string.format("%s %s x%d.", title, info.name, sum)
                notification.text = msg
            end

            return notification
        end
    elseif notification.event == "PERKS_PROGRAM_CURRENCY_AWARDED" then
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
        
        local info = C_CurrencyInfo.GetBasicCurrencyInfo(notification.identifier)
        local title = _G["PROFESSIONS_CRAFT_OUTPUT_TITLE"]
        notification.text = string.format("%s %s x%d.", title, info.name, notification.value)
        return notification
    elseif notification.event == "UPDATE_PENDING_MAIL" then
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].event == notification.event then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
        return notification
    elseif notification.event == "ZONE_CHANGED_NEW_AREA" or notification.event == "ZONE_CHANGED" or notification.event == "ZONE_CHANGED_INDOORS" then
        local zoneText = GetMinimapZoneText()
        notification.text = zoneText

        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].event == "ZONE_CHANGED_NEW_AREA" or ConsoleMenu.Notifications[i].event == "ZONE_CHANGED" or ConsoleMenu.Notifications[i].event == "ZONE_CHANGED_INDOORS" then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end

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
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.NotificationFrame)

        local event = notification.event

        if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
            ConsoleMenu.Deduplication[notification.text] = GetTime() + deduplicationDuration
        end

        local frame = ConsoleMenuFrame.NotificationFrame
        if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
            frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        else
            frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        end

        local duration = NotificationDuration and NotificationDuration[notification.event] or 5
    
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

    frame:RegisterEvent("UI_ERROR_MESSAGE")

    frame:RegisterEvent("CHAT_MSG_MONEY")
    frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("PERKS_PROGRAM_CURRENCY_AWARDED")
    frame:RegisterEvent("UPDATE_PENDING_MAIL")

    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")

    local function OnNotificationEvent(self, event, ...)

        if event == "UI_ERROR_MESSAGE" then

            if InCombatLockdown() then return end

            local _, errorMessage = ...

            if ConsoleMenuFrame.NotificationFrame:IsShown() and errorMessage == ConsoleMenuFrame.NotificationFrame.Text:GetText() then return end
            
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
        elseif event == "UPDATE_PENDING_MAIL" then
            if HasNewMail() then
                C_Timer.After(2, function()
                    ConsoleMenu:AddNotification(event, HAVE_MAIL, nil, nil)
                end)
            end
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then

            local zoneText = GetMinimapZoneText()
            if ConsoleMenu.Deduplication[zoneText] and GetTime() <= ConsoleMenu.Deduplication[zoneText] then return end

            ConsoleMenu:AddNotification(event, nil, nil, nil)
        else
            local msg = ...
            ConsoleMenu:AddNotification(event, msg)
        end

        RemoveOldDeduplication()
    end

    frame:SetScript("OnEvent", OnNotificationEvent)
end