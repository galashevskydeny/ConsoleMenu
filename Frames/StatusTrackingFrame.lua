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

local notificationUpdateTimer = nil

-- Функция для получения уведомления с наивысшим приоритетом
local function GetTopPriorityNotification()

    -- Обходим таблицу ConsoleMenu.Notifications с конца
    if not ConsoleMenuFrame.StatusTrackingFrame.Notifications or #ConsoleMenuFrame.StatusTrackingFrame.Notifications == 0 then
        return nil
    end

    local notification = ConsoleMenuFrame.StatusTrackingFrame.Notifications[1]

    -- Обходим таблицу с конца и удаляем все уведомления с таким же type
    if notification and notification.type then
        for i = #ConsoleMenuFrame.StatusTrackingFrame.Notifications, 1, -1 do
            if ConsoleMenuFrame.StatusTrackingFrame.Notifications[i].type == notification.type then
                table.remove(ConsoleMenuFrame.StatusTrackingFrame.Notifications, i)
            end
        end
    end

    return notification

end

-- Функция для обновления StatusTrackingFrame
local function StatusTrackingFrameUpdate()
    if not ConsoleMenuFrame.StatusTrackingFrame then
        return
    end

    -- Если таймер уже работает, не прерываем текущее отображение
    if notificationUpdateTimer then
        return
    end

    local notification = GetTopPriorityNotification()
    
    if notification then
        ConsoleMenuFrame.StatusTrackingFrame.FromText:SetText(notification.from)
        ConsoleMenuFrame.StatusTrackingFrame.ToText:SetText(notification.to)
        ConsoleMenuFrame.StatusTrackingFrame.Title:SetText(notification.title)

        if notification.type == "HouseFavor" then
            ConsoleMenuFrame.StatusTrackingFrame.Icon:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Icons\\housing.png")
        elseif notification.type == "Experience" then
            ConsoleMenuFrame.StatusTrackingFrame.Icon:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Icons\\expirience.png")
        elseif notification.type == "Honor" then
            ConsoleMenuFrame.StatusTrackingFrame.Icon:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Icons\\honor.png")
        end

        if notification.type == "HouseFavor" or notification.type == "Experience" or notification.type == "Honor" then
            ConsoleMenuFrame.StatusTrackingFrame.Title:Hide()
            ConsoleMenuFrame.StatusTrackingFrame.Icon:Show()
        else
            ConsoleMenuFrame.StatusTrackingFrame.Title:Show()
            ConsoleMenuFrame.StatusTrackingFrame.Icon:Hide()
        end

        local value = notification.value / notification.max * 100

        ConsoleMenuFrame.StatusTrackingFrame.StatusBar:SetMinMaxValues(0, 100)
        ConsoleMenuFrame.StatusTrackingFrame.StatusBar:SetValue(value)

        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.StatusTrackingFrame)

        notificationUpdateTimer = C_Timer.NewTimer(duration, function()
            notificationUpdateTimer = nil
            -- Скрываем текущее уведомление с анимацией
            ConsoleMenu:AnimatedHide(ConsoleMenuFrame.StatusTrackingFrame)
            -- Ждем окончания анимации исчезновения перед проверкой следующего уведомления
            C_Timer.After(animationDuration + delay, function()
                -- После отображения проверяем, есть ли еще уведомления в очереди
                StatusTrackingFrameUpdate()
            end)
        end)

    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.StatusTrackingFrame)
    end
end

-- Функция для добавления уведомления
local function AddNotification(type, from, to, title, value, min, max)
        -- Создаем таблицу субтитра
        local notificationData = {
            type = type,
            from = from,
            to = to,
            title = title,
            value = value,
            min = min,
            max = max,
        }

        table.insert(ConsoleMenuFrame.StatusTrackingFrame.Notifications, notificationData)

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
    frame:SetPoint("TOP", ConsoleMenuFrame, "TOP", 0, -(48 + macbookNotchOffset))
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

    frame:RegisterEvent("PLAYER_LEVEL_CHANGED")
    frame:RegisterEvent("PLAYER_XP_UPDATE")
    frame:RegisterEvent("HOUSE_LEVEL_FAVOR_UPDATED")

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
        end
    end

    frame:SetScript("OnEvent", OnStatusTrackingFrameEvent)
end