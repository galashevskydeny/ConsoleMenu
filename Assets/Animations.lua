local ConsoleMenu = _G.ConsoleMenu

-- Возвращает текущую прозрачность с учётом идущего проявления или исчезновения.
local function GetFadeAlpha(frame)
    local group
    if frame.fadeOut and frame.fadeOut:IsPlaying() then
        group = frame.fadeOut
    elseif frame.fadeIn and frame.fadeIn:IsPlaying() then
        group = frame.fadeIn
    end
    if group and group.alpha then
        local anim = group.alpha
        local progress = anim.GetSmoothProgress and anim:GetSmoothProgress() or group:GetProgress() or 0
        return anim:GetFromAlpha() + (anim:GetToAlpha() - anim:GetFromAlpha()) * progress
    end
    return frame:GetAlpha() or 1
end

-- Верхняя непрозрачность кадра. Без отдельного значения проявление идёт до полной.
local function FadeCeiling(frame)
    local alpha = frame and frame.fadeAlpha
    if not alpha or alpha > 1 then
        return 1
    end
    if alpha < 0 then
        return 0
    end
    return alpha
end

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
    if not frame or not frame.fadeIn or not frame.fadeOut then return end

    -- Запоминаем прозрачность до остановки, иначе сброс анимации вспыхивает на полной яркости.
    local current = GetFadeAlpha(frame)
    local shown = frame:IsShown()

    frame.fadeOut:Stop()
    frame.fadeOut:SetScript("OnFinished", nil)
    frame.fadeIn:Stop()

    local fadeIn = frame.fadeIn
    local ceiling = FadeCeiling(frame)
    if not shown then
        current = 0
        frame:Show()
    end
    if current >= ceiling then
        fadeIn.alpha:SetFromAlpha(0)
        fadeIn.alpha:SetToAlpha(ceiling)
        frame:SetAlpha(ceiling)
        return
    end

    frame:SetAlpha(current)
    fadeIn.alpha:SetFromAlpha(current)
    fadeIn.alpha:SetToAlpha(ceiling)
    fadeIn:Play()
end

function ConsoleMenu:AnimatedHide(frame)
    if not frame or not frame.fadeIn or not frame.fadeOut then return end
    if not frame:IsShown() then return end

    local current = GetFadeAlpha(frame)
    frame.fadeIn:Stop()
    frame.fadeOut:Stop()
    frame.fadeOut:SetScript("OnFinished", nil)

    if current <= 0 then
        frame:SetAlpha(0)
        frame:Hide()
        return
    end

    frame:SetAlpha(current)
    frame.fadeOut.alpha:SetFromAlpha(current)
    frame.fadeOut.alpha:SetToAlpha(0)
    frame.fadeOut:SetScript("OnFinished", function()
        frame:Hide()
        frame.fadeOut:SetScript("OnFinished", nil)
        frame.fadeOut.alpha:SetFromAlpha(FadeCeiling(frame))
        frame.fadeOut.alpha:SetToAlpha(0)
    end)
    frame.fadeOut:Play()
end

function ConsoleMenu:PlayFadeIn(frame)
    if not frame or not frame.fadeIn then return end
    if frame:GetAlpha() ~= 0 then return end
    frame.fadeIn:Play()
end

function ConsoleMenu:PlayFadeOut(frame)
    if frame:GetAlpha() ~= 1 then return end
    if not frame or not frame.fadeOut then return end
    frame.fadeOut:Play()
end


