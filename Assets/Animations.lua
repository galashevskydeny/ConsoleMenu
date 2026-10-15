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

-- Незаметная глазу разница размеров.
local SCALE_MATCH = 0.0005

-- Наименьший размер, который клиент позволяет записать. Ноль он не принимает.
local SCALE_FLOOR = 0.001

-- Переводит название сглаживания в значение клиента.
-- Плавное начало: «easeIn» и «easyIn». Плавное окончание: «easeOut» и «easyOut».
local function ScaleSmoothing(easing, fallback)
    if easing == "easeIn" or easing == "easyIn" then
        return "IN"
    end
    if easing == "easeOut" or easing == "easyOut" then
        return "OUT"
    end
    return fallback
end

-- Возвращает группу, которая сейчас меняет размер.
local function ActiveScaleGroup(frame)
    local grow = frame.scaleUp
    local shrink = frame.scaleDown
    if grow and grow:IsPlaying() then
        return grow
    end
    if shrink and shrink:IsPlaying() then
        return shrink
    end
end

-- Возвращает текущий видимый размер.
-- После уменьшения до нуля возвращает ноль, хотя в кадре записан наименьший допустимый размер.
local function GetAnimatedScale(frame)
    if ActiveScaleGroup(frame) then
        return frame:GetScale() or 1
    end
    if frame.scaleZero then
        return 0
    end
    return frame:GetScale() or 1
end

-- Крайние размеры перехода. Ноль заменяется наименьшим допустимым, чтобы не умножать картинку.
local function ScaleAnimationSpan(current, target)
    local startScale = current
    if not startScale or startScale <= SCALE_FLOOR then
        startScale = SCALE_FLOOR
    end
    local goalScale = target
    if not goalScale or goalScale <= SCALE_FLOOR then
        goalScale = SCALE_FLOOR
    end
    return startScale, goalScale
end

-- Размер на указанной доле пути от начального к конечному.
local function ScaleAtProgress(startScale, goalScale, progress)
    if progress < 0 then
        progress = 0
    elseif progress > 1 then
        progress = 1
    end
    local scale = startScale + (goalScale - startScale) * progress
    if scale < SCALE_FLOOR then
        return SCALE_FLOOR
    end
    return scale
end

-- Останавливает изменение размера.
local function ReleaseScaleGroup(group)
    if not group then
        return
    end
    group:SetScript("OnFinished", nil)
    group:SetScript("OnUpdate", nil)
    if group:IsPlaying() or group:IsPaused() then
        group:Stop()
    end
    if group.scale then
        group.scale:SetScaleFrom(1, 1)
        group.scale:SetScaleTo(1, 1)
    end
end

-- Записывает размер в кадр, не трогая его привязки.
-- Ноль сохраняется как наименьший допустимый размер, поэтому область нажатия тоже сжимается.
local function ApplyScale(frame, scale)
    local collapsed = scale <= 0
    local written = collapsed and SCALE_FLOOR or scale
    if written < SCALE_FLOOR then
        written = SCALE_FLOOR
    end
    frame.scaleZero = collapsed or nil
    frame:SetScale(written)
end

-- Сглаженный ход анимации от нуля до единицы.
local function AnimationProgress(anim, group)
    if anim and anim.GetSmoothProgress then
        return anim:GetSmoothProgress() or 0
    end
    if group and group.GetProgress then
        return group:GetProgress() or 0
    end
    return 0
end

-- Меняет размер от текущего видимого к указанному и записывает его по завершении.
local function PlayScaleTo(frame, group, target, smoothing)
    if target < 0 then
        target = 0
    end

    local current = GetAnimatedScale(frame)
    if current < 0 then
        current = 0
    end

    local wasPlaying = ActiveScaleGroup(frame) ~= nil
    ReleaseScaleGroup(frame.scaleUp)
    ReleaseScaleGroup(frame.scaleDown)
    if wasPlaying then
        ApplyScale(frame, current)
        current = frame.scaleZero and 0 or (frame:GetScale() or current)
    end

    if math.abs(current - target) < SCALE_MATCH then
        if (target <= 0) ~= (frame.scaleZero == true) then
            ApplyScale(frame, target)
        end
        return
    end

    local startScale, goalScale = ScaleAnimationSpan(current, target)
    -- Сама анимация масштаба остаётся единичной, чтобы не увеличивать картинку поверх размера кадра.
    local anim = group.scale
    anim:SetSmoothing(smoothing)
    anim:SetScaleFrom(1, 1)
    anim:SetScaleTo(1, 1)
    frame.scaleZero = nil
    frame:SetScale(startScale)
    group:SetScript("OnUpdate", function(self)
        local scaleAnim = self.scale
        local scale = ScaleAtProgress(startScale, goalScale, AnimationProgress(scaleAnim, self))
        frame:SetScale(scale)
    end)
    group:SetScript("OnFinished", function(self)
        self:SetScript("OnUpdate", nil)
        self:SetScript("OnFinished", nil)
        ApplyScale(frame, target)
    end)
    group:Play()
end

-- Создаёт группу изменения размера. Привязки кадра не сдвигаются.
local function CreateScaleGroup(frame, duration, smoothing)
    local group = frame:CreateAnimationGroup()
    local scale = group:CreateAnimation("Scale")
    scale:SetScaleFrom(1, 1)
    scale:SetScaleTo(1, 1)
    scale:SetDuration(duration or 0.2)
    scale:SetSmoothing(smoothing)
    scale:SetOrigin("CENTER", 0, 0)
    group.scale = scale
    return group
end

-- Готовит кадр к увеличению и уменьшению. Длительность задаётся один раз.
function ConsoleMenu:InitScaleAnimations(frame, duration)
    if not frame.scaleUp then
        frame.scaleUp = CreateScaleGroup(frame, duration, "OUT")
    end
    if not frame.scaleDown then
        frame.scaleDown = CreateScaleGroup(frame, duration, "IN")
    end
end

-- Увеличивает кадр до указанного размера.
-- Сглаживание: плавное начало или плавное окончание. Без него рост заканчивается плавно.
function ConsoleMenu:AnimatedScaleUp(frame, targetScale, easing)
    if not frame or not frame.scaleUp or type(targetScale) ~= "number" then
        return
    end
    PlayScaleTo(frame, frame.scaleUp, targetScale, ScaleSmoothing(easing, "OUT"))
end

-- Уменьшает кадр до указанного размера.
-- Сглаживание: плавное начало или плавное окончание. Без него сжатие ускоряется к концу.
function ConsoleMenu:AnimatedScaleDown(frame, targetScale, easing)
    if not frame or not frame.scaleDown or type(targetScale) ~= "number" then
        return
    end
    PlayScaleTo(frame, frame.scaleDown, targetScale, ScaleSmoothing(easing, "IN"))
end


