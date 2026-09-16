local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local captionPadding = 4

local titleFontSize = 24
local fontSize = 20
local captionFontSize = 16

local delay = 0.5
local fallbackLootDisplayDuration = 6
local fallbackLootAnimationDuration = 0.24

-- Номер валюты торговца за золото
local tradersTenderCurrencyID = 2032

-- Ключ подавления повторных уведомлений о почте
local mailDeduplicationKey = "UPDATE_PENDING_MAIL"

-- Отложенные вызовы показа и номер текущего цикла, чтобы отбросить устаревшие действия
local displayTimer = nil
local transitionTimer = nil
local mailDelayTimer = nil
local showGeneration = 0

-- Выбранная запись, которая ещё не появилась на экране
local committedNotification = nil
local committedVisible = false

-- Приоритет событий: меньшее число показывается раньше
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

-- Длительность показа уведомления в секундах
local NotificationDuration = {
    UI_ERROR_MESSAGE = 3,

    CHAT_MSG_COMBAT_FACTION_CHANGE = 5,
    UPDATE_PENDING_MAIL = 10,

    ZONE_CHANGED_NEW_AREA = 5,
    ZONE_CHANGED = 5,
    ZONE_CHANGED_INDOORS = 5,
    UI_INFO_MESSAGE = 5,
}

-- События получения золота и валюты
local CurrencyNotificationEvents = {
    CHAT_MSG_MONEY = true,
    CURRENCY_DISPLAY_UPDATE = true,
    PERKS_PROGRAM_CURRENCY_AWARDED = true,
}

-- Срок подавления повторного названия одной и той же области
local deduplicationDuration = 45

-- Определяет уведомление о получении золота или валюты
local function IsCurrencyNotification(event)
    return CurrencyNotificationEvents[event]
end

-- Золото и валюту в бою не показываем: оставляем в очереди до конца боя
local function IsCurrencyDeferredInCombat(event)
    return IsCurrencyNotification(event) and InCombatLockdown()
end

-- Список добычи уже на экране, валюту нужно показать сразу
local function ShouldShowCurrencyWithLootList(event)
    return IsCurrencyNotification(event)
        and not InCombatLockdown()
        and ConsoleMenu.IsLootListShowing
        and ConsoleMenu:IsLootListShowing()
end

-- Длительность анимации списка добычи, с запасным значением
local function GetAnimationDuration()
    if ConsoleMenu.GetLootListAnimationDuration then
        return ConsoleMenu:GetLootListAnimationDuration()
    end
    return fallbackLootAnimationDuration
end

-- Возвращает длительность показа для события
local function GetNotificationDuration(event)
    if IsCurrencyNotification(event) then
        if ConsoleMenu.GetLootListDisplayDuration then
            return ConsoleMenu:GetLootListDisplayDuration()
        end
        return fallbackLootDisplayDuration
    end
    return NotificationDuration[event] or 5
end

-- Возвращает срок ожидания в очереди; пустое значение означает, что запись не устаревает
local function GetQueueTimeToLive(event)
    if event == "UI_ERROR_MESSAGE" then
        return 10
    end
    if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "UI_INFO_MESSAGE" then
        return 30
    end
    return nil
end

-- Возвращает приоритет события: меньшее число важнее
local function GetNotificationPriority(event)
    return NotificationEventPriority[event] or 1
end

-- Проверяет, что значение скрыто клиентом
local function IsSecret(value)
    return value ~= nil and issecretvalue(value)
end

-- Проверяет, что рамка сейчас исчезает
local function IsFadingOut(frame)
    return frame and frame.fadeOut and frame.fadeOut:IsPlaying()
end

-- Отменяет отложенный показ, скрытие и длительность
local function CancelNotificationTimers()
    if displayTimer then
        displayTimer:Cancel()
        displayTimer = nil
    end
    if transitionTimer then
        transitionTimer:Cancel()
        transitionTimer = nil
    end
end

-- Начинает новый цикл показа и отменяет прежние отложенные действия
local function BeginShowGeneration()
    showGeneration = showGeneration + 1
    CancelNotificationTimers()
    return showGeneration
end

