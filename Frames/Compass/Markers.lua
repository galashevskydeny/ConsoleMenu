-- Markers.lua
-- Значки на полосе: пул рамок, отбор, группы и отрисовка.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Pixel = Compass.Pixel
local FULL_TEX_COORDS = { left = 0, right = 1, top = 0, bottom = 1 }
local ICON_COLOR = { r = 1, g = 1, b = 1 }
local nearbyOrder = {}

-- Проверяет, идёт ли проявление или скрытие рамки значка.
local function MarkerFadePlaying(button)
    return button
        and (
            (button.fadeIn and button.fadeIn:IsPlaying())
            or (button.fadeOut and button.fadeOut:IsPlaying())
        )
end

-- Текущая прозрачность рамки с учётом идущей анимации.
local function MarkerFrameAlpha(button)
    local group
    if button.fadeOut and button.fadeOut:IsPlaying() then
        group = button.fadeOut
    elseif button.fadeIn and button.fadeIn:IsPlaying() then
        group = button.fadeIn
    end
    if group and group.alpha then
        local anim = group.alpha
        local progress = anim.GetSmoothProgress and anim:GetSmoothProgress() or group:GetProgress() or 0
        return anim:GetFromAlpha() + (anim:GetToAlpha() - anim:GetFromAlpha()) * progress
    end
    return button:GetAlpha() or 1
end

-- Останавливает проявление или скрытие подписи слота.
local function StopLabelFade(button)
    local frame = button and button.labelFrame
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
    frame:SetAlpha(1)
end

-- Прозрачность значка с учётом края полосы и исходного рисунка.
local function MarkerTargetAlpha(marker)
    if not marker then
        return 1
    end
    local alpha = (marker.projectedAlpha or 1) * (marker.sourceAlpha or 1)
    if alpha < 0 then
        return 0
    end
    if alpha > 1 then
        return 1
    end
    return alpha
end

-- Значок должен доиграть скрытие и не проявляться снова.
local function MarkerHoldsFade(self, marker)
    if not marker then
        return false
    end
    local key = marker.key
    local rangeLeaving = self.rangeLeaving
    if rangeLeaving then
        for index = 1, #rangeLeaving do
            if rangeLeaving[index].key == key then
                return true
            end
        end
    end
    local fading = self.nearbyFading
    for index = 1, #fading do
        if fading[index].key == key then
            return true
        end
    end
    return #self.arrivalMarkers == 0 and (self.arrivalBlend or 0) > 0 and self:IsNearbyFocus(marker)
end

-- Задаёт цвет названия и тусклость второстепенной подписи.
-- Доля проявления идёт в канал прозрачности цвета; вторая строка дополнительно тусклее.
local function ApplyNearbyLabelColors(button, fade)
    if not button or not button.title then
        return
    end
    if type(fade) ~= "number" then
        fade = 1
    elseif fade < 0 then
        fade = 0
    elseif fade > 1 then
        fade = 1
    end
    local color = Compass.Constants.LINE_COLOR
    button.title:SetTextColor(color.r, color.g, color.b, fade)
    button.caption:SetTextColor(color.r, color.g, color.b, Compass.Constants.LABEL_CAPTION_ALPHA * fade)
end

-- Ставит одну прозрачность значку и его подсветке.
local function SetMarkerFrameAlpha(button, alpha)
    button:SetAlpha(alpha)
    if button.glowFrame then
        button.glowFrame:SetAlpha(alpha)
    end
end

-- Останавливает проявление и скрытие рамки.
local function StopFrameFade(frame)
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
end

-- Проявляет рамку до заданной прозрачности.
local function StartFrameFadeIn(frame, toAlpha, current)
    if not frame then
        return
    end
    local fadeIn, fadeOut = frame.fadeIn, frame.fadeOut
    if not fadeIn or not fadeOut then
        frame:Show()
        frame:SetAlpha(toAlpha)
        return
    end
    StopFrameFade(frame)
    if not frame:IsShown() then
        current = 0
        frame:Show()
    end
    if current >= toAlpha then
        frame:SetAlpha(toAlpha)
        return
    end
    frame:SetAlpha(current)
    fadeIn.alpha:SetFromAlpha(current)
    fadeIn.alpha:SetToAlpha(toAlpha)
    fadeIn:Play()
end

-- Возвращает исходную прозрачность рамки значка после анимации полосы.
local function RestoreMarkerTextures(button)
    if not MarkerFadePlaying(button) then
        button:SetAlpha(1)
    end
    local glowFrame = button.glowFrame
    if glowFrame and not MarkerFadePlaying(glowFrame) then
        glowFrame:SetAlpha(1)
    end
    -- Тусклость подписи хранится в цвете текста: SetAlpha её затирает.
    ApplyNearbyLabelColors(button)
    button.renderAlpha = nil
end

-- Скрывает подпись слота сразу, без анимации.
local function HideNearbyLabels(button)
    if not button then
        return
    end
    StopLabelFade(button)
    if button.labelFrame then
        button.labelFrame:Hide()
        button.labelFrame:SetAlpha(1)
    elseif button.title then
        button.title:Hide()
        button.caption:Hide()
    end
    button.labelShown, button.labelName, button.labelCaption = false, nil, nil
    button.labelX, button.labelY = nil, nil
    ApplyNearbyLabelColors(button)
end

-- Скрывает все подписи «поблизости», чтобы обводка не оставалась при скрытии полосы.
function Compass:HideAllNearbyLabels()
    local slots = self.markerSlots
    if not slots then
        return
    end
    for index = 1, #slots do
        HideNearbyLabels(slots[index])
    end
end

-- Проявляет значок целиком до уже посчитанной прозрачности, без вспышки на полную яркость.
local function FadeMarkerIn(button, toAlpha)
    if not button then
        return
    end
    button.leaving = false
    toAlpha = toAlpha or 1
    if toAlpha < 0 then
        toAlpha = 0
    elseif toAlpha > 1 then
        toAlpha = 1
    end
    local current = MarkerFrameAlpha(button)
    if not button:IsShown() then
        current = 0
    end
    StartFrameFadeIn(button, toAlpha, current)
    local glowFrame = button.glowFrame
    if glowFrame then
        local glowCurrent = MarkerFrameAlpha(glowFrame)
        if not glowFrame:IsShown() then
            glowCurrent = 0
        end
        StartFrameFadeIn(glowFrame, toAlpha, glowCurrent)
    end
    button.renderShown = true
    button.renderAlpha = MarkerFrameAlpha(button)
end

-- Гасит значок целиком и помечает слот к освобождению.
local function FadeMarkerOut(button)
    if not button or button.leaving then
        return
    end
    button.leaving = true
    button.revealAt = nil
    HideNearbyLabels(button)
    local fadeOut = button.fadeOut
    ConsoleMenu:AnimatedHide(button)
    if button.glowFrame then
        ConsoleMenu:AnimatedHide(button.glowFrame)
    end
    if not fadeOut or not fadeOut:IsPlaying() then
        button.renderShown = false
        button.leaving = false
        button.smoothLeft = nil
        return
    end
    local finished = fadeOut:GetScript("OnFinished")
    fadeOut:SetScript("OnFinished", function(...)
        if finished then
            finished(...)
        end
        button.renderShown = false
        button.leaving = false
        button.smoothLeft = nil
        Compass.markerSlotsDirty = true
        Compass.selectionDirty = true
        Compass.renderDirty = true
    end)
end

-- Задаёт длительность анимации, только если она сейчас не играет.
local function SetIdleFadeDuration(group, duration)
    if not group or not group.alpha or group:IsPlaying() then
        return
    end
    group.alpha:SetDuration(duration)
end

