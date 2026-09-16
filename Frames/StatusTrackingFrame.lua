local ConsoleMenu = _G.ConsoleMenu

local frameHeight = 18
local frameWidth = (308 / 16) * frameHeight

local macbookNotchOffset = 16
local padding = 12
local iconSize = 24

local fontSize = 20

local duration = 5
local animationDuration = 0.3
local delay = 0.5

-- Смещает полосу вниз при включённом вырезе экрана.
local function TopOffset()
    local offset = -48
    if ConsoleMenuDB and ConsoleMenuDB.enableMacBook == 1 then
        offset = offset - macbookNotchOffset
    end
    return offset
end

-- Прячет или возвращает полосу навигации на время индикатора опыта.
local function SetCompassProgressHidden(hidden)
    local compass = ConsoleMenu.Compass
    if compass and compass.SetProgressHidden then
        compass:SetProgressHidden(hidden)
    end
end

local notificationUpdateTimer = nil
local compassRestoreTimer = nil
local currentNotification = nil
local pendingShowToken = 0
local progressAnimToken = 0
local lastProgressByType = {}

-- Проверяет, находится ли игрок в бою.
local function IsPlayerInCombat()
    return UnitAffectingCombat("player")
end

-- Возвращает список ожидающих изменений полосы.
local function GetNotifications()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.StatusTrackingFrame
    if not frame then
        return nil
    end
    if not frame.Notifications then
        frame.Notifications = {}
    end
    return frame.Notifications
end

-- Отменяет отложенное появление компаса, если снова показана строка статуса.
local function CancelCompassRestore()
    if compassRestoreTimer then
        compassRestoreTimer:Cancel()
        compassRestoreTimer = nil
    end
end

-- Возвращает компас после исчезновения строки статуса и короткой паузы.
local function ScheduleCompassRestore()
    CancelCompassRestore()
    compassRestoreTimer = C_Timer.NewTimer(animationDuration + delay, function()
        compassRestoreTimer = nil
        local notifications = GetNotifications()
        if notifications and #notifications > 0 then
            return
        end
        if currentNotification then
            return
        end
        SetCompassProgressHidden(false)
    end)
end

-- Заменяет ожидающее изменение того же типа последним снимком.
local function ReplaceQueuedNotification(notification)
    local notifications = GetNotifications()
    if not notifications then
        return
    end

    local foundIndex
    for i = 1, #notifications do
        if notifications[i].type == notification.type then
            foundIndex = i
            break
        end
    end

    if foundIndex then
        notifications[foundIndex] = notification
        for i = #notifications, foundIndex + 1, -1 do
            if notifications[i].type == notification.type then
                table.remove(notifications, i)
            end
        end
    else
        table.insert(notifications, notification)
    end
end

-- Берёт последний снимок первого типа в списке и удаляет все того же типа.
local function GetTopPriorityNotification()
    local notifications = GetNotifications()
    if not notifications or #notifications == 0 then
        return nil
    end

    local notificationType = notifications[1].type
    local notification

    for i = #notifications, 1, -1 do
        if notifications[i].type == notificationType then
            if not notification then
                notification = notifications[i]
            end
            table.remove(notifications, i)
        end
    end

    return notification
end

-- Возвращает заполнение полосы в процентах по снимку.
local function GetProgressPercent(notification)
    if not notification.max or notification.max == 0 then
        return 0
    end
    return notification.value / notification.max * 100
end

-- Останавливает плавное изменение заполнения полосы.
local function StopProgressAnimation()
    progressAnimToken = progressAnimToken + 1
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.StatusTrackingFrame
    local statusBar = frame and frame.StatusBar
    if statusBar then
        statusBar:SetScript("OnUpdate", nil)
    end
end

-- Плавно меняет заполнение полосы от начального значения к целевому.
local function AnimateProgress(fromValue, toValue)
    local frame = ConsoleMenuFrame.StatusTrackingFrame
    local statusBar = frame.StatusBar
    statusBar:SetMinMaxValues(0, 100)

    StopProgressAnimation()

    if fromValue > toValue then
        fromValue = 0
    end

    statusBar:SetValue(fromValue)

    if fromValue == toValue then
        return
    end

    local token = progressAnimToken
    local elapsed = 0
    statusBar:SetScript("OnUpdate", function(self, dt)
        if token ~= progressAnimToken then
            self:SetScript("OnUpdate", nil)
            return
        end
        elapsed = elapsed + dt
        local t = elapsed / animationDuration
        if t >= 1 then
            self:SetValue(toValue)
            self:SetScript("OnUpdate", nil)
            return
        end
        local eased = 1 - (1 - t) * (1 - t)
        self:SetValue(fromValue + (toValue - fromValue) * eased)
    end)
end