-- Сбрасывает выбранную, но ещё не показанную запись
local function ClearCommitment()
    committedNotification = nil
    committedVisible = false
end

-- Возвращает в очередь запись, которая была снята, но ещё не появилась
local function RequeueUnshownCommitment()
    if not committedNotification or committedVisible then
        return
    end
    if ConsoleMenu.Notifications then
        table.insert(ConsoleMenu.Notifications, committedNotification)
    end
    committedNotification = nil
end

-- Определяет смену области
local function IsZoneChangeEvent(event)
    return event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS"
end

-- Определяет сообщение об изучении области по имени строки клиента
local function IsZoneExploredMessage(messageType)
    if not messageType or not GetGameMessageInfo then
        return false
    end
    local stringID = GetGameMessageInfo(messageType)
    return stringID == "ERR_ZONE_EXPLORED" or stringID == "ERR_ZONE_EXPLORED_XP"
end

-- Строит шаблон захвата из строки клиента с подстановками
local function PatternFromClientString(template)
    if type(template) ~= "string" then
        return nil
    end

    local parts = {}
    local tagged = template:gsub("%%([sd%%])", function(spec)
        if spec == "%" then
            return "\3"
        end
        parts[#parts + 1] = spec
        return "\1" .. #parts .. "\2"
    end)

    tagged = tagged:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    tagged = tagged:gsub("\3", "%%")

    for index, spec in ipairs(parts) do
        local capture
        if spec == "s" then
            capture = "(.+)"
        else
            capture = "(%d+)"
        end
        tagged = tagged:gsub("\1" .. index .. "\2", function()
            return capture
        end, 1)
    end

    return tagged
end

-- Разбирает название области и подпись из сообщения об изучении
local function ParseZoneExploredMessage(messageType, message)
    local stringID = GetGameMessageInfo(messageType)
    local caption

    if type(ERR_ZONE_EXPLORED) == "string" then
        caption = ERR_ZONE_EXPLORED:match("^([^:]+):") or ERR_ZONE_EXPLORED
    end

    if stringID == "ERR_ZONE_EXPLORED_XP" then
        local pattern = PatternFromClientString(ERR_ZONE_EXPLORED_XP)
        if pattern then
            local zoneText = message:match("^" .. pattern .. "$")
            if zoneText and zoneText ~= "" then
                return zoneText, caption
            end
        end
        local zoneText = message:match("^(.-):%s*%d+")
        if zoneText then
            local prefix = caption
            if prefix and zoneText:sub(1, #prefix) == prefix then
                zoneText = zoneText:sub(#prefix + 1):gsub("^[%s:]+", "")
            end
            if zoneText ~= "" then
                return zoneText, caption
            end
        end
    end

    local zoneText = message:match(":%s*(.+)$")
    if not caption then
        caption = message:match("^([^:]+):")
    end
    return zoneText, caption
end

-- Собирает текст о получении валюты
local function FormatCurrencyReceived(name, amount)
    local quantity = math.floor(amount)
    if type(CURRENCY_GAINED_MULTIPLE) == "string" then
        local ok, result = pcall(string.format, CURRENCY_GAINED_MULTIPLE, name, quantity)
        if ok then
            return result
        end
    end
    return string.format("%s x%d", name, quantity)
end

-- Отсекает служебные и запрещённые валюты
local function IsIgnoredCurrency(currencyID)
    if not currencyID or IsSecret(currencyID) then
        return true
    end
    if ConsoleMenu.IgnoredCurrencies and ConsoleMenu.IgnoredCurrencies[currencyID] then
        return true
    end
    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info or not info.name or info.name == "" or IsSecret(info.name) then
        return true
    end
    if info.isTypeUnused then
        return true
    end
    if info.name:find("[DNT]", 1, true) then
        return true
    end
    return false
end

-- Удаляет записи, чей срок ожидания в очереди уже вышел
local function RemoveExpiredNotifications()
    if not ConsoleMenu.Notifications then
        return
    end
    local now = GetTime()
    for i = #ConsoleMenu.Notifications, 1, -1 do
        local notification = ConsoleMenu.Notifications[i]
        local timeToLive = GetQueueTimeToLive(notification.event)
        if timeToLive and now - notification.startTime > timeToLive then
            table.remove(ConsoleMenu.Notifications, i)
        end
    end
end

-- Удаляет из очереди записи, для которых условие истинно
local function RemoveMatchingNotifications(shouldRemove)
    if not ConsoleMenu.Notifications then
        return
    end
    for i = #ConsoleMenu.Notifications, 1, -1 do
        if shouldRemove(ConsoleMenu.Notifications[i]) then
            table.remove(ConsoleMenu.Notifications, i)
        end
    end
end

-- Проверяет, есть ли в очереди запись с таким событием
local function HasQueuedEvent(event)
    if not ConsoleMenu.Notifications then
        return false
    end
    for i = 1, #ConsoleMenu.Notifications do
        if ConsoleMenu.Notifications[i].event == event then
            return true
        end
    end
    return false
end

-- Выбирает запись с наивысшим приоритетом, при равенстве — более новую
local function GetTopPriorityNotification()
    if not ConsoleMenu.Notifications or #ConsoleMenu.Notifications == 0 then
        return nil
    end

    local minPriority = nil
    local minNotification = nil

    for i = #ConsoleMenu.Notifications, 1, -1 do
        local notification = ConsoleMenu.Notifications[i]
        if not IsCurrencyDeferredInCombat(notification.event) then
            local priority = GetNotificationPriority(notification.event)
            if not minPriority or priority < minPriority then
                minPriority = priority
                minNotification = notification
            end
        end
    end

    return minNotification
end

-- Сворачивает однотипные записи и всегда удаляет их из очереди
local function GetGroupedNotification(notification)
    if not notification then
        return nil
    end

    if notification.event == "UI_ERROR_MESSAGE" then
        local timeToLive = GetQueueTimeToLive(notification.event)
        local isExpired = timeToLive and (GetTime() - notification.startTime > timeToLive)
        RemoveMatchingNotifications(function(entry)
            return entry.event == "UI_ERROR_MESSAGE" and entry.text == notification.text
        end)
        if isExpired or not notification.text then
            return nil
        end
        return notification

    elseif notification.event == "CHAT_MSG_MONEY" then
        RemoveMatchingNotifications(function(entry)
            return entry == notification
        end)
        if not notification.text then
            return nil
        end
        return notification

    elseif notification.event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        if not notification.text then
            RemoveMatchingNotifications(function(entry)
                return entry == notification
            end)
            return nil
        end

        local previousText, value, nextText = notification.text:match("^(.*%D)([%+%-]?%d+)(%D*)$")
        if not previousText or not value then
            RemoveMatchingNotifications(function(entry)
                return entry == notification
            end)
            return notification
        end

        local sum = 0
        RemoveMatchingNotifications(function(entry)
            if entry.event ~= notification.event or not entry.text then
                return false
            end
            local entryPreviousText, entryValue, entryNextText = entry.text:match("^(.*%D)([%+%-]?%d+)(%D*)$")
            if entryPreviousText == previousText and entryNextText == nextText and entryValue then
                sum = sum + (tonumber(entryValue) or 0)
                return true
            end
            return entry == notification
        end)
        notification.value = sum
        notification.text = previousText .. sum .. nextText
        return notification

    elseif notification.event == "CURRENCY_DISPLAY_UPDATE" then
        local identifier = notification.identifier
        if not identifier then
            RemoveMatchingNotifications(function(entry)
                return entry == notification
            end)
            return nil
        end

        local sum = 0
        RemoveMatchingNotifications(function(entry)
            if entry.event == notification.event and entry.identifier == identifier then
                sum = sum + (entry.value or 0)
                return true
            end
            return false
        end)
        if sum <= 0 then
            return nil
        end

        local info = C_CurrencyInfo.GetCurrencyInfo(identifier)
        if not info or not info.name or info.name == "" or IsSecret(info.name) then
            return nil
        end

        notification.value = sum
        notification.text = FormatCurrencyReceived(info.name, sum)
        return notification

    elseif notification.event == "PERKS_PROGRAM_CURRENCY_AWARDED" then
        local identifier = notification.identifier or tradersTenderCurrencyID
        local sum = 0
        RemoveMatchingNotifications(function(entry)
            if entry.event == notification.event and (entry.identifier or tradersTenderCurrencyID) == identifier then
                sum = sum + (entry.value or 0)
                return true
            end
            return false
        end)
        if sum <= 0 then
            return nil
        end

        local info = C_CurrencyInfo.GetBasicCurrencyInfo(identifier)
        if not info or not info.name or info.name == "" or IsSecret(info.name) then
            return nil
        end

        notification.value = sum
        notification.identifier = identifier
        notification.text = FormatCurrencyReceived(info.name, sum)
        return notification

    elseif notification.event == "UPDATE_PENDING_MAIL" then
        RemoveMatchingNotifications(function(entry)
            return entry.event == notification.event
        end)
        return notification

    elseif IsZoneChangeEvent(notification.event) then
        local zoneText = GetMinimapZoneText()
        notification.text = zoneText
        local caption = notification.caption

        RemoveMatchingNotifications(function(entry)
            if IsZoneChangeEvent(entry.event) then
                return true
            end
            if entry.event == "UI_INFO_MESSAGE" and IsZoneExploredMessage(entry.identifier) and entry.text == zoneText then
                caption = entry.caption or caption
                return true
            end
            return false
        end)

        notification.caption = caption
        if ConsoleMenu.Deduplication[zoneText] and GetTime() <= ConsoleMenu.Deduplication[zoneText] then
            return nil
        end
        return notification

    elseif notification.event == "UI_INFO_MESSAGE" then
        local zoneText = notification.text
        local caption = notification.caption

        RemoveMatchingNotifications(function(entry)
            if entry == notification then
                return true
            end
            if not IsZoneExploredMessage(notification.identifier) then
                return false
            end
            if entry.event == "UI_INFO_MESSAGE" and entry.text == zoneText then
                caption = caption or entry.caption
                return true
            end
            if IsZoneChangeEvent(entry.event) and entry.text == zoneText then
                return true
            end
            return false
        end)

        notification.caption = caption
        return notification
    end

    RemoveMatchingNotifications(function(entry)
        return entry == notification
    end)
    return notification
end

-- Возвращает безопасную высоту строки
local function GetSafeStringHeight(fontString)
    if not fontString then
        return 0
    end
    local height = fontString:GetStringHeight()
    if not height or IsSecret(height) then
        return 0
    end
    return height
end

-- Подгоняет высоту рамки под текст и подпись
local function UpdateNotificationFrameHeight(frame)
    if not frame or not frame.Text then
        return
    end
    local textHeight = GetSafeStringHeight(frame.Text)
    local captionHeight = 0
    if frame.Caption and frame.Caption:IsShown() then
        captionHeight = GetSafeStringHeight(frame.Caption) + captionPadding
    end
    frame:SetHeight(math.max(frameHeight, textHeight + captionHeight))
end

-- Повторяет подгонку высоты после переноса строк
local function ScheduleNotificationFrameHeightUpdate(frame)
    UpdateNotificationFrameHeight(frame)
    if not frame then
        return
    end
    frame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        UpdateNotificationFrameHeight(self)
    end)
end

-- Запускает появление рамки, даже если идёт исчезновение
local function ForceAnimatedShow(frame)
    if not frame then
        return
    end
    if frame.fadeOut and frame.fadeOut:IsPlaying() then
        frame.fadeOut:Stop()
        frame.fadeOut:SetScript("OnFinished", nil)
        frame:Hide()
        frame:SetAlpha(0)
    end
    ConsoleMenu:AnimatedShow(frame)
end

-- Заполняет текст, шрифт и подпись рамки
local function ApplyNotificationContent(notification)
    local frame = ConsoleMenuFrame.NotificationFrame
    frame.Text:SetText(notification.text)

    local event = notification.event
    local isZone = IsZoneChangeEvent(event) or (event == "UI_INFO_MESSAGE" and IsZoneExploredMessage(notification.identifier))
    if isZone then
        frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        if notification.text then
            ConsoleMenu.Deduplication[notification.text] = GetTime() + deduplicationDuration
        end
    else
        frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
    end

    if notification.caption then
        frame.Caption:SetText(notification.caption)
        frame.Caption:Show()
    else
        frame.Caption:Hide()
    end

    if event == "UPDATE_PENDING_MAIL" then
        ConsoleMenu.Deduplication[mailDeduplicationKey] = GetTime() + GetNotificationDuration(event) + GetAnimationDuration() + delay
    end

    ScheduleNotificationFrameHeightUpdate(frame)
end

-- Скрывает рамку и после паузы продолжает очередь
local function HideAndContinue(generation)
    ClearCommitment()
    ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)
    transitionTimer = C_Timer.NewTimer(GetAnimationDuration() + delay, function()
        transitionTimer = nil
        if generation ~= showGeneration then
            return
        end
        ConsoleMenu:NotificationFrameUpdate()
    end)
end

-- Запускает отсчёт длительности текущего показа
local function StartDisplayTimer(generation, duration)
    committedVisible = true
    displayTimer = C_Timer.NewTimer(duration, function()
        displayTimer = nil
        if generation ~= showGeneration then
            return
        end
        HideAndContinue(generation)
    end)
end

-- Обновляет подпись уже видимой рамки и заново отсчитывает длительность
local function RefreshVisibleCaption(caption, duration)
    local frame = ConsoleMenuFrame.NotificationFrame
    if caption then
        frame.Caption:SetText(caption)
        frame.Caption:Show()
    end
    if frame.fadeOut then
        frame.fadeOut:Stop()
        frame.fadeOut:SetScript("OnFinished", nil)
        frame:SetAlpha(1)
    end
    ScheduleNotificationFrameHeightUpdate(frame)

    showGeneration = showGeneration + 1
    CancelNotificationTimers()
    committedVisible = true
    StartDisplayTimer(showGeneration, duration)
end

-- Удаляет устаревшие ключи подавления повторов
local function RemoveOldDeduplication()
    if not ConsoleMenu or not ConsoleMenu.Deduplication then
        return
    end
    local currentTime = GetTime()
    for key in pairs(ConsoleMenu.Deduplication) do
        if ConsoleMenu.Deduplication[key] <= currentTime then
            ConsoleMenu.Deduplication[key] = nil
        end
    end
end

-- Ставит уведомление в очередь и при необходимости начинает показ
function ConsoleMenu:AddNotification(event, message, caption, identifier, value)
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    table.insert(ConsoleMenu.Notifications, {
        event = event,
        text = message,
        caption = caption,
        identifier = identifier,
        value = value,
        startTime = GetTime(),
    })

    local priority = GetNotificationPriority(event)
    if not displayTimer or priority == 1 then
        ConsoleMenu:NotificationFrameUpdate()
    end
end

-- Выбирает следующую запись и запускает цикл показа без гонок
function ConsoleMenu:NotificationFrameUpdate()
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local previousCommitted = committedNotification
    local wasWaitingToShow = committedNotification and not committedVisible
    RequeueUnshownCommitment()
    RemoveExpiredNotifications()

    local notification = nil
    while ConsoleMenu.Notifications and #ConsoleMenu.Notifications > 0 do
        local nextNotification = GetTopPriorityNotification()
        if not nextNotification then
            break
        end
        local before = #ConsoleMenu.Notifications
        notification = GetGroupedNotification(nextNotification)
        if #ConsoleMenu.Notifications >= before then
            RemoveMatchingNotifications(function(entry)
                return entry == nextNotification
            end)
        end
        if notification then
            break
        end
    end

    local frame = ConsoleMenuFrame.NotificationFrame

    if wasWaitingToShow and notification == previousCommitted and transitionTimer then
        committedNotification = notification
        committedVisible = false
        ApplyNotificationContent(notification)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.QueueStatusToastFrame)
        if ShouldShowCurrencyWithLootList(notification.event) then
            local generation = showGeneration
            local duration = GetNotificationDuration(notification.event)
            transitionTimer:Cancel()
            transitionTimer = nil
            ForceAnimatedShow(frame)
            StartDisplayTimer(generation, duration)
        end
        return
    end

    local generation = BeginShowGeneration()

    if notification then
        committedNotification = notification
        committedVisible = false
        ApplyNotificationContent(notification)
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.QueueStatusToastFrame)

        local duration = GetNotificationDuration(notification.event)
        local fadeOutPlaying = IsFadingOut(frame)
        local showWithLootList = ShouldShowCurrencyWithLootList(notification.event)

        if frame:IsShown() and not fadeOutPlaying then
            StartDisplayTimer(generation, duration)
        elseif fadeOutPlaying or showWithLootList then
            ForceAnimatedShow(frame)
            StartDisplayTimer(generation, duration)
        else
            transitionTimer = C_Timer.NewTimer(GetAnimationDuration() + delay, function()
                transitionTimer = nil
                if generation ~= showGeneration then
                    return
                end
                ForceAnimatedShow(frame)
                StartDisplayTimer(generation, duration)
            end)
        end
    else
        ClearCommitment()
        -- В бою золото и валюта остаются в очереди: рамку не трогаем, если она уже скрыта
        if InCombatLockdown() and not frame:IsShown() and not IsFadingOut(frame) then
            return
        end
        ConsoleMenu:AnimatedHide(frame)
        transitionTimer = C_Timer.NewTimer(GetAnimationDuration() + delay, function()
            transitionTimer = nil
            if generation ~= showGeneration then
                return
            end
            ConsoleMenu:QueueStatusToastFrameUpdate()
        end)
    end
