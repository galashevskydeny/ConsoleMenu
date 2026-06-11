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
    if not frame or not frame.fadeIn or not frame.fadeOut then return end

    -- Если фрейм уже показан, ничего не делаем
    if frame:IsShown() then return end
    
    -- Останавливаем все текущие анимации
    frame.fadeIn:Stop()
    frame.fadeOut:Stop()
    
    -- Удаляем предыдущий скрипт OnFinished, если он был установлен
    frame.fadeOut:SetScript("OnFinished", nil)
    
    -- Показываем фрейм и устанавливаем начальную альфу для анимации
    frame:Show()
    frame:SetAlpha(0)
    
    -- Запускаем анимацию появления
    frame.fadeIn:Play()
end

function ConsoleMenu:AnimatedHide(frame)
    if not frame or not frame.fadeIn or not frame.fadeOut then return end
    
    -- Если фрейм уже скрыт, ничего не делаем
    if not frame:IsShown() then return end
    
    -- Останавливаем все текущие анимации
    frame.fadeIn:Stop()
    frame.fadeOut:Stop()
    
    -- Удаляем предыдущий скрипт OnFinished, если он был установлен
    frame.fadeOut:SetScript("OnFinished", nil)
    
    -- Устанавливаем альфу в 1 для начала анимации исчезновения
    frame:SetAlpha(1)
    
    -- Устанавливаем скрипт для скрытия фрейма после окончания анимации
    frame.fadeOut:SetScript("OnFinished", function()
        frame:Hide()
        frame.fadeOut:SetScript("OnFinished", nil)
    end)
    
    -- Запускаем анимацию исчезновения
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


