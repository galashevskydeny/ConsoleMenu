-- Peek.lua
-- Всплывающая подпись названия и расстояния при удержании Alt.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Pixel = Compass.Pixel
local PEEK_LEVEL = 26
local MAX_WIDTH = 240
local PADDING = 6
local HEADING_GAP = 6
local TEXT_GAP = 2
local CONNECTOR_WIDTH = 1
local NAME_LINES = 2
local BACKGROUND = { r = 0.025, g = 0.035, b = 0.055, a = 0.88 }
local CONNECTOR_COLOR = { r = 1, g = 0.82, b = 0.46, a = 0.7 }

-- Ищет первую видимую точку, не закрытую выбранной целью.
function Compass:FindPeekMarker()
    local target = self.navigationTarget
    local trackedLeft, trackedRight, trackedSize, trackedLevel
    for _, marker in ipairs(self.markerGroupOrder) do
        local slot = self.markerSlotsByKey[marker.key]
        if slot and slot.marker == marker and slot.renderShown and slot.renderAlpha > 0 and self:IsTrackedPoint(marker, target) then
            trackedLeft = trackedLeft and math.min(trackedLeft, marker.projectedLeftPx) or marker.projectedLeftPx
            trackedRight = trackedRight and math.max(trackedRight, marker.projectedRightPx) or marker.projectedRightPx
            trackedSize = math.max(trackedSize or 0, marker.projectedHitSize)
            trackedLevel = math.max(trackedLevel or 0, marker.depthLevel)
        end
    end
    for _, marker in ipairs(self.markerGroupOrder) do
        local slot = self.markerSlotsByKey[marker.key]
        if
            slot
            and slot.marker == marker
            and slot.renderShown
            and slot.renderAlpha > 0
            and not self:IsTrackedPoint(marker, target)
        then
            local covered = trackedLeft
                and marker.depthLevel < trackedLevel
                and marker.projectedLeftPx >= trackedLeft
                and marker.projectedRightPx <= trackedRight
                and marker.projectedHitSize <= trackedSize
            if not covered then
                return marker, slot
            end
        end
    end
end

-- Создаёт рамку подписи и линию к значку.
function Compass:CreatePeek()
    local frame = CreateFrame("Frame", nil, self.frame)
    frame:EnableMouse(false)
    frame:Hide()
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(BACKGROUND.r, BACKGROUND.g, BACKGROUND.b, BACKGROUND.a)
    local connector = frame:CreateTexture(nil, "BACKGROUND")
    connector:SetColorTexture(CONNECTOR_COLOR.r, CONNECTOR_COLOR.g, CONNECTOR_COLOR.b, CONNECTOR_COLOR.a)
    connector:SetSnapToPixelGrid(true)
    connector:SetTexelSnappingBias(0)
    local name = frame:CreateFontString(nil, "OVERLAY")
    name:SetMaxLines(NAME_LINES)
    name:SetJustifyH("CENTER")
    name:SetJustifyV("TOP")
    name:SetWordWrap(true)
    name:SetNonSpaceWrap(true)
    local distance = frame:CreateFontString(nil, "OVERLAY")
    distance:SetMaxLines(1)
    distance:SetJustifyH("CENTER")
    self.compassPeek = {
        frame = frame,
        name = name,
        distance = distance,
        connector = connector,
        shown = false,
        measureDirty = true,
    }
end

-- Применяет шрифт к подписи.
function Compass:StylePeek(fontSize, refresh)
    local peek = self.compassPeek
    local scale = peek.frame:GetEffectiveScale()
    if not refresh and peek.fontSize == fontSize and peek.fontScale == scale then
        return
    end
    peek.name:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    peek.distance:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    local offset = Pixel:Multiple(self.Constants.SHADOW_OFFSET, scale)
    peek.name:SetShadowOffset(offset, -offset)
    peek.distance:SetShadowOffset(offset, -offset)
    local color = self.Constants.LINE_COLOR
    peek.name:SetTextColor(color.r, color.g, color.b, 1)
    peek.distance:SetTextColor(color.r, color.g, color.b, self.Constants.LABEL_CAPTION_ALPHA)
    peek.fontSize, peek.fontScale = fontSize, scale
    peek.measureDirty = true
end

-- Скрывает подпись.
function Compass:HidePeek()
    local peek = self.compassPeek
    if peek and peek.shown then
        peek.frame:Hide()
        peek.shown = false
    end
end

