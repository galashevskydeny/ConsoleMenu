-- Отрисовка окна субтитров и планирование следующего обновления.

local ConsoleMenu = _G.ConsoleMenu
local Subtitle = ConsoleMenu.Subtitle

-- Отменяет отложенное обновление субтитров.
function Subtitle.CancelUpdateTimer()
    if Subtitle.updateTimer then
        Subtitle.updateTimer:Cancel()
        Subtitle.updateTimer = nil
    end
end

-- Задаёт размер фона по содержимому, не шире окна субтитров.
function Subtitle.SetBackgroundSizeFromContent(frame, contentWidth, contentHeight)
    if Subtitle.IsSecret(contentWidth) or Subtitle.IsSecret(contentHeight) then
        frame.Background:SetSize(
            Subtitle.frameWidth + Subtitle.backgroundOverlapHorizontal,
            Subtitle.frameHeight + Subtitle.backgroundOverlapVertical
        )
        return
    end

    if contentWidth > Subtitle.frameWidth then
        contentWidth = Subtitle.frameWidth
    end

    frame.Background:SetSize(
        contentWidth + Subtitle.backgroundOverlapHorizontal,
        contentHeight + Subtitle.backgroundOverlapVertical
    )
end

-- Снимает реплики разговора и запускает скрытие окна субтитров.
function Subtitle.CloseDialogue()
    Subtitle.closeToken = (Subtitle.closeToken or 0) + 1
    Subtitle.RemoveByPriority(1)
    ConsoleMenu:SubtitleFrameUpdate()
end

-- Назначает следующее обновление, если в очереди ещё есть реплики.
function Subtitle.ScheduleNextUpdate(current)
    Subtitle.CancelUpdateTimer()

    if current then
        if current.priority == 1 and current.lastLine then
            return
        end

        local now = GetTime()
        local durationLeft = (current.stopTime or now) - now
        if durationLeft < 0.05 then
            durationLeft = 0.05
        end

        Subtitle.updateTimer = C_Timer.NewTimer(durationLeft, function()
            ConsoleMenu:SubtitleFrameUpdate()
        end)
        return
    end

    if not Subtitle.queue then
        return
    end

    local now = GetTime()
    local nextStart = nil
    for i = 1, #Subtitle.queue do
        local subtitle = Subtitle.queue[i]
        if subtitle.startTime > now then
            if not nextStart or subtitle.startTime < nextStart then
                nextStart = subtitle.startTime
            end
        end
    end

    if nextStart then
        Subtitle.updateTimer = C_Timer.NewTimer(math.max(0.05, nextStart - now), function()
            ConsoleMenu:SubtitleFrameUpdate()
        end)
    end
end

