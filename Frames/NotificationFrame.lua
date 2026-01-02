local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local fontSize = 20

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
function ConsoleMenu:AddSubtitles(event, message)
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local priority = SubtitleEventPriority[event] or 1

    -- Создаем таблицу субтитра
    local notificationData = {
        text = message,
        event = event,
    }
    
    table.insert(ConsoleMenu.Notifications, notificationData)
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

    local function OnSubtitleEvent(self, event, ...)
        if event == "UI_ERROR_MESSAGE" then
            local _, errorMessage = ...
            ConsoleMenu:AddSubtitles(event, errorMessage)
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
                    ConsoleMenu:AddSubtitles(event, msg)
                end
            end
        elseif event == "PERKS_PROGRAM_CURRENCY_AWARDED" then
            local value = ...
            local info = C_CurrencyInfo.GetBasicCurrencyInfo(2032)
            local msg = string.format("Получено: %s x%d.", info.name, value)
            ConsoleMenu:AddSubtitles(event, msg)
        else
            local msg = ...
            ConsoleMenu:AddSubtitles(event, msg)
        end
    end

    frame:SetScript("OnEvent", OnSubtitleEvent)
end