-- Плавно показывает или прячет подпись слота.
local function SetNearbyLabelsShown(button, shown)
    local frame = button and button.labelFrame
    if shown then
        if not button.labelShown then
            button.labelShown = true
            SetIdleFadeDuration(frame and frame.fadeIn, Compass.Constants.LABEL_FADE_DURATION)
            ConsoleMenu:AnimatedShow(frame)
        end
    elseif button.labelShown then
        button.labelShown = false
        local duration = Compass.nearbyReflowPhase == "hide" and Compass.Constants.NEARBY_LABEL_HIDE_DURATION
            or Compass.Constants.LABEL_FADE_DURATION
        if Compass.nearbyReflowPhase == "hide" and frame and frame.fadeOut and frame.fadeOut.alpha then
            -- Короткое скрытие перед разъездом: останавливаем текущее исчезновение и запускаем заново.
            frame.fadeOut.alpha:SetDuration(duration)
        else
            SetIdleFadeDuration(frame and frame.fadeOut, duration)
        end
        ConsoleMenu:AnimatedHide(frame)
    end
end

-- Создаёт пул декоративных значков без мыши.
function Compass:CreateMarkerPool()
    local C = self.Constants
    self.markerPool = CreateObjectPool(function()
        local button = CreateFrame("Frame", nil, self.frame)
        button:EnableMouse(false)
        button.icon = button:CreateTexture(nil, "OVERLAY", nil, C.MARKER_ICON_SUBLEVEL)
        button.background = button:CreateTexture(nil, "OVERLAY", nil, C.MARKER_BACKGROUND_SUBLEVEL)
        button.shadow = button:CreateTexture(nil, "OVERLAY", nil, C.MARKER_SHADOW_SUBLEVEL)
        button.underlay = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAlpha(1)
        button.background:SetAlpha(1)
        button.shadow:SetAlpha(1)
        button.underlay:SetAlpha(1)
        button.shadow:SetVertexColor(0, 0, 0, C.MARKER_OUTLINE_ALPHA)
        button.icon:SetRotation(0)
        button.background:SetRotation(0)
        button.shadow:SetRotation(0)
        button.underlay:SetRotation(0)
        button.icon:Show()
        button.shadow:Show()
        button.background:Hide()
        button.underlay:Hide()
        -- Подсветка на отдельной рамке ниже значков, чтобы не накрывать соседние точки.
        local glowFrame = CreateFrame("Frame", nil, self.frame)
        glowFrame:EnableMouse(false)
        glowFrame:SetClipsChildren(false)
        glowFrame:Hide()
        ConsoleMenu:InitFadeAnimations(glowFrame, C.MARKER_APPEAR_DURATION)
        button.glowFrame = glowFrame
        button.trackedGlow = glowFrame:CreateTexture(nil, "ARTWORK")
        button.trackedGlow:SetAtlas(C.TRACKED_GLOW_ATLAS)
        button.trackedGlow:SetAlpha(1)
        button.trackedGlow:Hide()
        button:SetClipsChildren(false)
        ConsoleMenu:InitFadeAnimations(button, C.MARKER_APPEAR_DURATION)
        -- Название и тип на полосе, чтобы подпись не обрезалась рамкой значка.
        local labelFrame = CreateFrame("Frame", nil, self.frame)
        labelFrame:EnableMouse(false)
        labelFrame:SetClipsChildren(false)
        labelFrame:SetFrameLevel(self.frame:GetFrameLevel() + 2)
        labelFrame:Hide()
        ConsoleMenu:InitFadeAnimations(labelFrame, C.LABEL_FADE_DURATION)
        button.labelFrame = labelFrame
        button.title = labelFrame:CreateFontString(nil, "OVERLAY")
        button.title:SetMaxLines(2)
        button.title:SetJustifyH("CENTER")
        button.title:SetWordWrap(true)
        button.title:SetNonSpaceWrap(true)
        button.caption = labelFrame:CreateFontString(nil, "OVERLAY")
        button.caption:SetMaxLines(2)
        button.caption:SetJustifyH("CENTER")
        button.caption:SetWordWrap(true)
        button.caption:SetNonSpaceWrap(true)
        button:Hide()
        button.renderShown = false
        RestoreMarkerTextures(button)
        return button
    end, function(_, button)
        if button.fadeOut then
            button.fadeOut:SetScript("OnFinished", nil)
            button.fadeOut:Stop()
        end
        if button.fadeIn then
            button.fadeIn:Stop()
        end
        local glowFrame = button.glowFrame
        if glowFrame then
            StopFrameFade(glowFrame)
            glowFrame:Hide()
            glowFrame:SetAlpha(1)
            glowFrame:ClearAllPoints()
        end
        button:Hide()
        button:SetAlpha(1)
        button:ClearAllPoints()
        if button.marker then
            button.marker.renderShown = false
        end
        button.marker, button.atlas = nil, nil
        button.sourceTexture, button.texLeft, button.texRight, button.texTop, button.texBottom = nil, nil, nil, nil, nil
        button.colorR, button.colorG, button.colorB = nil, nil, nil
        button.backgroundAtlas, button.underlayAtlas = nil, nil
        button.background:Hide()
        button.underlay:Hide()
        button.markerKey, button.revealAt, button.selected, button.leaving = nil, nil, false, false
        button.renderX, button.renderAlpha, button.renderWaypoint, button.renderGlow, button.renderShown = nil, nil, nil, nil, false
        button.renderLeft, button.renderTop, button.smoothLeft = nil, nil, nil
        HideNearbyLabels(button)
        button.labelScale, button.labelWidth = nil, nil
        button.trackedGlow:Hide()
        RestoreMarkerTextures(button)
    end)
end

-- Возвращает прозрачность всех значков после анимации родительской рамки.
function Compass:RestoreMarkerAlphas()
    local pool = self.markerPool
    if not pool then
        return
    end
    if pool.EnumerateActive then
        for button in pool:EnumerateActive() do
            RestoreMarkerTextures(button)
        end
    end
    if pool.EnumerateInactive then
        for _, button in pool:EnumerateInactive() do
            RestoreMarkerTextures(button)
        end
    end
end

-- Сужает окно поворота, пока набор значков можно только сдвигать.
local function LimitTurn(delta, halfView, minimum, maximum)
    local C = Compass.Constants
    local leaving, entering = halfView - delta, -halfView - delta
    if leaving > C.HALF_TURN then
        leaving = leaving - C.FULL_TURN
    end
    if entering < -C.HALF_TURN then
        entering = entering + C.FULL_TURN
    end
    if leaving >= 0 then
        maximum = math.min(maximum, leaving)
    end
    if leaving <= 0 then
        minimum = math.max(minimum, leaving)
    end
    if entering >= 0 then
        maximum = math.min(maximum, entering)
    end
    if entering <= 0 then
        minimum = math.max(minimum, entering)
    end
    return minimum, maximum
end

-- Сортирует близкие точки слева направо по отклонению от взгляда.
local function NearbyDeltaBefore(a, b)
    if a.nearbyDelta ~= b.nearbyDelta then
        return a.nearbyDelta < b.nearbyDelta
    end
    return a.key < b.key
end

-- Ставит значки в ряд с постоянным шагом, начиная с левой позиции.
local function PlaceNearbyRow(list, firstX, step)
    for index = 1, #list do
        list[index].nearbyX = firstX + (index - 1) * step
    end
end

-- Собирает второстепенную подпись близкой точки.
local function NearbyCaptionText(self, marker)
    local typeLabel = self.L[marker.kind]
    if typeLabel then
        return self.L.DETAIL_F:format(typeLabel, self.L.NEARBY)
    end
    return self.L.NEARBY
end