-- Создаёт текстовые поля и фон окна субтитров.
function Subtitle.CreateDisplay(frame)
    frame:SetSize(Subtitle.frameWidth, Subtitle.frameHeight)
    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, Subtitle.frameBottomOffset)
    frame:Hide()
    ConsoleMenu:InitFadeAnimations(frame, Subtitle.animationDuration)

    -- Имя говорящего над текстом реплики.
    if not frame.Speaker then
        frame.Speaker = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Speaker:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Speaker:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Speaker:SetFont(Subtitle.fontName, Subtitle.speakerFontSize, "OUTLINE")
        frame.Speaker:SetTextColor(Subtitle.textColorR, Subtitle.textColorG, Subtitle.textColorB, 0.6)
        frame.Speaker:SetJustifyH("CENTER")
        frame.Speaker:SetText("")
        frame.Speaker:SetNonSpaceWrap(true)
        frame.Speaker:SetWordWrap(true)
        frame.Speaker:Hide()
    end

    -- Основной текст реплики.
    if not frame.Subtitle then
        frame.Subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Subtitle:SetPoint("TOPLEFT", frame.Speaker, "BOTTOMLEFT", 0, -6)
        frame.Subtitle:SetPoint("TOPRIGHT", frame.Speaker, "BOTTOMRIGHT", 0, -6)
        frame.Subtitle:SetFont(Subtitle.fontName, Subtitle.subtitleFontSize, "OUTLINE")
        frame.Subtitle:SetTextColor(Subtitle.textColorR, Subtitle.textColorG, Subtitle.textColorB, 1.0)
        frame.Subtitle:SetJustifyH("CENTER")
        frame.Subtitle:SetText("")
        frame.Subtitle:SetNonSpaceWrap(true)
        frame.Subtitle:SetWordWrap(true)
        frame.Subtitle:Hide()
    end

    -- Текст эмоции и полной ремарки без имени говорящего.
    if not frame.Emotion then
        frame.Emotion = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Emotion:SetPoint("LEFT", frame, "LEFT", 0, 0)
        frame.Emotion:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        frame.Emotion:SetFont(Subtitle.fontName, Subtitle.subtitleFontSize, "OUTLINE")
        frame.Emotion:SetTextColor(Subtitle.textColorR, Subtitle.textColorG, Subtitle.textColorB, 0.6)
        frame.Emotion:SetJustifyH("CENTER")
        frame.Emotion:SetText("")
        frame.Emotion:SetNonSpaceWrap(true)
        frame.Emotion:SetWordWrap(true)
        frame.Emotion:Hide()
    end

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.Background:SetTexture(Subtitle.backgroundTexture)
        frame.Background:SetSize(Subtitle.frameWidth, Subtitle.frameHeight)
    end
end

-- Обновляет показ текущей реплики.
function ConsoleMenu:SubtitleFrameUpdate(subtitle)
    local frame = Subtitle.GetFrame()
    if not frame then
        return
    end

    Subtitle.RemoveOld()

    local current = subtitle or Subtitle.GetCurrent()
    frame.CurrentSubtitle = current

    if current then
        frame.Speaker:SetText("")
        frame.Subtitle:SetText("")
        frame.Emotion:SetText("")

        if current.emotion then
            frame.Emotion:SetText(Subtitle.GetSafeDisplayText(current.text))
            frame.Emotion:Show()

            local width = frame.Emotion:GetStringWidth()
            local height = frame.Emotion:GetStringHeight()
            Subtitle.SetBackgroundSizeFromContent(frame, width, height)

            frame.Background:ClearAllPoints()
            frame.Background:SetPoint("CENTER", frame.Emotion, "CENTER", 0, 0)

            frame.Speaker:Hide()
            frame.Subtitle:Hide()
        else
            frame.Speaker:SetText(Subtitle.GetSafeDisplayText(current.sender))
            frame.Speaker:Show()

            local speakerH = frame.Speaker:GetStringHeight()

            frame.Subtitle:SetText(Subtitle.GetSafeDisplayText(current.text))
            frame.Subtitle:Show()

            local subW = frame.Subtitle:GetStringWidth()
            local subH = frame.Subtitle:GetStringHeight()
            if Subtitle.IsSecret(speakerH) or Subtitle.IsSecret(subW) or Subtitle.IsSecret(subH) then
                Subtitle.SetBackgroundSizeFromContent(frame, Subtitle.frameWidth, Subtitle.frameHeight)
            else
                Subtitle.SetBackgroundSizeFromContent(frame, subW, speakerH + subH)
            end

            frame.Background:ClearAllPoints()
            frame.Background:SetPoint("CENTER", frame.Subtitle, "CENTER", 0, 10)

            frame.Emotion:Hide()
        end

        Subtitle.UpdateDialogueKeyHints(current)

        if not frame:IsShown() then
            ConsoleMenu:AnimatedShow(frame)
        end

        Subtitle.ScheduleNextUpdate(current)
    else
        Subtitle.UpdateDialogueKeyHints(nil)
        ConsoleMenu:AnimatedHide(frame)
        Subtitle.ScheduleNextUpdate(nil)
    end
end