end

-- Возвращает золото и валюту в очередь и скрывает рамку на время боя
local function DeferCurrencyForCombat()
    if not committedNotification or not IsCurrencyNotification(committedNotification.event) then
        return
    end

    if ConsoleMenu.Notifications then
        table.insert(ConsoleMenu.Notifications, committedNotification)
    end
    committedNotification = nil
    committedVisible = false

    local generation = BeginShowGeneration()
    local frame = ConsoleMenuFrame.NotificationFrame
    ConsoleMenu:AnimatedHide(frame)
    transitionTimer = C_Timer.NewTimer(GetAnimationDuration() + delay, function()
        transitionTimer = nil
        if generation ~= showGeneration then
            return
        end
        ConsoleMenu:NotificationFrameUpdate()
    end)
end

-- Показывает ожидающее золото или валюту вместе со списком добычи
function ConsoleMenu:OnLootListAppeared()
    if InCombatLockdown() then
        return
    end
    if not committedNotification or committedVisible then
        return
    end
    if not IsCurrencyNotification(committedNotification.event) then
        return
    end
    if not transitionTimer then
        return
    end

    local generation = showGeneration
    local duration = GetNotificationDuration(committedNotification.event)
    transitionTimer:Cancel()
    transitionTimer = nil
    ForceAnimatedShow(ConsoleMenuFrame.NotificationFrame)
    StartDisplayTimer(generation, duration)