-- Оформляет название и подпись на значке.
local function StyleNearbyLabels(self, button, scale, width)
    local C = self.Constants
    local offset = Pixel:Multiple(C.SHADOW_OFFSET, scale)
    button.title:SetFont(STANDARD_TEXT_FONT, C.TITLE_FONT_SIZE, "OUTLINE")
    button.caption:SetFont(STANDARD_TEXT_FONT, C.FONT_SIZE, "OUTLINE")
    button.title:SetShadowOffset(offset, -offset)
    button.caption:SetShadowOffset(offset, -offset)
    button.title:SetShadowColor(0, 0, 0, 1)
    button.caption:SetShadowColor(0, 0, 0, 1)
    button.title:SetWidth(width)
    button.caption:SetWidth(width)
    ApplyNearbyLabelColors(button)
    button.labelScale, button.labelWidth = scale, width
end

-- Проверяет, что на полосе те же точки «поблизости», без учёта догасающих и ещё не показанных.
local function SelectionMatchesFoci(selection, foci, extra, skip)
    local expected = extra or 0
    for index = 1, #foci do
        if not (skip and skip[foci[index].key]) then
            expected = expected + 1
        end
    end
    if #selection ~= expected then
        return false
    end
    for index = 1, #foci do
        local marker = foci[index]
        if not (skip and skip[marker.key]) then
            local found
            for inner = 1, #selection do
                if selection[inner].key == marker.key then
                    found = true
                    break
                end
            end
            if not found then
                return false
            end
        end
    end
    return true
end

-- Точка уже в наборе, но в ряд встанет только после скрытия подписей.
local function IsNearbyDeferred(self, marker)
    return marker
        and self.nearbyReflowPhase == "hide"
        and self.nearbyDeferredKeys
        and self.nearbyDeferredKeys[marker.key]
end

-- Возвращает видимую горизонталь значка или последнюю расчётную.
local function NearbyVisualX(self, marker)
    local slot = self.markerSlotsByKey and self.markerSlotsByKey[marker.key]
    if slot and slot.smoothLeft then
        local hitWidth = marker.projectedHitWidth or marker.projectedHitSize or 0
        return slot.smoothLeft + hitWidth / 2
    end
    return marker.nearbyX or marker.projectedX or 0
end

-- Сбрасывает перестроение ряда «поблизости».
function Compass:ClearNearbyReflow()
    self.nearbyReflowPhase = nil
    self.nearbyReflowElapsed = 0
    self.nearbyFrozenWidth = nil
    self.nearbyReflowPending = nil
    wipe(self.nearbyFrozenPositions)
    wipe(self.nearbyDeferredKeys)
end

-- Дописывает новые точки в уже идущее перестроение, не сбрасывая его фазы.
local function RetargetNearbyReflow(self)
    local frozen, deferred = self.nearbyFrozenPositions, self.nearbyDeferredKeys
    local foci = self.arrivalMarkers
    for index = 1, #foci do
        local marker = foci[index]
        if not frozen[marker.key] then
            deferred[marker.key] = true
        end
    end
    local fading = self.nearbyFading
    for index = 1, #fading do
        local marker = fading[index]
        if not frozen[marker.key] then
            frozen[marker.key] = marker.nearbyHoldX or NearbyVisualX(self, marker)
        end
    end
end

-- Запускает скрытие подписей перед перестроением ряда.
function Compass:BeginNearbyReflow()
    if self.nearbyReflowPhase then
        if self.nearbyReflowPhase == "show" then
            self.nearbyReflowPending = true
        else
            RetargetNearbyReflow(self)
        end
        self.nearbyMotionPending = true
        self.selectionDirty = true
        self.renderDirty = true
        return
    end
    self.nearbyReflowPending = nil
    local frozen, deferred = self.nearbyFrozenPositions, self.nearbyDeferredKeys
    wipe(frozen)
    wipe(deferred)
    local foci = self.arrivalMarkers
    for index = 1, #foci do
        local marker = foci[index]
        if marker.nearbyX then
            frozen[marker.key] = NearbyVisualX(self, marker)
        else
            deferred[marker.key] = true
        end
    end
    local fading = self.nearbyFading
    for index = 1, #fading do
        local marker = fading[index]
        frozen[marker.key] = marker.nearbyHoldX or NearbyVisualX(self, marker)
    end
    self.nearbyFrozenWidth = self.nearbyDisplayWidth or self.nearbySlotWidth
    self.nearbyReflowPhase = "hide"
    self.nearbyReflowElapsed = 0
    self.nearbyMotionPending = true
    self.selectionDirty = true
    self.renderDirty = true
end

-- Расставляет близкие точки в ряд, деля между ними большую часть полосы.
function Compass:LayoutNearby(facing)
    local C = self.Constants
    local foci = self:GetNearbyFoci()
    local layout = self.artworkLayout
    local scale = layout and layout.scale or 1
    local ribbon = (layout and layout.contentWidth) or C.WIDTH
    wipe(nearbyOrder)
    for index = 1, #foci do
        local marker = foci[index]
        local delta = 0
        if marker.bearing and facing then
            delta = self:WrapDegrees(facing - marker.bearing)
        end
        marker.nearbyDelta = delta
        nearbyOrder[index] = marker
    end
    table.sort(nearbyOrder, NearbyDeltaBefore)
    local count = #nearbyOrder
    local band = ribbon * C.NEARBY_BAND_FRACTION
    local step = count > 0 and band / count or band
    local gap = Pixel:Multiple(C.NEARBY_SLOT_GAP, scale)
    self.nearbySlotWidth = math.max(0, step - gap)
    local firstX = count > 1 and -((count - 1) * step) / 2 or 0
    PlaceNearbyRow(nearbyOrder, firstX, step)
    local phase = self.nearbyReflowPhase
    -- Пока подписи гаснут, значки остаются на прежних местах и при прежней ширине.
    if phase == "hide" then
        local frozen = self.nearbyFrozenPositions
        for index = 1, count do
            local marker = nearbyOrder[index]
            local held = frozen[marker.key]
            if held then
                marker.nearbyX = held
            end
        end
        if self.nearbyFrozenWidth then
            self.nearbyDisplayWidth = self.nearbyFrozenWidth
        end
    else
        self.nearbyDisplayWidth = self.nearbySlotWidth
    end
end