-- Показывает подпись над выбранной точкой.
function Compass:ShowPeek(marker, slot)
    local peek, layout = self.compassPeek, self.artworkLayout
    local scale, centerX, centerY = layout.scale, layout.centerX, layout.centerY
    if peek.fontScale ~= scale then
        self:StylePeek(peek.fontSize)
    end
    if peek.lastName ~= marker.name then
        peek.name:SetText(marker.name)
        peek.lastName, peek.measureDirty = marker.name, true
    end
    local displayDistance = self:DisplayDistance(marker.distance)
    if peek.lastDistance ~= displayDistance then
        peek.distance:SetText(self:FormatDistance(marker.distance))
        peek.lastDistance = displayDistance
        peek.measureDirty = true
    end
    local measured = peek.measureDirty
    if measured then
        peek.nameWidth = peek.name:GetUnboundedStringWidth()
        peek.distanceWidth = peek.distance:GetUnboundedStringWidth()
        peek.measureDirty = false
    end
    local padding = Pixel:Multiple(PADDING, scale)
    local textGap = Pixel:Multiple(TEXT_GAP, scale)
    local ribbonLeft = Pixel:Snap(centerX - layout.contentWidth / 2, scale)
    local ribbonRight = Pixel:Snap(centerX + layout.contentWidth / 2, scale)
    local width = math.min(
        Pixel:Snap(MAX_WIDTH, scale),
        ribbonRight - ribbonLeft,
        Pixel:Snap(math.max(peek.nameWidth, peek.distanceWidth) + padding * 2, scale)
    )
    if width <= padding * 2 then
        self:HidePeek()
        return
    end
    if measured or peek.width ~= width or peek.scale ~= scale then
        local textWidth = width - padding * 2
        if peek.textWidth ~= textWidth then
            peek.name:SetWidth(textWidth)
            peek.distance:SetWidth(textWidth)
            peek.textWidth = textWidth
        end
        local nameHeight = Pixel:Snap(peek.name:GetStringHeight(), scale)
        local distanceHeight = Pixel:Snap(peek.distance:GetStringHeight(), scale)
        if peek.scale ~= scale then
            peek.name:SetPoint("TOPLEFT", peek.frame, "TOPLEFT", padding, -padding)
        end
        if peek.nameHeight ~= nameHeight or peek.scale ~= scale then
            peek.distance:SetPoint("TOPLEFT", peek.frame, "TOPLEFT", padding, -padding - nameHeight - textGap)
            peek.nameHeight = nameHeight
        end
        local height = Pixel:Snap(nameHeight + distanceHeight + textGap + padding * 2, scale)
        if peek.width ~= width or peek.height ~= height then
            peek.frame:SetSize(width, height)
            peek.width, peek.height = width, height
        end
    end
    local hitSize, iconSize = marker.projectedHitSize, marker.projectedIconSize
    local inset = Pixel:Snap((hitSize - iconSize) / 2, scale)
    local iconX = slot.renderX - hitSize / 2 + inset + iconSize / 2
    local offsetY = 0
    if not marker.navigation then
        offsetY = Pixel:Multiple(marker.offsetY or 0, scale)
    end
    local iconBottom = Pixel:Snap(centerY + slot.renderY + hitSize / 2 - inset - iconSize + offsetY, scale)
    local left = math.max(ribbonLeft, math.min(ribbonRight - width, Pixel:Snap(centerX + iconX - width / 2, scale)))
    local top = Pixel:Snap(centerY + layout.headingY - self.headingHeight - Pixel:Multiple(HEADING_GAP, scale), scale)
    if peek.left ~= left or peek.top ~= top or peek.centerX ~= centerX or peek.centerY ~= centerY then
        peek.frame:SetPoint("TOPLEFT", self.frame, "CENTER", left - centerX, top - centerY)
        peek.left, peek.top = left, top
    end
    local lineWidth = Pixel:Multiple(CONNECTOR_WIDTH, scale)
    local lineLeft = Pixel:Snap(centerX + iconX - lineWidth / 2, scale)
    if
        peek.lineLeft ~= lineLeft
        or peek.lineTop ~= iconBottom
        or peek.centerX ~= centerX
        or peek.centerY ~= centerY
    then
        peek.connector:SetPoint("TOPLEFT", self.frame, "CENTER", lineLeft - centerX, iconBottom - centerY)
        peek.lineLeft, peek.lineTop = lineLeft, iconBottom
    end
    local lineHeight = math.max(lineWidth, iconBottom - top)
    if peek.lineWidth ~= lineWidth or peek.lineHeight ~= lineHeight then
        peek.connector:SetSize(lineWidth, lineHeight)
        peek.lineWidth, peek.lineHeight = lineWidth, lineHeight
    end
    peek.scale, peek.centerX, peek.centerY = scale, centerX, centerY
    local level = self.frame:GetFrameLevel() + PEEK_LEVEL
    if peek.frame:GetFrameLevel() ~= level then
        peek.frame:SetFrameLevel(level)
    end
    if not peek.shown then
        peek.frame:Show()
        peek.shown = true
    end
end

-- Запоминает, удерживается ли Alt.
function Compass:RefreshPeekModifier()
    local held = Compass.Readable(IsAltKeyDown()) == true
    if self.peekAltHeld ~= held then
        self.peekAltHeld, self.renderDirty = held, true
        if not held then
            self:HidePeek()
        end
    end
end
