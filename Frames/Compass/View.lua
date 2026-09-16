-- View.lua
-- Линия, указатель, стороны света и цикл отрисовки полосы.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Pixel = Compass.Pixel

-- Оформляет текстовую подпись полосы.
local function StyleText(region, fontSize, color)
    local C = Compass.Constants
    region:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    local offset = Pixel:Multiple(C.SHADOW_OFFSET, region:GetEffectiveScale())
    region:SetShadowOffset(offset, -offset)
    region:SetShadowColor(0, 0, 0, 1)
    region:SetTextColor(color.r, color.g, color.b, color.a or 1)
end

-- Задаёт прозрачность названия; тусклость подписи — в цвете текста, чтобы анимация рамки её не затирала.
local function SetDetailAlpha(self, ease)
    local color = self.Constants.LINE_COLOR
    self.detailTitle:SetAlpha(ease)
    self.detailCaption:SetAlpha(ease)
    self.detailCaption:SetTextColor(color.r, color.g, color.b, self.Constants.LABEL_CAPTION_ALPHA)
end

-- Создаёт линию, указатель, деления и подписи сторон света.
function Compass:CreateView()
    local C = self.Constants
    local frame = self.frame
    self.artwork, self.artworkLayout = {}, {}
    self.headingsDirty = true
    self.headingHeight = C.FONT_SIZE
    local line = C.LINE_COLOR
    local clear = CreateColor(line.r, line.g, line.b, 0)
    local solid = CreateColor(line.r, line.g, line.b, C.LINE_ALPHA)
    for index = 1, 3 do
        local texture = frame:CreateTexture(nil, "BORDER")
        texture:SetColorTexture(1, 1, 1)
        texture:SetSnapToPixelGrid(true)
        texture:SetTexelSnappingBias(0)
        texture:SetGradient("HORIZONTAL", index == 1 and clear or solid, index == 3 and clear or solid)
        self.artwork[index] = texture
    end
    self.pointer = frame:CreateTexture(nil, "OVERLAY")
    self.pointer:SetColorTexture(line.r, line.g, line.b)
    self.pointer:SetSnapToPixelGrid(true)
    self.pointer:SetTexelSnappingBias(0)
    self.ticks, self.markerSlots, self.selectedMarkers = {}, {}, {}
    self.nextMarkerSlots, self.markerSlotsByKey = {}, {}
    self.markerGroupOrder, self.markerGroups = {}, {}
    self.markerLeftOrder, self.markerGroupMembers = {}, {}
    self.markerGeneration, self.markerClock = 0, 0
    local directions = { self.L.N, self.L.W, self.L.S, self.L.E }
    for degrees = 0, C.FULL_TURN - C.TICK_STEP, C.TICK_STEP do
        local tick = { bearing = degrees, texture = frame:CreateTexture(nil, "ARTWORK") }
        tick.texture:SetColorTexture(line.r, line.g, line.b)
        tick.texture:SetSnapToPixelGrid(true)
        tick.texture:SetTexelSnappingBias(0)
        if degrees % C.CARDINAL_STEP == 0 then
            tick.label = frame:CreateFontString(nil, "OVERLAY")
            tick.labelText = directions[degrees / C.CARDINAL_STEP + 1]
        end
        self.ticks[#self.ticks + 1] = tick
    end
    self:CreateMarkerPool()
    -- Подложка под подписями: начинается у нижнего края полосы.
    local shadowFrame = CreateFrame("Frame", nil, frame)
    shadowFrame:EnableMouse(false)
    shadowFrame:SetClipsChildren(false)
    shadowFrame:Hide()
    local shadow = shadowFrame:CreateTexture(nil, "BACKGROUND")
    shadow:SetTexture(C.LABEL_SHADOW_TEXTURE)
    shadow:SetSnapToPixelGrid(true)
    shadow:SetTexelSnappingBias(0)
    self.labelShadowBottom = shadow
    ConsoleMenu:InitFadeAnimations(shadowFrame, C.LABEL_FADE_DURATION)
    self.labelShadow = shadowFrame
    -- Название и подпись выбранной точки, проявляются отдельно от значка.
    local detailFrame = CreateFrame("Frame", nil, frame)
    detailFrame:EnableMouse(false)
    detailFrame:SetClipsChildren(false)
    detailFrame:Hide()
    ConsoleMenu:InitFadeAnimations(detailFrame, C.LABEL_FADE_DURATION)
    self.detailFrame = detailFrame
    shadowFrame:SetFrameLevel(frame:GetFrameLevel())
    detailFrame:SetFrameLevel(frame:GetFrameLevel() + 2)
    -- Название точки по центру взгляда.
    self.detailTitle = detailFrame:CreateFontString(nil, "OVERLAY")
    self.detailTitle:SetMaxLines(1)
    self.detailTitle:SetJustifyH("CENTER")
    self.detailTitle:SetWordWrap(false)
    -- Расстояние и тип под названием.
    self.detailCaption = detailFrame:CreateFontString(nil, "OVERLAY")
    self.detailCaption:SetMaxLines(1)
    self.detailCaption:SetJustifyH("CENTER")
    self.detailCaption:SetWordWrap(false)
    self:CreatePeek()
end

-- Раскладывает линию, указатель и вертикаль подписей.
function Compass:LayoutArtwork()
    local C = self.Constants
    local frame = self.frame
    local scale = frame:GetEffectiveScale()
    local frameWidth, frameHeight = frame:GetSize()
    local centerX, centerY = frame:GetCenter()
    if not centerX or not centerY then
        return false
    end
    local thickness = Pixel:Multiple(C.LINE_THICKNESS, scale)
    local layout = self.artworkLayout
    if
        layout.width == frameWidth
        and layout.height == frameHeight
        and layout.centerX == centerX
        and layout.centerY == centerY
        and layout.scale == scale
        and layout.thickness == thickness
        and layout.headingHeight == self.headingHeight
    then
        return true
    end
    layout.width, layout.height, layout.centerX, layout.centerY = frameWidth, frameHeight, centerX, centerY
    layout.scale, layout.thickness = scale, thickness
    layout.headingHeight = self.headingHeight
    self.renderDirty, self.selectionDirty, self.headingsDirty = true, true, true
    self.detailTitle:SetWidth(frameWidth)
    self.detailCaption:SetWidth(frameWidth)
    local width = math.max(0, frameWidth - Pixel:Multiple(C.EDGE_INSET * 2, scale))
    layout.contentWidth = width
    layout.halfTickWidth = Pixel:Multiple(C.TICK_WIDTH, scale) / 2
    local lineY = Pixel:Snap(centerY + frameHeight * C.LINE_Y_FRACTION, scale) - centerY
    self.lineY = lineY
    -- Центр значка совпадает с серединой линии по высоте.
    layout.markerY = Pixel:Snap(lineY - thickness / 2, scale)
    local pointerHeight = Pixel:Multiple(C.POINTER_HEIGHT, scale)
    local pointerY = lineY - thickness - Pixel:Multiple(C.POINTER_GAP, scale)
    local lineBottom = lineY - thickness
    layout.headingY = Pixel:Snap(
        centerY + lineBottom - Pixel:Multiple(C.HEADING_GAP, scale),
        scale
    ) - centerY
    local detailY = layout.headingY - Pixel:Snap(self.headingHeight, scale) - Pixel:Multiple(C.LABEL_GAP, scale)
    self.detailTitle:ClearAllPoints()
    self.detailTitle:SetPoint("TOP", frame, "CENTER", 0, detailY)
    self.detailCaption:ClearAllPoints()
    self.detailCaption:SetPoint("TOP", self.detailTitle, "BOTTOM", 0, -Pixel:Multiple(C.LABEL_CAPTION_GAP, scale))
    local fadeWidth = width * C.LINE_FADE_FRACTION
    local sizes = { fadeWidth, width - fadeWidth * 2, fadeWidth }
    local left = -width / 2
    for index, texture in ipairs(self.artwork) do
        local right = left + sizes[index]
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", frame, "CENTER", Pixel:Snap(centerX + left, scale) - centerX, lineY)
        texture:SetPoint("TOPRIGHT", frame, "CENTER", Pixel:Snap(centerX + right, scale) - centerX, lineY)
        texture:SetHeight(thickness)
        left = right
    end
    self.pointer:SetSize(thickness, pointerHeight)
    self.pointer:ClearAllPoints()
    self.pointer:SetPoint("TOPLEFT", frame, "CENTER", Pixel:Snap(centerX - thickness / 2, scale) - centerX, pointerY)
    for _, tick in ipairs(self.ticks) do
        tick.texture:SetSize(Pixel:Multiple(C.TICK_WIDTH, scale), Pixel:Multiple(C.TICK_HEIGHT, scale))
    end
    local left = Pixel:Snap(centerX - frameWidth / 2, scale) - centerX
    local right = Pixel:Snap(centerX + frameWidth / 2, scale) - centerX
    local bottom = self.labelShadowBottom
    if bottom then
        local captionBottom = layout.headingY
            - Pixel:Snap(self.headingHeight, scale)
            - Pixel:Multiple(C.LABEL_GAP, scale)
            - Pixel:Snap(C.TITLE_FONT_SIZE, scale)
            - Pixel:Multiple(C.LABEL_CAPTION_GAP, scale)
            - Pixel:Snap(C.FONT_SIZE, scale)
        local shadowTop = Pixel:Snap(centerY + lineBottom, scale) - centerY + Pixel:Multiple(C.LABEL_SHADOW_OFFSET_Y, scale)
        local height = math.max(
            Pixel:Multiple(C.LABEL_SHADOW_FADE, scale),
            shadowTop - captionBottom + Pixel:Multiple(C.LABEL_SHADOW_FADE, scale)
        )
        bottom:ClearAllPoints()
        bottom:SetPoint("TOPLEFT", frame, "CENTER", left, shadowTop)
        bottom:SetPoint("TOPRIGHT", frame, "CENTER", right, shadowTop)
        bottom:SetHeight(height)
    end
    return true
end

-- Применяет шрифт и прозрачность указателя.
function Compass:StyleView()
    local C = self.Constants
    self.renderDirty, self.selectionDirty, self.headingsDirty = true, true, true
    local fontSize = C.FONT_SIZE
    self.headingHeight = 0
    for _, tick in ipairs(self.ticks) do
        if tick.label then
            StyleText(tick.label, fontSize, C.LINE_COLOR)
            tick.label:SetText(tick.labelText)
            self.headingHeight = math.max(self.headingHeight, tick.label:GetStringHeight())
            tick.labelAlpha = nil
        end
    end
    StyleText(self.detailTitle, C.TITLE_FONT_SIZE, C.LINE_COLOR)
    StyleText(self.detailCaption, fontSize, C.LINE_COLOR)
    SetDetailAlpha(self, 1)
    self:StylePeek(fontSize, true)
    for _, texture in ipairs(self.artwork) do
        texture:SetAlpha(1)
    end
    self.pointer:SetAlpha(C.POINTER_ALPHA)
    self:LayoutArtwork()
end

-- Возвращает прозрачность линии, подписей и значков после анимации рамки.
function Compass:RestoreViewAlpha()
    local C = self.Constants
    if self.artwork then
        for _, texture in ipairs(self.artwork) do
            texture:SetAlpha(1)
        end
    end
    if self.pointer then
        self.pointer:SetAlpha(C.POINTER_ALPHA)
    end
    if self.ticks then
        for _, tick in ipairs(self.ticks) do
            tick.alpha, tick.labelAlpha = nil, nil
        end
    end
    self.headingsDirty = true
    if self.detailTitle and self.detailCaption then
        SetDetailAlpha(self, 1)
    end
    if self.compassPeek and self.compassPeek.frame then
        self.compassPeek.frame:SetAlpha(1)
        self:StylePeek(C.FONT_SIZE, true)
    end
    self:RestoreMarkerAlphas()
    self.renderDirty = true
end

-- Скрывает все значки и подписи.
function Compass:ClearMarkers()
    self:HidePeek()
    if self.markerPool then
        self.markerPool:ReleaseAll()
    end
    wipe(self.markerSlots)
    wipe(self.nextMarkerSlots)
    wipe(self.markerSlotsByKey)
    wipe(self.selectedMarkers)
    wipe(self.selectionKeys)
    wipe(self.markerGroupOrder)
    wipe(self.markerGroups)
    wipe(self.markerLeftOrder)
    wipe(self.markerGroupMembers)
    self.markerRevealPending, self.markerSmoothPending = false, false
    wipe(self.arrivalMarkers)
    wipe(self.arrivalKeys)
    wipe(self.arrivalLeaving)
    wipe(self.nearbyFading)
    wipe(self.rangeLeaving)
    self.nearbyDisplayWidth, self.nearbySlotWidth = nil, nil
    self.arrivalBlend, self.arrivalEase, self.arrivalBlendPending, self.arrivalFanReveal = 0, 0, false, false
    self.selectionDirty, self.markerSlotsDirty, self.headingsDirty = true, true, true
    self:HideDetail(true)
    self:SetLabelShadowShown(false, true)
    self.renderDirty = true
end

-- Рисует деления и стороны света по направлению взгляда.
function Compass:RenderHeadings(facing)
    local C = self.Constants
    local fadingIn = self:IsFadeInPlaying()
    if not self.headingsDirty and self.renderFacing == facing then
        return
    end
    local frame = self.frame
    local layout = self.artworkLayout
    local scale, width = layout.scale, layout.contentWidth
    local headingY, halfTickWidth = layout.headingY, layout.halfTickWidth
    for _, tick in ipairs(self.ticks) do
        local x, alpha
        if facing then
            x, alpha = self:Project(tick.bearing, facing, self.viewAngle, width)
        end
        local visible = x ~= nil
        if tick.visible ~= visible then
            tick.texture:SetShown(visible and not tick.label)
            if tick.label then
                tick.label:SetShown(visible)
            end
            tick.visible = visible
        end
        if x then
            x = Pixel:Snap(x, scale)
            local centerX = layout.centerX
            local tickX = Pixel:Snap(centerX + x - halfTickWidth, scale) - centerX
            if not tick.label then
                if tick.x ~= tickX or tick.y ~= self.lineY then
                    tick.texture:SetPoint("TOPLEFT", frame, "CENTER", tickX, self.lineY)
                    tick.x, tick.y = tickX, self.lineY
                end
                if not fadingIn and tick.alpha ~= alpha then
                    tick.texture:SetAlpha(alpha * C.MINOR_TICK_ALPHA)
                    tick.alpha = alpha
                end
            end
            if tick.label then
                if tick.x ~= x or tick.y ~= headingY then
                    tick.label:SetPoint("TOP", frame, "CENTER", x, headingY)
                    tick.x, tick.y = x, headingY
                end
                local labelAlpha = alpha * C.HEADING_ALPHA
                if not fadingIn and tick.labelAlpha ~= labelAlpha then
                    tick.label:SetAlpha(labelAlpha)
                    tick.labelAlpha = labelAlpha
                end
            end
        end
    end
    self.headingsDirty = false
end

-- Останавливает проявление или скрытие рамки.
local function StopFade(frame)
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

-- Показывает или прячет подложку под подписями.
function Compass:SetLabelShadowShown(shown, immediate)
    local frame = self.labelShadow
    if not frame then
        return
    end
    if immediate then
        StopFade(frame)
        frame:SetShown(shown)
        self.labelShadowShown = shown and true or false
        return
    end
    shown = shown and true or false
    if self.labelShadowShown == shown then
        return
    end
    self.labelShadowShown = shown
    if shown then
        ConsoleMenu:AnimatedShow(frame)
    else
        ConsoleMenu:AnimatedHide(frame)
    end
end

-- Подложка видна, пока на полосе есть название или подпись.
function Compass:RefreshLabelShadow(immediate)
    local shown = self.detailShown
    if not shown then
        local slots = self.markerSlots
        if slots then
            for index = 1, #slots do
                if slots[index].labelShown then
                    shown = true
                    break
                end
            end
        end
    end
    self:SetLabelShadowShown(shown, immediate)
end

-- Скрывает название и подпись под полосой.
function Compass:HideDetail(immediate)
    if immediate then
        StopFade(self.detailFrame)
        if self.detailFrame then
            self.detailFrame:Hide()
        else
            self.detailTitle:Hide()
            self.detailCaption:Hide()
        end
        self.detailShown = false
        self.detailName, self.detailDistance, self.detailKind, self.detailNearby = nil, nil, nil, nil
        return
    end
    if self.detailShown then
        self.detailShown = false
        ConsoleMenu:AnimatedHide(self.detailFrame)
    end
end

-- Показывает название, расстояние или отметку прибытия под полосой.
function Compass:ShowDetail(marker, nearby)
    local distance = nearby and -1 or self:DisplayDistance(marker.distance)
    local kind = marker.kind
    if
        self.detailName ~= marker.name
        or self.detailDistance ~= distance
        or self.detailKind ~= kind
        or self.detailNearby ~= nearby
    then
        self.detailTitle:SetText(marker.name)
        local typeLabel = self.L[kind]
        local second = nearby and self.L.NEARBY or self:FormatDistance(marker.distance)
        if typeLabel then
            self.detailCaption:SetText(self.L.DETAIL_F:format(typeLabel, second))
        else
            self.detailCaption:SetText(second)
        end
        self.detailName, self.detailDistance, self.detailKind, self.detailNearby = marker.name, distance, kind, nearby
    end
    if not self.detailShown then
        self.detailShown = true
        ConsoleMenu:AnimatedShow(self.detailFrame)
    end
end

-- Показывает подпись, только когда выбранный значок уже достаточно ярок.
local function UpdateDetail(self, nearest, alpha)
    if nearest and self:ShouldShowMarkerLabel(self.detailShown, alpha) then
        self:ShowDetail(nearest)
    else
        self:HideDetail()
    end
end

-- Рисует полосу: стороны света, значки и подпись выбранной точки.
function Compass:Render(facing, live, elapsed)
    local C = self.Constants
    if not live and not self:LayoutArtwork() then
        return
    end
    self.markerSmoothElapsed = elapsed or 0
    self:UpdateArrivalBlend(self.markerSmoothElapsed)
    self:UpdateNearbyMotion(self.markerSmoothElapsed)
    local layout = self.artworkLayout
    local scale, width = layout.scale, layout.contentWidth
    self:RenderHeadings(facing)
    local nearest, nearestDelta, nearestAlpha
    local outline = Pixel:Multiple(C.MARKER_OUTLINE * 2, scale)
    local selection = self:SelectMarkers(facing, width, live)
    self:ApplyArrivalBlend(selection, facing)
    self:HoldLeavingMarkers(selection)
    self:LayoutMarkerGroups(selection)
    self:AssignMarkerSlots(selection, live)
    self.markerRevealPending, self.markerSmoothPending = false, false
    for index, marker in ipairs(selection) do
        local slot = self.markerSlots[index]
        marker.renderShown = self:RenderMarker(
            slot,
            marker,
            marker.projectedX,
            marker.projectedAlpha,
            layout.markerY,
            outline,
            scale
        )
        local absoluteDelta = math.abs(marker.projectedDelta or 0)
        if
            marker.renderShown
            and not marker.rangeHoldX
            and not marker.nearbyHoldX
            and absoluteDelta <= C.DETAIL_ANGLE
            and (
                not nearestDelta
                or absoluteDelta < nearestDelta
                or (absoluteDelta == nearestDelta and marker.distanceSquared < nearest.distanceSquared)
            )
        then
            nearest, nearestDelta, nearestAlpha = marker, absoluteDelta, slot.renderAlpha or 0
        end
    end
    -- Пока рамка проявляется, подписи не трогаем: иначе их прозрачность смешается с анимацией.
    if self:IsFadeInPlaying() then
        self.renderFacing = facing
        self.renderDirty = true
        return
    end
    local blend = self.arrivalBlend or 0
    local foci = self:GetNearbyFoci()
    if #foci > 0 and blend > 0 then
        self:HidePeek()
        self:HideDetail()
    elseif self.peekAltHeld then
        local marker, slot = self:FindPeekMarker()
        if marker then
            self:ShowPeek(marker, slot)
        else
            self:HidePeek()
        end
        UpdateDetail(self, nearest, nearestAlpha or 0)
    else
        self:HidePeek()
        UpdateDetail(self, nearest, nearestAlpha or 0)
    end
    self:RefreshLabelShadow()
    self.renderDirty, self.renderFacing = false, facing
end