-- Добавляет на полосу точки, которые ещё гаснут после освобождения слота.
local function AppendNearbyFading(self, selection)
    local fading = self.nearbyFading
    for index = 1, #fading do
        local marker = fading[index]
        local seen
        for inner = 1, #selection do
            if selection[inner].key == marker.key then
                seen = true
                break
            end
        end
        if not seen and not self:ShouldHideNavigationMarker(marker) then
            selection[#selection + 1] = marker
            self.selectionKeys[marker.key] = true
            self.markerSlotsDirty = true
        end
        marker.projectedX = marker.nearbyHoldX or marker.projectedX or 0
        marker.projectedAlpha = 1
        marker.projectedDelta = marker.nearbyDelta or 0
    end
end

-- Оставляет значки, вышедшие из отбора, на последнем месте, пока не доиграет скрытие.
function Compass:HoldLeavingMarkers(selection)
    local leaving = self.rangeLeaving
    if not leaving then
        leaving = {}
        self.rangeLeaving = leaving
    end
    local write = 1
    for index = 1, #leaving do
        local marker = leaving[index]
        if self.selectionKeys[marker.key] then
            marker.rangeHoldX = nil
            self.markerSlotsDirty = true
        else
            local slot = self.markerSlotsByKey and self.markerSlotsByKey[marker.key]
            if slot and (slot.leaving or MarkerFadePlaying(slot) or slot.renderShown) then
                leaving[write] = marker
                write = write + 1
                selection[#selection + 1] = marker
                self.selectionKeys[marker.key] = true
                marker.projectedX = marker.rangeHoldX or marker.projectedX or 0
                self.markerSlotsDirty = true
            else
                marker.rangeHoldX = nil
                self.markerSlotsDirty = true
            end
        end
    end
    for index = #leaving, write, -1 do
        leaving[index] = nil
    end
    local slots = self.markerSlots
    if not slots then
        return
    end
    for index = 1, #slots do
        local slot = slots[index]
        local marker = slot.marker
        if
            marker
            and not self.selectionKeys[marker.key]
            and not marker.nearbyHoldX
            and not self:IsNearbyFocus(marker)
            and (slot.renderShown or slot.leaving or MarkerFadePlaying(slot))
        then
            local already
            for inner = 1, #leaving do
                if leaving[inner].key == marker.key then
                    already = true
                    break
                end
            end
            if not already then
                marker.rangeHoldX = marker.projectedX or marker.rangeHoldX or 0
                leaving[#leaving + 1] = marker
                selection[#selection + 1] = marker
                self.selectionKeys[marker.key] = true
                marker.projectedX = marker.rangeHoldX
                self.markerSlotsDirty = true
            end
        end
    end
end

-- Сдвигает уже отобранные значки при повороте.
local function ProjectSelection(self, facing, width)
    for _, marker in ipairs(self.selectedMarkers) do
        if not marker.bearing then
            if not self:IsNearbyFocus(marker) then
                return false
            end
        else
            local x, alpha, delta = self:Project(marker.bearing, facing, self.viewAngle, width, Compass.Constants.EDGE_CLIP_FRACTION)
            if x and alpha > 0 then
                marker.projectedX, marker.projectedAlpha, marker.projectedDelta = x, alpha, delta
            elseif not self:IsNearbyFocus(marker) then
                return false
            end
        end
    end
    return true
end

-- Отбирает до двадцати четырёх видимых значков.
function Compass:SelectMarkers(facing, width, live)
    local C = self.Constants
    local selection = self.selectedMarkers
    local foci = self:GetNearbyFoci()
    local blend = self.arrivalBlend or 0
    local arrived = #self.arrivalMarkers > 0
    -- Пока близкие точки гаснут на месте, веер значков ещё не показываем.
    local lock = #foci > 0 and ((arrived and blend >= 1) or (not arrived and blend > 0))
    if lock then
        local extra = #self.nearbyFading
        local skip = self.nearbyReflowPhase == "hide" and self.nearbyDeferredKeys or nil
        if not (
            live
            and not self.selectionDirty
            and #self.rangeLeaving == 0
            and SelectionMatchesFoci(selection, foci, extra, skip)
        ) then
            wipe(selection)
            self.markerSlotsDirty = true
            wipe(self.selectionKeys)
            for index = 1, #foci do
                local focus = foci[index]
                if not self:ShouldHideNavigationMarker(focus) and not IsNearbyDeferred(self, focus) then
                    selection[#selection + 1] = focus
                    self.selectionKeys[focus.key] = true
                end
            end
        end
        self:LayoutNearby(facing)
        for index = 1, #selection do
            local marker = selection[index]
            marker.projectedX = marker.nearbyX or 0
            marker.projectedAlpha = 1
            marker.projectedDelta = marker.nearbyDelta or 0
        end
        AppendNearbyFading(self, selection)
        self.selectionFacing, self.selectionTurnMin, self.selectionTurnMax = facing, -C.HALF_TURN, C.HALF_TURN
        self.selectionDirty = false
        return selection
    end
    if not facing then
        wipe(selection)
        wipe(self.selectionKeys)
        self.markerSlotsDirty = true
        self.selectionDirty = true
        return selection
    end
    if live and not self.selectionDirty and self.selectionFacing then
        local turn = self:WrapDegrees(facing - self.selectionFacing)
        if
            (turn == 0 or (turn > self.selectionTurnMin and turn < self.selectionTurnMax))
            and ProjectSelection(self, facing, width)
        then
            return selection
        end
    end
    wipe(selection)
    self.markerSlotsDirty = true
    local halfView, turnMin, turnMax = self.viewAngle / 2 * (1 - C.EDGE_CLIP_FRACTION), -C.HALF_TURN, C.HALF_TURN
    for _, marker in ipairs(self.bearings) do
        if marker.bearing and not self:ShouldHideNavigationMarker(marker) then
            local x, alpha, delta = self:Project(marker.bearing, facing, self.viewAngle, width, C.EDGE_CLIP_FRACTION)
            turnMin, turnMax = LimitTurn(delta, halfView, turnMin, turnMax)
            if x and alpha > 0 then
                if live and marker.bearingRevision ~= self.bearingRevision then
                    self:RefreshMarkerBearing(marker)
                    x, alpha = nil, nil
                    if marker.bearing then
                        x, alpha, delta = self:Project(marker.bearing, facing, self.viewAngle, width, C.EDGE_CLIP_FRACTION)
                        turnMin, turnMax = LimitTurn(delta, halfView, turnMin, turnMax)
                    end
                end
                if x and alpha > 0 then
                    selection[#selection + 1] = marker
                    marker.projectedX, marker.projectedAlpha, marker.projectedDelta = x, alpha, delta
                    if #selection == C.MAX_MARKERS then
                        break
                    end
                end
            end
        end
    end
    wipe(self.selectionKeys)
    for _, marker in ipairs(selection) do
        self.selectionKeys[marker.key] = true
    end
    self.selectionFacing, self.selectionTurnMin, self.selectionTurnMax = facing, turnMin, turnMax
    self.selectionDirty = false
    return selection
end

-- Ставит обычный вид или режим «поблизости» сразу, без перехода.
function Compass:SnapArrivalMode()
    local target = #self.arrivalMarkers > 0 and 1 or 0
    self.arrivalBlend = target
    self.arrivalEase = target
    self.arrivalBlendPending = false
    self.arrivalFanReveal = false
    self:ClearNearbyReflow()
    -- После возврата полосы не сдвигаем значки с мест, застывших до скрытия.
    local slots = self.markerSlots
    if slots then
        for index = 1, #slots do
            slots[index].smoothLeft = nil
        end
    end
    if target == 0 then
        local fading = self.nearbyFading
        for index = 1, #fading do
            fading[index].nearbyHoldX = nil
        end
        wipe(self.arrivalLeaving)
        wipe(self.nearbyFading)
        self.nearbyLiveCount = 0
        wipe(self.nearbyLiveKeys)
    end
end

-- Плавно переводит полосу в режим прибытия и обратно.
function Compass:UpdateArrivalBlend(elapsed)
    local C = self.Constants
    local foci = self.arrivalMarkers
    if #foci > 0 then
        local leaving = self.arrivalLeaving
        wipe(leaving)
        for index = 1, #foci do
            leaving[index] = foci[index]
        end
        self.arrivalFanReveal = false
    end
    local target = #foci > 0 and 1 or 0
    local blend = self.arrivalBlend or 0
    -- При появлении полосы не проигрываем переход с обычного вида на «поблизости».
    if self.snapArrivalOnShow then
        if blend ~= target then
            self:SnapArrivalMode()
            self.renderDirty = true
        end
        blend = target
    elseif blend ~= target then
        local duration = C.ARRIVAL_BLEND_DURATION
        local step = duration > 0 and math.max(0, elapsed or 0) / duration or 1
        local fadingOut = target == 0 and blend > 0
        if blend < target then
            blend = math.min(target, blend + step)
        else
            blend = math.max(target, blend - step)
        end
        if fadingOut and blend <= 0 then
            self.arrivalFanReveal = true
        end
        self.arrivalBlend = blend
        self.renderDirty = true
    end
    self.arrivalBlendPending = blend ~= target
    self.arrivalEase = blend * blend * (3 - 2 * blend)
    if #foci == 0 and blend <= 0 then
        local fading = self.nearbyFading
        for index = 1, #fading do
            fading[index].nearbyHoldX = nil
        end
        wipe(self.arrivalLeaving)
        wipe(self.nearbyFading)
        self.arrivalEase = 0
        self:ClearNearbyReflow()
        self.nearbyLiveCount = 0
        wipe(self.nearbyLiveKeys)
    end
end

-- Плавно меняет ряд «поблизости» и следит за догасающими слотами.
function Compass:UpdateNearbyMotion(elapsed)
    local C = self.Constants
    elapsed = math.max(0, elapsed or 0)
    local pending = false
    local fading = self.nearbyFading
    local write = 1
    for index = 1, #fading do
        local marker = fading[index]
        if self.arrivalKeys[marker.key] then
            marker.nearbyHoldX = nil
        else
            local slot = self.markerSlotsByKey and self.markerSlotsByKey[marker.key]
            if slot and (slot.leaving or MarkerFadePlaying(slot) or slot.renderShown) then
                if slot.renderShown and not slot.leaving then
                    FadeMarkerOut(slot)
                end
                fading[write] = marker
                write = write + 1
                pending = true
            else
                marker.nearbyHoldX = nil
                self.selectionDirty = true
            end
        end
    end
    for index = #fading, write, -1 do
        fading[index] = nil
    end
    local phase = self.nearbyReflowPhase
    if phase then
        self.nearbyReflowElapsed = (self.nearbyReflowElapsed or 0) + elapsed
        if phase == "hide" then
            if self.nearbyReflowElapsed >= C.NEARBY_LABEL_HIDE_DURATION then
                wipe(self.nearbyFrozenPositions)
                wipe(self.nearbyDeferredKeys)
                self.nearbyFrozenWidth = nil
                self.nearbyReflowPhase = "move"
                self.nearbyReflowElapsed = 0
                self.nearbyDisplayWidth = self.nearbySlotWidth
                self.selectionDirty = true
            end
        elseif phase == "move" then
            if self.nearbyReflowElapsed >= C.NEARBY_RELAYOUT_DURATION then
                self.nearbyReflowPhase = "show"
                self.nearbyReflowElapsed = 0
            end
        elseif phase == "show" then
            if self.nearbyReflowElapsed >= C.LABEL_FADE_DURATION then
                local pendingRestart = self.nearbyReflowPending
                self:ClearNearbyReflow()
                if pendingRestart then
                    self:BeginNearbyReflow()
                end
            end
        end
        if self.nearbyReflowPhase then
            pending = true
        end
    end
    self.nearbyMotionPending = pending
end

-- Сдвигает близкие точки к указателю по сторонам и гасит остальные значки.
function Compass:ApplyArrivalBlend(selection, facing)
    local ease = self.arrivalEase or 0
    local foci = self:GetNearbyFoci()
    if ease <= 0 or #foci == 0 then
        return selection
    end
    self:LayoutNearby(facing)
    if #self.arrivalMarkers == 0 then
        -- Исчезновение: значки остаются на своих сторонах и гаснут той же анимацией рамки.
        for index = 1, #foci do
            local marker = foci[index]
            marker.projectedX = marker.nearbyX or 0
            marker.projectedAlpha = 1
            marker.projectedDelta = marker.nearbyDelta or 0
            local slot = self.markerSlotsByKey and self.markerSlotsByKey[marker.key]
            if slot then
                slot.revealAt = nil
                if slot.renderShown and not slot.leaving then
                    FadeMarkerOut(slot)
                end
            end
        end
        return selection
    end
    for _, marker in ipairs(selection) do
        if marker.nearbyHoldX and not self.arrivalKeys[marker.key] then
            marker.projectedX = marker.nearbyHoldX or marker.projectedX or 0
            marker.projectedAlpha = 1
        elseif self.arrivalKeys[marker.key] then
            marker.projectedX = marker.nearbyX or 0
            marker.projectedAlpha = 1
        else
            marker.projectedAlpha = (marker.projectedAlpha or 1) * (1 - ease)
        end
    end
    for index = 1, #foci do
        local focus = foci[index]
        local seen
        for _, marker in ipairs(selection) do
            if marker.key == focus.key then
                seen = true
                break
            end
        end
        if not seen and not self:ShouldHideNavigationMarker(focus) and not IsNearbyDeferred(self, focus) then
            focus.projectedX = focus.nearbyX or 0
            focus.projectedAlpha = 1
            focus.projectedDelta = focus.nearbyDelta or 0
            selection[#selection + 1] = focus
            self.selectionKeys[focus.key] = true
            self.markerSlotsDirty = true
        end
    end
    AppendNearbyFading(self, selection)
    return selection
end

-- Сортировка слева направо для групп пересечения.
local function LeftBefore(a, b)
    if a.projectedLeftPx ~= b.projectedLeftPx then
        return a.projectedLeftPx < b.projectedLeftPx
    end
    return a.key < b.key
end

-- Сортировка по близости для глубины.
local function NearBefore(a, b)
    if a.distanceSquared ~= b.distanceSquared then
        return a.distanceSquared < b.distanceSquared
    end
    return a.key < b.key
end

-- Обновляет порядок близости, если набор изменился.
local function RefreshNearOrder(order, members, selection)
    local membershipChanged = #order ~= #selection
    if not membershipChanged then
        for _, marker in ipairs(order) do
            if not members[marker] then
                membershipChanged = true
                break
            end
        end
    end
    if membershipChanged then
        wipe(order)
        for index, marker in ipairs(selection) do
            order[index] = marker
        end
    end
    for index = 2, #order do
        if NearBefore(order[index], order[index - 1]) then
            table.sort(order, NearBefore)
            return
        end
    end
end

-- Возвращает символ, круг и размеры с учётом выбранной точки.
local function MarkerDisplayArt(marker)
    local C = Compass.Constants
    local atlas = marker.atlas
    local iconWidth, iconHeight = marker.iconWidth, marker.iconHeight
    local background = marker.backgroundAtlas
    local backgroundWidth, backgroundHeight = marker.backgroundWidth, marker.backgroundHeight
    if marker.questProgress then
        if marker.navigation then
            atlas = C.QUEST_PROGRESS_FOCUSED_ATLAS
            if marker.iconWidthFocused and marker.iconHeightFocused then
                iconWidth, iconHeight = marker.iconWidthFocused, marker.iconHeightFocused
            end
        else
            atlas = C.QUEST_PROGRESS_ATLAS
        end
    end
    if marker.navigation and marker.backgroundAtlasFocused then
        background = marker.backgroundAtlasFocused
        backgroundWidth, backgroundHeight = marker.backgroundWidthFocused, marker.backgroundHeightFocused
    end
    return atlas, background, iconWidth, iconHeight, backgroundWidth, backgroundHeight
end

-- Считает размеры и группы пересекающихся значков.
function Compass:LayoutMarkerGroups(selection)
    local C = self.Constants
    local layout = self.artworkLayout
    local scale, centerX = layout.scale, layout.centerX
    local outline = Pixel:Multiple(C.MARKER_OUTLINE * 2, scale)
    local order, groups = self.markerGroupOrder, self.markerGroups
    local leftOrder, members = self.markerLeftOrder, self.markerGroupMembers
    wipe(leftOrder)
    wipe(members)
    for _, group in ipairs(groups) do
        wipe(group.markers)
    end
    for index, marker in ipairs(selection) do
        local _, _, iconW, iconH, backgroundW, backgroundH = MarkerDisplayArt(marker)
        local iconWidth = Pixel:Snap(iconW or C.ICON_SIZE, scale)
        local iconHeight = Pixel:Snap(iconH or C.ICON_SIZE, scale)
        local backgroundWidth = backgroundW and Pixel:Snap(backgroundW, scale)
        local backgroundHeight = backgroundH and Pixel:Snap(backgroundH, scale)
        local underlayWidth = marker.underlayWidth and Pixel:Snap(marker.underlayWidth, scale)
        local underlayHeight = marker.underlayHeight and Pixel:Snap(marker.underlayHeight, scale)
        local outerWidth = math.max(iconWidth, backgroundWidth or 0, underlayWidth or 0)
        local outerHeight = math.max(iconHeight, backgroundHeight or 0, underlayHeight or 0)
        local hitWidth = outerWidth + outline
        local hitHeight = outerHeight + outline
        marker.projectedIconWidth, marker.projectedIconHeight = iconWidth, iconHeight
        marker.projectedOuterWidth, marker.projectedOuterHeight = outerWidth, outerHeight
        marker.projectedBackgroundWidth, marker.projectedBackgroundHeight = backgroundWidth, backgroundHeight
        marker.projectedUnderlayWidth, marker.projectedUnderlayHeight = underlayWidth, underlayHeight
        marker.projectedHitWidth, marker.projectedHitHeight = hitWidth, hitHeight
        marker.projectedIconSize, marker.projectedHitSize = outerWidth, hitWidth
        local left = centerX + marker.projectedX - hitWidth / 2
        marker.projectedLeft = left
        marker.projectedLeftPx = Pixel:ToCount(left, scale)
        marker.projectedRightPx = marker.projectedLeftPx + Pixel:ToCount(hitWidth, scale)
        leftOrder[index] = marker
        members[marker] = true
    end
    table.sort(leftOrder, LeftBefore)
    local group, right = 0, nil
    for _, marker in ipairs(leftOrder) do
        if not right or marker.projectedLeftPx >= right then
            group = group + 1
            right = marker.projectedRightPx
            groups[group] = groups[group] or { markers = {} }
        else
            right = math.max(right, marker.projectedRightPx)
        end
        marker.overlapGroup = groups[group]
    end
    RefreshNearOrder(order, members, selection)
    for index, marker in ipairs(order) do
        local record = marker.overlapGroup
        record.markers[#record.markers + 1] = marker
        marker.depthLevel = C.MARKER_BASE_LEVEL + #order - index
    end
end

-- Назначает рамки отобранным точкам.
function Compass:AssignMarkerSlots(selection, live)
    local C = self.Constants
    if not self.markerSlotsDirty and self.markerSlotsLive == live then
        return
    end
    self.markerSlotsDirty, self.markerSlotsLive = false, live
    local slots, nextSlots, byKey = self.markerSlots, self.nextMarkerSlots, self.markerSlotsByKey
    local generation = self.markerGeneration + 1
    self.markerGeneration = generation
    wipe(nextSlots)
    for index, marker in ipairs(selection) do
        local slot = byKey[marker.key]
        if slot then
            slot.markerGeneration = generation
            nextSlots[index] = slot
        end
    end
    local freeIndex = 1
    for index, marker in ipairs(selection) do
        local slot = nextSlots[index]
        local assignedNew = false
        if not slot then
            while
                slots[freeIndex]
                and (slots[freeIndex].markerGeneration == generation or slots[freeIndex].leaving)
            do
                freeIndex = freeIndex + 1
            end
            slot = slots[freeIndex] or self.markerPool:Acquire()
            freeIndex = freeIndex + 1
            if slot.markerKey then
                byKey[slot.markerKey] = nil
            end
            slot.markerKey, slot.markerGeneration = marker.key, generation
            slot.smoothLeft = nil
            slot.leaving = false
            HideNearbyLabels(slot)
            byKey[marker.key], nextSlots[index] = slot, slot
            assignedNew = true
        end
        local shown = slot.renderShown or MarkerFadePlaying(slot)
        local toAlpha = MarkerTargetAlpha(marker)
        if MarkerHoldsFade(self, marker) then
            slot.revealAt = nil
            if shown and not slot.leaving then
                FadeMarkerOut(slot)
            end
        else
            if slot.leaving then
                FadeMarkerIn(slot, toAlpha)
                shown = true
            end
            if self.arrivalFanReveal then
                slot.revealAt = nil
                slot.smoothLeft = nil
                if not shown then
                    FadeMarkerIn(slot, toAlpha)
                end
            elseif self:IsNearbyFocus(marker) then
                slot.revealAt = nil
                if not shown then
                    FadeMarkerIn(slot, toAlpha)
                end
            elseif (self.arrivalBlend or 0) > 0 then
                slot.revealAt = nil
            elseif self.rangeChanged and not shown then
                slot.revealAt = nil
                FadeMarkerIn(slot, toAlpha)
            elseif self.markerFadeIn and not shown then
                -- Пока сама полоса проявляется, значки идут с ней; иначе проявляем отдельно.
                slot.revealAt = nil
                if not (self.frame.fadeIn and self.frame.fadeIn:IsPlaying()) then
                    FadeMarkerIn(slot, toAlpha)
                end
            elseif not live or marker.navigation or marker.priority <= C.TRACKED_QUEST_PRIORITY then
                slot.revealAt = nil
            elseif assignedNew or not slot.selected or not slot.marker or slot.marker.key ~= marker.key then
                slot.revealAt = self.markerClock + C.MARKER_REVEAL_DELAY
            end
        end
        slot.selected = true
    end
    self.rangeChanged, self.arrivalFanReveal = false, false
    if self.markerFadeIn and #selection > 0 then
        self.markerFadeIn = false
    end
    for _, slot in ipairs(slots) do
        if slot.markerGeneration ~= generation then
            slot.selected, slot.revealAt = false, nil
            if slot.renderShown and not slot.leaving then
                FadeMarkerOut(slot)
            elseif not slot.leaving then
                if slot.marker then
                    slot.marker.renderShown = false
                end
                HideNearbyLabels(slot)
                slot.smoothLeft = nil
            end
            nextSlots[#nextSlots + 1] = slot
        end
    end
    self.markerSlots, self.nextMarkerSlots = nextSlots, slots
end

-- Проверяет, сменилась ли картинка значка.
local function MarkerArtChanged(button, marker, atlas, backgroundAtlas)
    return button.atlas ~= atlas
        or button.sourceTexture ~= marker.texture
        or button.texLeft ~= marker.texLeft
        or button.texRight ~= marker.texRight
        or button.texTop ~= marker.texTop
        or button.texBottom ~= marker.texBottom
        or button.colorR ~= marker.colorR
        or button.colorG ~= marker.colorG
        or button.colorB ~= marker.colorB
        or button.backgroundAtlas ~= backgroundAtlas
        or button.underlayAtlas ~= marker.underlayAtlas
end

-- Назначает атлас или текстуру значку и круглую подложку, если она есть.
local function BindMarkerArt(button, marker, atlas, backgroundAtlas)
    local C = Compass.Constants
    atlas = atlas or marker.atlas
    backgroundAtlas = backgroundAtlas or marker.backgroundAtlas
    local shadowAtlas = backgroundAtlas or atlas
    if marker.texture and not backgroundAtlas then
        button.icon:SetTexture(marker.texture)
        button.shadow:SetTexture(marker.texture)
        local left, right = marker.texLeft or FULL_TEX_COORDS.left, marker.texRight or FULL_TEX_COORDS.right
        local top, bottom = marker.texTop or FULL_TEX_COORDS.top, marker.texBottom or FULL_TEX_COORDS.bottom
        button.icon:SetTexCoord(left, right, top, bottom)
        button.shadow:SetTexCoord(left, right, top, bottom)
        button.icon:SetVertexColor(
            marker.colorR or ICON_COLOR.r,
            marker.colorG or ICON_COLOR.g,
            marker.colorB or ICON_COLOR.b
        )
        button.background:Hide()
    else
        button.icon:SetTexCoord(
            FULL_TEX_COORDS.left,
            FULL_TEX_COORDS.right,
            FULL_TEX_COORDS.top,
            FULL_TEX_COORDS.bottom
        )
        button.shadow:SetTexCoord(
            FULL_TEX_COORDS.left,
            FULL_TEX_COORDS.right,
            FULL_TEX_COORDS.top,
            FULL_TEX_COORDS.bottom
        )
        button.icon:SetAtlas(atlas)
        button.shadow:SetAtlas(shadowAtlas)
        button.icon:SetVertexColor(ICON_COLOR.r, ICON_COLOR.g, ICON_COLOR.b)
        if backgroundAtlas then
            button.background:SetTexCoord(
                FULL_TEX_COORDS.left,
                FULL_TEX_COORDS.right,
                FULL_TEX_COORDS.top,
                FULL_TEX_COORDS.bottom
            )
            button.background:SetAtlas(backgroundAtlas)
            button.background:Show()
        else
            button.background:Hide()
        end
    end
    if marker.underlayAtlas then
        button.underlay:SetTexCoord(
            FULL_TEX_COORDS.left,
            FULL_TEX_COORDS.right,
            FULL_TEX_COORDS.top,
            FULL_TEX_COORDS.bottom
        )
        button.underlay:SetAtlas(marker.underlayAtlas)
        button.underlay:Show()
    else
        button.underlay:Hide()
    end
    button.shadow:SetVertexColor(0, 0, 0, C.MARKER_OUTLINE_ALPHA)
    button.atlas, button.sourceTexture = atlas, marker.texture
    button.texLeft, button.texRight, button.texTop, button.texBottom =
        marker.texLeft, marker.texRight, marker.texTop, marker.texBottom
    button.colorR, button.colorG, button.colorB = marker.colorR, marker.colorG, marker.colorB
    button.backgroundAtlas, button.underlayAtlas = backgroundAtlas, marker.underlayAtlas
    button.layoutAtlas = nil
end

-- Привязывает рамку к точке.
function Compass:BindMarker(button, marker)
    if button.marker and button.marker ~= marker then
        button.marker.renderShown = false
    end
    if button.marker ~= marker then
        button.smoothLeft = nil
    end
    button.marker = marker
end

-- Сдвигает видимую горизонталь к расчётной без скачков.
local function SmoothMarkerLeft(self, button, targetLeft, scale, gentle)
    local C = self.Constants
    local current = button.smoothLeft
    if not current or (not gentle and math.abs(targetLeft - current) >= C.MARKER_SMOOTH_SNAP) then
        button.smoothLeft = targetLeft
        return targetLeft
    end
    local elapsed = self.markerSmoothElapsed or 0
    local tau
    if gentle then
        if self.nearbyReflowPhase == "move" then
            tau = C.NEARBY_RELAYOUT_DURATION * 0.5
        else
            tau = C.NEARBY_MOTION_DURATION * 0.6
        end
    else
        tau = C.MARKER_SMOOTH_TIME
    end
    local factor = 1
    if tau > 0 and elapsed > 0 then
        factor = 1 - math.exp(-elapsed / tau)
    end
    local left = current + (targetLeft - current) * factor
    local settle = Pixel:Multiple(1, scale) * 0.25
    if math.abs(targetLeft - left) > settle then
        self.markerSmoothPending = true
        button.smoothLeft = left
        return left
    end
    button.smoothLeft = targetLeft
    return targetLeft
end

-- Рисует один значок по центру высоты полосы.
function Compass:RenderMarker(button, marker, x, alpha, markerY, outline, scale)
    local C = self.Constants
    local blending = (self.arrivalBlend or 0) > 0
    local arrived = blending and self:IsNearbyFocus(marker)
    local waypoint = marker.navigation == true
    local atlas, backgroundAtlas = MarkerDisplayArt(marker)
    if MarkerArtChanged(button, marker, atlas, backgroundAtlas) then
        BindMarkerArt(button, marker, atlas, backgroundAtlas)
    end
    if button.marker ~= marker then
        self:BindMarker(button, marker)
    end
    if arrived then
        button.revealAt = nil
    end
    if marker.overlapGroup and #marker.overlapGroup.markers > 1 then
        button.revealAt = nil
    end
    alpha = (alpha or 1) * (marker.sourceAlpha or 1)
    if button.revealAt and self.markerClock < button.revealAt then
        self.markerRevealPending = true
        HideNearbyLabels(button)
        return false
    end
    if button.revealAt then
        button.revealAt = nil
        if not button.renderShown and not MarkerFadePlaying(button) then
            FadeMarkerIn(button, alpha)
        end
    end
    local baseLevel = self.frame:GetFrameLevel()
    local level = baseLevel + marker.depthLevel
    if button:GetFrameLevel() ~= level then
        button:SetFrameLevel(level)
    end
    local iconWidth = marker.projectedIconWidth or marker.projectedIconSize
    local iconHeight = marker.projectedIconHeight or marker.projectedIconSize
    local outerWidth = marker.projectedOuterWidth or iconWidth
    local outerHeight = marker.projectedOuterHeight or iconHeight
    local hitWidth = marker.projectedHitWidth or marker.projectedHitSize
    local hitHeight = marker.projectedHitHeight or marker.projectedHitSize
    local backgroundWidth = marker.projectedBackgroundWidth
    local backgroundHeight = marker.projectedBackgroundHeight
    local underlayWidth = marker.projectedUnderlayWidth
    local underlayHeight = marker.projectedUnderlayHeight
    if
        button.layoutWidth ~= iconWidth
        or button.layoutHeight ~= iconHeight
        or button.layoutOuterWidth ~= outerWidth
        or button.layoutOuterHeight ~= outerHeight
        or button.layoutOutline ~= outline
        or button.layoutHitWidth ~= hitWidth
        or button.layoutHitHeight ~= hitHeight
        or button.layoutBackgroundWidth ~= backgroundWidth
        or button.layoutBackgroundHeight ~= backgroundHeight
        or button.layoutUnderlayWidth ~= underlayWidth
        or button.layoutUnderlayHeight ~= underlayHeight
        or button.layoutScale ~= scale
        or button.layoutAtlas ~= atlas
        or button.layoutBackground ~= backgroundAtlas
        or button.layoutUnderlay ~= marker.underlayAtlas
    then
        button:SetSize(hitWidth, hitHeight)
        button.icon:SetSize(iconWidth, iconHeight)
        local insetX = Pixel:Snap((hitWidth - iconWidth) / 2, scale)
        local insetY = Pixel:Snap((hitHeight - iconHeight) / 2, scale)
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", insetX, -insetY)
        local shadowWidth = (backgroundWidth or iconWidth) + outline
        local shadowHeight = (backgroundHeight or iconHeight) + outline
        button.shadow:SetSize(shadowWidth, shadowHeight)
        local shadowInsetX = Pixel:Snap((hitWidth - shadowWidth) / 2, scale)
        local shadowInsetY = Pixel:Snap((hitHeight - shadowHeight) / 2, scale)
        button.shadow:SetPoint("TOPLEFT", button, "TOPLEFT", shadowInsetX, -shadowInsetY)
        if backgroundWidth and backgroundHeight then
            button.background:SetSize(backgroundWidth, backgroundHeight)
            local backgroundInsetX = Pixel:Snap((hitWidth - backgroundWidth) / 2, scale)
            local backgroundInsetY = Pixel:Snap((hitHeight - backgroundHeight) / 2, scale)
            button.background:SetPoint("TOPLEFT", button, "TOPLEFT", backgroundInsetX, -backgroundInsetY)
        end
        if underlayWidth and underlayHeight then
            button.underlay:SetSize(underlayWidth, underlayHeight)
            local underlayInsetX = Pixel:Snap((hitWidth - underlayWidth) / 2, scale)
            local underlayInsetY = Pixel:Snap((hitHeight - underlayHeight) / 2, scale)
            button.underlay:SetPoint("TOPLEFT", button, "TOPLEFT", underlayInsetX, -underlayInsetY)
        end
        button.trackedGlow:SetSize(
            Pixel:Snap(C.ICON_SIZE * C.TRACKED_GLOW_WIDTH_SCALE, scale),
            Pixel:Snap(C.ICON_SIZE * C.TRACKED_GLOW_HEIGHT_SCALE, scale)
        )
        button.layoutWidth, button.layoutHeight = iconWidth, iconHeight
        button.layoutOuterWidth, button.layoutOuterHeight = outerWidth, outerHeight
        button.layoutOutline = outline
        button.layoutHitWidth, button.layoutHitHeight = hitWidth, hitHeight
        button.layoutBackgroundWidth, button.layoutBackgroundHeight = backgroundWidth, backgroundHeight
        button.layoutUnderlayWidth, button.layoutUnderlayHeight = underlayWidth, underlayHeight
        button.layoutScale, button.layoutAtlas = scale, atlas
        button.layoutBackground, button.layoutUnderlay = backgroundAtlas, marker.underlayAtlas
    end
    local centerX, centerY = self.artworkLayout.centerX, self.artworkLayout.centerY
    local left = SmoothMarkerLeft(self, button, marker.projectedLeft - centerX, scale, arrived)
    local top = Pixel:Snap(centerY + markerY + hitHeight / 2, scale) - centerY
    if button.renderLeft ~= left or button.renderTop ~= top then
        button:SetPoint("TOPLEFT", self.frame, "CENTER", left, top)
        button.renderLeft, button.renderTop = left, top
    end
    button.renderX, button.renderY = left + hitWidth / 2, top - hitHeight / 2
    x = button.renderX
    local glow = waypoint or arrived
    if button.renderWaypoint ~= waypoint or button.renderGlow ~= glow then
        button.trackedGlow:SetShown(glow)
        button.renderWaypoint, button.renderGlow = waypoint, glow
    end
    if glow then
        local glowY = self.lineY - Pixel:Multiple(C.TRACKED_GLOW_DROP, scale)
        if button.glowX ~= x or button.glowY ~= glowY then
            button.trackedGlow:SetPoint("BOTTOM", self.frame, "CENTER", x, glowY)
            button.glowX, button.glowY = x, glowY
        end
    end
    local fading = MarkerFadePlaying(button) or button.leaving
    if fading then
        self.markerRevealPending = true
        button.renderAlpha = MarkerFrameAlpha(button)
    elseif not self:IsFadeInPlaying() and button.renderAlpha ~= alpha then
        SetMarkerFrameAlpha(button, alpha)
        button.renderAlpha = alpha
    else
        button.renderAlpha = alpha
    end
    if arrived then
        local slotWidth = self.nearbyDisplayWidth or self.nearbySlotWidth
        if not slotWidth or slotWidth <= 0 then
            local ribbon = (self.artworkLayout and self.artworkLayout.contentWidth) or C.WIDTH
            slotWidth = math.max(0, ribbon * C.NEARBY_BAND_FRACTION - Pixel:Multiple(C.NEARBY_SLOT_GAP, scale))
        end
        if button.labelScale ~= scale or button.labelWidth ~= slotWidth then
            StyleNearbyLabels(self, button, scale, slotWidth)
        end
        if button.labelName ~= marker.name then
            button.title:SetText(marker.name or "")
            button.labelName = marker.name
        end
        local caption = NearbyCaptionText(self, marker)
        if button.labelCaption ~= caption then
            button.caption:SetText(caption)
            button.labelCaption = caption
        end
        local layout = self.artworkLayout
        local detailY = layout.headingY - Pixel:Snap(self.headingHeight, scale) - Pixel:Multiple(C.LABEL_GAP, scale)
        if button.labelX ~= x or button.labelY ~= detailY then
            button.title:ClearAllPoints()
            button.title:SetPoint("TOP", self.frame, "CENTER", x, detailY)
            button.caption:ClearAllPoints()
            button.caption:SetPoint("TOP", button.title, "BOTTOM", 0, -Pixel:Multiple(C.LABEL_CAPTION_GAP, scale))
            button.labelX, button.labelY = x, detailY
        end
        local leaving = button.leaving or marker.nearbyHoldX ~= nil or marker.rangeHoldX ~= nil or #self.arrivalMarkers == 0
        local reflow = self.nearbyReflowPhase
        local hideForReflow = reflow == "hide" or reflow == "move"
        local wantLabels = not leaving and not hideForReflow and self:ShouldShowMarkerLabel(button.labelShown, button.renderAlpha or alpha)
        -- Пока проявляется полоса, подписи остаются на экране, прозрачность — в цвете текста.
        if self:IsFadeInPlaying() then
            if wantLabels then
                StopLabelFade(button)
                if button.labelFrame then
                    button.labelFrame:SetAlpha(1)
                    button.labelFrame:Show()
                end
                ApplyNearbyLabelColors(button, MarkerFrameAlpha(self.frame))
                button.labelShown = true
            else
                SetNearbyLabelsShown(button, false)
            end
        else
            SetNearbyLabelsShown(button, wantLabels)
        end
    else
        SetNearbyLabelsShown(button, false)
    end
    if not button.renderShown and not button.leaving then
        if MarkerHoldsFade(self, marker) then
            return false
        elseif self:IsFadeInPlaying() then
            button:Show()
            SetMarkerFrameAlpha(button, alpha)
            if button.glowFrame then
                button.glowFrame:Show()
            end
            button.renderShown = true
            button.renderAlpha = alpha
        else
            FadeMarkerIn(button, alpha)
        end
    end
    return button.renderShown or MarkerFadePlaying(button)
end

-- Ставит путевую точку игры и включает её отслеживание.
function Compass:SetWaypoint(mapID, x, y, title, description, sourceKey)
    local L = self.L
    mapID, x, y = Compass.Number(mapID), Compass.Number(x), Compass.Number(y)
    if not mapID or mapID <= 0 or mapID % 1 ~= 0 or not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then
        return false, L.WAYPOINT_INVALID
    end
    local mapInfo, canSet = C_Map.GetMapInfo(mapID), C_Map.CanSetUserWaypointOnMap(mapID)
    if Compass.IsSecret(mapInfo) or not mapInfo or Compass.IsSecret(canSet) or canSet ~= true then
        return false, L.WAYPOINT_UNAVAILABLE
    end
    local success = C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
    if Compass.IsSecret(success) or success ~= true then
        return false, L.WAYPOINT_UNAVAILABLE
    end
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    self.dismissedNavigationKey = nil
    self.waypointLabel = {
        mapID = mapID,
        x = x,
        y = y,
        title = title ~= "" and title or nil,
        description = description ~= "" and description or nil,
        sourceKey = sourceKey ~= "" and sourceKey ~= "waypoint" and sourceKey or nil,
    }
    self.waypointDirty = true
    return true
end

-- Возвращает подпись путевой точки, если координаты совпали.
function Compass:GetWaypointTitle(mapID, x, y)
    local C = self.Constants
    local label = self.waypointLabel
    if
        label
        and label.mapID == mapID
        and math.abs(label.x - x) < C.WAYPOINT_MATCH_EPSILON
        and math.abs(label.y - y) < C.WAYPOINT_MATCH_EPSILON
    then
        return label.title or self.L.WAYPOINT, label.description, label.sourceKey
    end
    self.waypointLabel = nil
    return self.L.WAYPOINT
end
