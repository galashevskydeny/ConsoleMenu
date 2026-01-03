local ConsoleMenu = _G.ConsoleMenu

function ConsoleMenu:InitFadeAnimations(frame, duration)
    -- Создаем группу анимаций для фрейма, если еще не создана
    if not frame.fadeIn then
        -- Анимация появления (fade in)
        frame.fadeIn = frame:CreateAnimationGroup()
        frame.fadeIn.alpha = frame.fadeIn:CreateAnimation("Alpha")
        frame.fadeIn.alpha:SetFromAlpha(0)
        frame.fadeIn.alpha:SetToAlpha(1)
        frame.fadeIn.alpha:SetDuration(duration or 0.2)
        frame.fadeIn.alpha:SetSmoothing("OUT")

        frame.fadeIn:SetToFinalAlpha(true)
    end

    if not frame.fadeOut then
        -- Анимация исчезновения (fade out)
        frame.fadeOut = frame:CreateAnimationGroup()
        frame.fadeOut.alpha = frame.fadeOut:CreateAnimation("Alpha")
        frame.fadeOut.alpha:SetFromAlpha(1)
        frame.fadeOut.alpha:SetToAlpha(0)
        frame.fadeOut.alpha:SetDuration(duration or 0.2)
        frame.fadeOut.alpha:SetSmoothing("IN")

        frame.fadeOut:SetToFinalAlpha(true)
    end
end

function ConsoleMenu:AnimatedShow(frame)
    if not frame then return end
    frame:Show()
    frame:SetAlpha(0)
    frame.fadeOut:Stop()
    frame.fadeIn:Play()
end

function ConsoleMenu:AnimatedHide(frame)
    if not frame then return end
    frame:SetAlpha(1)
    frame.fadeIn:Stop()
    frame.fadeOut:Play()
    frame.fadeOut:SetScript("OnFinished", function()
        frame:Hide()
        frame.fadeOut:SetScript("OnFinished", nil)
    end)
end


