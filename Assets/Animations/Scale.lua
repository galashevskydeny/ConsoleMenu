local ConsoleMenu = _G.ConsoleMenu

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
    group.scaleDone = nil
end

-- Записывает размер и сразу возвращает кнопку на её место: клиент иначе тянет отступ к центру группы.
local function ApplyScale(frame, scale)
    local collapsed = scale <= 0
    local written = collapsed and SCALE_FLOOR or scale
    if written < SCALE_FLOOR then
        written = SCALE_FLOOR
    end
    frame.scaleZero = collapsed or nil
    frame:SetScale(written)
    local bar = ConsoleMenu.ActionBar
    if frame.mainKey and bar and bar.SeatButton then
        bar.SeatButton(frame)
    end
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
-- По окончании вызывает переданное действие. При обрыве прежнее действие не выполняется.
local function PlayScaleTo(frame, group, target, smoothing, onFinished)
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

    group.scaleDone = onFinished
    if math.abs(current - target) < SCALE_MATCH then
        if (target <= 0) ~= (frame.scaleZero == true) then
            ApplyScale(frame, target)
        end
        local done = group.scaleDone
        group.scaleDone = nil
        if done then
            done(frame)
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
    local bar = ConsoleMenu.ActionBar
    if frame.mainKey and bar and bar.SeatButton then
        bar.SeatButton(frame)
    end
    group:SetScript("OnUpdate", function(self)
        local scaleAnim = self.scale
        local scale = ScaleAtProgress(startScale, goalScale, AnimationProgress(scaleAnim, self))
        frame:SetScale(scale)
        if frame.mainKey and bar and bar.SeatButton then
            bar.SeatButton(frame)
        end
    end)
    group:SetScript("OnFinished", function(self)
        self:SetScript("OnUpdate", nil)
        self:SetScript("OnFinished", nil)
        ApplyScale(frame, target)
        local done = self.scaleDone
        self.scaleDone = nil
        if done then
            done(frame)
        end
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

-- Останавливает смену размера и оставляет кадр в текущем видимом размере.
function ConsoleMenu:StopScaleAnimation(frame)
    if not frame then
        return
    end
    ReleaseScaleGroup(frame.scaleUp)
    ReleaseScaleGroup(frame.scaleDown)
end

-- Увеличивает кадр до указанного размера.
-- Сглаживание: плавное начало или плавное окончание. Без него рост заканчивается плавно.
-- Последний аргумент выполняется, когда размер уже достигнут.
function ConsoleMenu:AnimatedScaleUp(frame, targetScale, easing, onFinished)
    if not frame or not frame.scaleUp or type(targetScale) ~= "number" then
        return
    end
    PlayScaleTo(frame, frame.scaleUp, targetScale, ScaleSmoothing(easing, "OUT"), onFinished)
end

-- Уменьшает кадр до указанного размера.
-- Сглаживание: плавное начало или плавное окончание. Без него сжатие ускоряется к концу.
-- Последний аргумент выполняется, когда размер уже достигнут.
function ConsoleMenu:AnimatedScaleDown(frame, targetScale, easing, onFinished)
    if not frame or not frame.scaleDown or type(targetScale) ~= "number" then
        return
    end
    PlayScaleTo(frame, frame.scaleDown, targetScale, ScaleSmoothing(easing, "IN"), onFinished)
end