-- Запускает рост полосы от последнего значения к новому.
local function AnimateNotificationProgress(notification, fromValue)
    local toValue = GetProgressPercent(notification)
    if fromValue == nil then
        fromValue = lastProgressByType[notification.type] or 0
    end
    AnimateProgress(fromValue, toValue)
    lastProgressByType[notification.type] = toValue
end

-- Запоминает текущий опыт, чтобы первая анимация шла от него, а не от нуля.
local function SeedExperienceProgress()
    local maxXP = UnitXPMax("player")
    if not maxXP or maxXP == 0 then
        return
    end
    lastProgressByType.Experience = UnitXP("player") / maxXP * 100
end

-- Заполняет подписи и значок полосы статуса данными снимка.
local function ApplyNotificationPresentation(notification)
    local frame = ConsoleMenuFrame.StatusTrackingFrame

    frame.FromText:SetText(notification.from)
    frame.ToText:SetText(notification.to)
    frame.Title:SetText(notification.title)

    if notification.type == "HouseFavor" then
        frame.Icon:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Icons\\housing.png")
    elseif notification.type == "Experience" then
        frame.Icon:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Icons\\expirience.png")
    elseif notification.type == "Honor" then
        frame.Icon:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Icons\\honor.png")
    end

    if notification.type == "HouseFavor" or notification.type == "Experience" or notification.type == "Honor" then
        frame.Title:Hide()
        frame.Icon:Show()
    else
        frame.Title:Show()
        frame.Icon:Hide()
    end
end

-- Скрывает полосу сразу, без анимации исчезновения.
local function HideStatusTrackingNow()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.StatusTrackingFrame
    if not frame then
        return
    end

    if frame.fadeIn then
        frame.fadeIn:Stop()
    end
    if frame.fadeOut then
        frame.fadeOut:Stop()
        frame.fadeOut:SetScript("OnFinished", nil)
    end

    StopProgressAnimation()
    frame:Hide()
    frame:SetAlpha(1)
end

-- Отменяет текущий показ и отложенный переход к следующей полосе.
local function CancelNotificationDisplay()
    pendingShowToken = pendingShowToken + 1
    if notificationUpdateTimer then
        notificationUpdateTimer:Cancel()
        notificationUpdateTimer = nil
    end
end

-- Скрывает полосу при входе в бой и сохраняет текущий снимок.
local function HideForCombat()
    CancelNotificationDisplay()
    CancelCompassRestore()

    if currentNotification then
        ReplaceQueuedNotification(currentNotification)
        currentNotification = nil
    end

    HideStatusTrackingNow()
    SetCompassProgressHidden(false)
end

-- Показывает следующее изменение полосы, если игрок не в бою.
local function StatusTrackingFrameUpdate()
    if not ConsoleMenuFrame.StatusTrackingFrame then
        return
    end

    -- Если таймер уже работает, не прерываем текущее отображение
    if notificationUpdateTimer then
        return
    end

    if IsPlayerInCombat() then
        return
    end

    local notification = GetTopPriorityNotification()

    if notification then
        currentNotification = notification
        ApplyNotificationPresentation(notification)

        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.StatusTrackingFrame)
        AnimateNotificationProgress(notification)
        CancelCompassRestore()
        SetCompassProgressHidden(true)

        local token = pendingShowToken
        notificationUpdateTimer = C_Timer.NewTimer(duration, function()
            if token ~= pendingShowToken then
                return
            end
            notificationUpdateTimer = nil
            currentNotification = nil
            -- Скрываем текущее уведомление с анимацией
            ConsoleMenu:AnimatedHide(ConsoleMenuFrame.StatusTrackingFrame)
            local notifications = GetNotifications()
            if not notifications or #notifications == 0 then
                -- Компас проявится после исчезновения строки и паузы.
                ScheduleCompassRestore()
            end
            -- Ждем окончания анимации исчезновения перед проверкой следующего уведомления
            C_Timer.After(animationDuration + delay, function()
                if token ~= pendingShowToken then
                    return
                end
                StatusTrackingFrameUpdate()
            end)
        end)

    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.StatusTrackingFrame)
    end
end

-- Добавляет снимок изменения полосы или обновляет уже показанный.
local function AddNotification(type, from, to, title, value, min, max)
        local notificationData = {
            type = type,
            from = from,
            to = to,
            title = title,
            value = value,
            min = min,
            max = max,
        }

        -- Та же полоса уже на экране: обновляем значение, не продлевая показ.
        if currentNotification and currentNotification.type == type then
            currentNotification = notificationData
            ApplyNotificationPresentation(notificationData)
            local statusBar = ConsoleMenuFrame.StatusTrackingFrame.StatusBar
            AnimateNotificationProgress(notificationData, statusBar:GetValue())
            return
        end

        ReplaceQueuedNotification(notificationData)

        if not notificationUpdateTimer then
            StatusTrackingFrameUpdate()
        end

        return