end

-- Создаёт рамку уведомлений и подписывается на события клиента
function ConsoleMenu:SetNotificationFrame()

    if not ConsoleMenu.Notifications then
        ConsoleMenu.Notifications = {}
    end

    if not ConsoleMenu.Deduplication then
        ConsoleMenu.Deduplication = {}
    end

    if not ConsoleMenuFrame.NotificationFrame then
        local frame = CreateFrame("Frame", nil, ConsoleMenuFrame)
        ConsoleMenuFrame.NotificationFrame = frame
    end

    local frame = ConsoleMenuFrame.NotificationFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 72, -72)
    ConsoleMenu:InitFadeAnimations(frame, GetAnimationDuration())
    frame:Hide()

    -- Основной текст уведомления
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

    -- Подпись под основным текстом
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
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Обрабатывает события клиента и ставит уведомления в очередь
    local function OnNotificationEvent(self, event, ...)

        if event == "PLAYER_REGEN_DISABLED" then
            DeferCurrencyForCombat()
            return

        elseif event == "PLAYER_REGEN_ENABLED" then
            ConsoleMenu:NotificationFrameUpdate()
            return

        elseif event == "UI_ERROR_MESSAGE" then

            -- Если выбран стандартный стиль ошибок интерфейса
            if ConsoleMenuDB.errorsFrameStyle == 1 then return end

            if InCombatLockdown() then return end

            local _, errorMessage = ...
            if not errorMessage or IsSecret(errorMessage) then
                return
            end

            local notificationFrame = ConsoleMenuFrame.NotificationFrame
            if notificationFrame:IsShown() and not IsFadingOut(notificationFrame) and errorMessage == notificationFrame.Text:GetText() then
                return
            end

            ConsoleMenu:AddNotification(event, errorMessage)

        elseif event == "CURRENCY_DISPLAY_UPDATE" then

            -- Если выбран стандартный стиль оповещений о получении валюты
            if ConsoleMenuDB.currencyDisplayUpdateStyle == 1 then return end

            local currencyID, _, quantityChange = ...
            if IsIgnoredCurrency(currencyID) then return end
            if not quantityChange or IsSecret(quantityChange) then return end

            if quantityChange > 0 then
                ConsoleMenu:AddNotification(event, nil, nil, currencyID, quantityChange)
            end

        elseif event == "PERKS_PROGRAM_CURRENCY_AWARDED" then

            -- Если выбран стандартный стиль оповещений о получении валюты
            if ConsoleMenuDB.currencyDisplayUpdateStyle == 1 then return end

            local value = ...
            if not value or IsSecret(value) then return end
            ConsoleMenu:AddNotification(event, nil, nil, tradersTenderCurrencyID, value)

        elseif event == "UPDATE_PENDING_MAIL" then

            -- Если выбран стандартный стиль оповещений о получении почты
            if ConsoleMenuDB.mailDisplayUpdateStyle == 1 then return end

            local notificationFrame = ConsoleMenuFrame.NotificationFrame
            local mailVisible = notificationFrame:IsShown() and not IsFadingOut(notificationFrame) and notificationFrame.Text:GetText() == HAVE_MAIL

            if not HasNewMail() then
                return
            end
            if HasQueuedEvent(event) then
                return
            end
            if ConsoleMenu.Deduplication[mailDeduplicationKey] and GetTime() <= ConsoleMenu.Deduplication[mailDeduplicationKey] then
                return
            end
            if mailVisible then
                return
            end
            if mailDelayTimer then
                return
            end

            mailDelayTimer = C_Timer.NewTimer(2, function()
                mailDelayTimer = nil
                if not HasNewMail() then
                    return
                end
                if HasQueuedEvent(event) then
                    return
                end
                if ConsoleMenu.Deduplication[mailDeduplicationKey] and GetTime() <= ConsoleMenu.Deduplication[mailDeduplicationKey] then
                    return
                end
                if notificationFrame:IsShown() and not IsFadingOut(notificationFrame) and notificationFrame.Text:GetText() == HAVE_MAIL then
                    return
                end
                ConsoleMenu:AddNotification(event, HAVE_MAIL)
            end)

        elseif IsZoneChangeEvent(event) then

            -- Если выбран стандартный стиль оповещений о смене области
            if ConsoleMenuDB.zoneTextFrameStyle == 1 then return end

            local zoneText = GetMinimapZoneText()
            if ConsoleMenu.Deduplication[zoneText] and GetTime() <= ConsoleMenu.Deduplication[zoneText] then return end

            ConsoleMenu:AddNotification(event)

        elseif event == "UI_INFO_MESSAGE" then

            local messageType, message = ...
            if not IsZoneExploredMessage(messageType) then
                return
            end

            -- Если выбран стандартный стиль оповещений о смене области
            if ConsoleMenuDB.zoneTextFrameStyle == 1 then return end

            if not message or IsSecret(message) then
                return
            end

            local zoneText, caption = ParseZoneExploredMessage(messageType, message)
            local notificationFrame = ConsoleMenuFrame.NotificationFrame

            if notificationFrame:IsShown() and zoneText == notificationFrame.Text:GetText() then
                RefreshVisibleCaption(caption, GetNotificationDuration(event))
            else
                ConsoleMenu:AddNotification(event, zoneText, caption, messageType)
            end

        else
            local msg = ...
            if msg and not IsSecret(msg) then
                ConsoleMenu:AddNotification(event, msg)
            end
        end

        RemoveOldDeduplication()
    end

    frame:SetScript("OnEvent", OnNotificationEvent)
end