end

function ConsoleMenu:SetStatusTrackingFrame()

    if ConsoleMenuDB.statusTrackingBarManagerStyle == 1 then return end

    if not ConsoleMenuFrame.StatusTrackingFrame then
        local frame = CreateFrame("Frame", "StatusTrackingFrame", ConsoleMenuFrame)
        
        -- Простой StatusBar (все методы уже есть в WoW API)
        local statusBar = CreateFrame("StatusBar", nil, frame)
        statusBar:SetAllPoints(frame)
        statusBar:SetStatusBarTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\healthBar.png")
        statusBar:SetStatusBarColor(1.0, 0.960784, 0.772549, 1)
        statusBar:SetMinMaxValues(0, 100)
        statusBar:SetValue(20)
        
        frame.StatusBar = statusBar
        ConsoleMenuFrame.StatusTrackingFrame = frame
    end

    if not ConsoleMenuFrame.StatusTrackingFrame.Notifications then
        ConsoleMenuFrame.StatusTrackingFrame.Notifications = {}
    end

    local frame = ConsoleMenuFrame.StatusTrackingFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOP", ConsoleMenuFrame, "TOP", 0, TopOffset())
    frame:Hide()
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetAllPoints()
        frame.Background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\healthBar.png")
        frame.Background:SetVertexColor(0, 0, 0, 0.4)
    end

    -- Текст "from" слева
    if not frame.FromText then
        frame.FromText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        frame.FromText:SetPoint("RIGHT", frame, "LEFT", -padding, 0)
        frame.FromText:SetText("80")
        frame.FromText:SetJustifyH("LEFT")
        frame.FromText:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.FromText:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")

    end

    -- Текст "to" справа
    if not frame.ToText then
        frame.ToText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        frame.ToText:SetPoint("LEFT", frame, "RIGHT", padding, 0)
        frame.ToText:SetText("81")
        frame.ToText:SetJustifyH("RIGHT")
        frame.ToText:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.ToText:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
    end

    -- Текст "Title" снизу
    if not frame.Title then
        frame.Title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        frame.Title:SetPoint("TOP", frame, "BOTTOM", 0, -padding)
        frame.Title:SetText("Название")
        frame.Title:SetJustifyH("RIGHT")
        frame.Title:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Title:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
    end

    -- Иконка
    if not frame.Icon then
        frame.Icon = frame:CreateTexture(nil, "ARTWORK")
        frame.Icon:SetPoint("RIGHT", frame.FromText, "LEFT", -padding, 0)
        frame.Icon:SetSize(iconSize, iconSize)
        frame.Icon:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Icons\\housing.png")
        frame.Icon:SetVertexColor(1.0, 0.960784, 0.772549, 1)
    end

    SeedExperienceProgress()

    frame:RegisterEvent("PLAYER_LEVEL_CHANGED")
    frame:RegisterEvent("PLAYER_XP_UPDATE")
    frame:RegisterEvent("HOUSE_LEVEL_FAVOR_UPDATED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    local function OnStatusTrackingFrameEvent(self, event, ...)
        if event == "PLAYER_LEVEL_CHANGED" then
            local min = 0
            local max = UnitXPMax("player")
            local value = UnitXP("player")

            local from
            local to

            local _, newLevel, _ = ...

            if newLevel < GameRulesUtil.GetEffectiveMaxLevelForPlayer() then
                from = newLevel
                to = newLevel + 1
            else
                return
            end

            AddNotification("Experience", from, to, nil, value, min, max)
        elseif event == "PLAYER_XP_UPDATE" then
            local min = 0
            local max = UnitXPMax("player")
            local value = UnitXP("player")

            local from
            local to

            local level = UnitLevel("player")

            if level < GameRulesUtil.GetEffectiveMaxLevelForPlayer() then
                from = level
                to = level + 1
            else
                return
            end

            AddNotification("Experience", from, to, nil, value, min, max)
        elseif event == "HOUSE_LEVEL_FAVOR_UPDATED" then 
            local min = 0

            local houseLevelFavor = ...
            local currentLevel = houseLevelFavor.houseLevel
            local value = houseLevelFavor.houseFavor

            local value = value - C_Housing.GetHouseLevelFavorForLevel(currentLevel)
            local max = C_Housing.GetHouseLevelFavorForLevel(currentLevel+1) - C_Housing.GetHouseLevelFavorForLevel(currentLevel)

            AddNotification("HouseFavor", currentLevel, currentLevel + 1, nil, value, min, max)
        elseif event == "PLAYER_REGEN_DISABLED" then
            HideForCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            StatusTrackingFrameUpdate()
        end
    end

    frame:SetScript("OnEvent", OnStatusTrackingFrameEvent)
end
