-- Markers.lua
-- Значки на полосе: пул рамок, отбор, группы и отрисовка.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Pixel = Compass.Pixel
local FULL_TEX_COORDS = { left = 0, right = 1, top = 0, bottom = 1 }
local ICON_COLOR = { r = 1, g = 1, b = 1 }
local QUEST_BACKGROUND_ATLAS = "UI-QuestPoi-QuestNumber"
local QUEST_SYMBOL_ATLASES = {
    ["Quest-In-Progress-Icon-yellow"] = true,
    ["UI-QuestIcon-TurnIn-Normal"] = true,
    ["Worldquest-icon"] = true,
}

-- Создаёт пул декоративных значков без мыши.
function Compass:CreateMarkerPool()
    local C = self.Constants
    self.markerPool = CreateObjectPool(function()
        local button = CreateFrame("Frame", nil, self.frame)
        button:EnableMouse(false)
        button.icon = button:CreateTexture(nil, "OVERLAY", nil, C.MARKER_ICON_SUBLEVEL)
        button.shadow = button:CreateTexture(nil, "OVERLAY", nil, C.MARKER_SHADOW_SUBLEVEL)
        button.shadow:SetAlpha(C.MARKER_OUTLINE_ALPHA)
        button.shadow:SetVertexColor(0, 0, 0)
        button.icon:SetRotation(0)
        button.shadow:SetRotation(0)
        button.icon:Show()
        button.shadow:Show()
        button.symbol = button:CreateTexture(nil, "OVERLAY", nil, C.MARKER_SYMBOL_SUBLEVEL)
        button.symbol:Hide()
        button.trackedGlow = button:CreateTexture(nil, "BACKGROUND")
        button.trackedGlow:SetAtlas(C.TRACKED_GLOW_ATLAS)
        button.trackedGlow:Hide()
        button.selectionFrame = CreateFrame("Frame", nil, button)
        button.selectionFrame:SetAllPoints(button)
        button.selectionFrame:EnableMouse(false)
        button.selection = button.selectionFrame:CreateTexture(nil, "OVERLAY", nil, C.SELECTION_MARKER_SUBLEVEL)
        button.selection:SetAtlas(C.SELECTION_MARKER_ATLAS)
        button.selection:SetRotation(0)
        button.selection:Hide()
        button:Hide()
        button.renderShown = false
        return button
    end, function(_, button)
        button:Hide()
        button:ClearAllPoints()
        if button.marker then
            button.marker.renderShown = false
        end
        button.marker, button.atlas = nil, nil
        button.sourceTexture, button.texLeft, button.texRight, button.texTop, button.texBottom = nil, nil, nil, nil, nil
        button.colorR, button.colorG, button.colorB = nil, nil, nil
        button.markerKey, button.revealAt, button.selected = nil, nil, false
        button.appearStart = nil
        button.renderX, button.renderAlpha, button.renderWaypoint, button.renderGlow, button.renderShown = nil, nil, nil, nil, false
        button.renderLeft, button.renderTop, button.smoothLeft = nil, nil, nil
        button.symbol:Hide()
        button.selection:Hide()
        button.trackedGlow:Hide()
    end)
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

-- Сдвигает уже отобранные значки при повороте.
local function ProjectSelection(self, facing, width)
    for _, marker in ipairs(self.selectedMarkers) do
        if not marker.bearing then
            if marker ~= self.arrivalMarker and marker ~= self.arrivalLeaving then
                return false
            end
        else
            local x, alpha, delta = self:Project(marker.bearing, facing, self.viewAngle, width, Compass.Constants.EDGE_CLIP_FRACTION)
            if not x or alpha <= 0 then
                return false
            end
            marker.projectedX, marker.projectedAlpha, marker.projectedDelta = x, alpha, delta
        end
    end
    return true
end

-- Отбирает до двадцати четырёх видимых значков.
function Compass:SelectMarkers(facing, width, live)
    local C = self.Constants
    local selection = self.selectedMarkers
    local focus = self.arrivalMarker or self.arrivalLeaving
    local blend = self.arrivalBlend or 0
    -- Пока точка гаснет на месте, веер значков ещё не показываем.
    local lock = focus and ((self.arrivalMarker and blend >= 1) or (not self.arrivalMarker and blend > 0))
    if lock then
        if live and not self.selectionDirty and #selection == 1 and selection[1] == focus then
            focus.projectedX, focus.projectedAlpha, focus.projectedDelta = 0, 1, 0
            return selection
        end
        wipe(selection)
        self.markerSlotsDirty = true
        focus.projectedX, focus.projectedAlpha, focus.projectedDelta = 0, 1, 0
        selection[1] = focus
        wipe(self.selectionKeys)
        self.selectionKeys[focus.key] = true
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
        if marker.bearing then
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

-- Плавно переводит полосу в режим прибытия и обратно.
function Compass:UpdateArrivalBlend(elapsed)
    local C = self.Constants
    if self.arrivalMarker then
        self.arrivalLeaving = self.arrivalMarker
        self.arrivalFanReveal = false
    end
    local target = self.arrivalMarker and 1 or 0
    local blend = self.arrivalBlend or 0
    if blend ~= target then
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
    if not self.arrivalMarker and blend <= 0 then
        self.arrivalLeaving = nil
        self.arrivalEase = 0
    end
end

-- Сдвигает точку прибытия к центру и гасит остальные значки по мере анимации.
function Compass:ApplyArrivalBlend(selection)
    local ease = self.arrivalEase or 0
    local focus = self.arrivalMarker or self.arrivalLeaving
    if ease <= 0 or not focus then
        return selection
    end
    if not self.arrivalMarker then
        -- Исчезновение: значок остаётся в центре и гаснет на месте.
        focus.projectedX, focus.projectedAlpha, focus.projectedDelta = 0, ease, 0
        return selection
    end
    local found
    for _, marker in ipairs(selection) do
        if marker == focus then
            found = true
            marker.projectedX = (marker.projectedX or 0) * (1 - ease)
            marker.projectedAlpha = 1
            marker.projectedDelta = marker.projectedDelta or 0
        else
            marker.projectedAlpha = (marker.projectedAlpha or 1) * (1 - ease)
        end
    end
    if not found then
        focus.projectedX, focus.projectedAlpha, focus.projectedDelta = 0, ease, 0
        selection[#selection + 1] = focus
        self.selectionKeys[focus.key] = true
        self.markerSlotsDirty = true
    end
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
        -- Размер не зависит от дальности, только от типа точки.
        marker.projectedIconSize = Pixel:Snap(self.iconSize * (marker.sizeScale or 1), scale)
        marker.projectedHitSize = marker.projectedIconSize + outline
        local left = centerX + marker.projectedX - marker.projectedHitSize / 2
        marker.projectedLeft = left
        marker.projectedLeftPx = Pixel:ToCount(left, scale)
        marker.projectedRightPx = marker.projectedLeftPx + Pixel:ToCount(marker.projectedHitSize, scale)
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
            while slots[freeIndex] and slots[freeIndex].markerGeneration == generation do
                freeIndex = freeIndex + 1
            end
            slot = slots[freeIndex] or self.markerPool:Acquire()
            freeIndex = freeIndex + 1
            if slot.markerKey then
                byKey[slot.markerKey] = nil
            end
            slot.markerKey, slot.markerGeneration = marker.key, generation
            slot.smoothLeft, slot.appearStart = nil, nil
            byKey[marker.key], nextSlots[index] = slot, slot
            assignedNew = true
        end
        if self.arrivalFanReveal then
            slot.revealAt = nil
            slot.appearStart = self.markerClock
            slot.smoothLeft = nil
        elseif marker == self.arrivalMarker or marker == self.arrivalLeaving or (self.arrivalBlend or 0) > 0 then
            slot.revealAt, slot.appearStart = nil, nil
        elseif self.rangeChanged and not slot.renderShown then
            slot.appearStart = self.markerClock
            slot.revealAt = nil
        elseif self.markerFadeIn and not slot.renderShown then
            -- Пока сама полоса проявляется, значки идут с ней; иначе проявляем отдельно.
            if not (self.frame.fadeIn and self.frame.fadeIn:IsPlaying()) then
                slot.appearStart = self.markerClock
            end
            slot.revealAt = nil
        elseif not live or marker.navigation or marker.priority <= C.TRACKED_QUEST_PRIORITY then
            slot.revealAt = nil
        elseif assignedNew or not slot.selected or not slot.marker or slot.marker.key ~= marker.key then
            slot.revealAt = self.markerClock + C.MARKER_REVEAL_DELAY
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
            if slot.marker then
                slot.marker.renderShown = false
            end
            if slot.renderShown then
                slot:Hide()
                slot.renderShown = false
            end
            slot.smoothLeft, slot.appearStart = nil, nil
            nextSlots[#nextSlots + 1] = slot
        end
    end
    self.markerSlots, self.nextMarkerSlots = nextSlots, slots
end

-- Проверяет, сменилась ли картинка значка.
local function MarkerArtChanged(button, marker, questSymbol)
    return button.atlas ~= marker.atlas
        or button.sourceTexture ~= marker.texture
        or button.questSymbol ~= questSymbol
        or button.texLeft ~= marker.texLeft
        or button.texRight ~= marker.texRight
        or button.texTop ~= marker.texTop
        or button.texBottom ~= marker.texBottom
        or button.colorR ~= marker.colorR
        or button.colorG ~= marker.colorG
        or button.colorB ~= marker.colorB
end

-- Назначает атлас или текстуру значку.
local function BindMarkerArt(button, marker, questSymbol)
    if marker.texture then
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
        local baseAtlas = questSymbol and QUEST_BACKGROUND_ATLAS or marker.atlas
        button.icon:SetAtlas(baseAtlas, questSymbol)
        button.shadow:SetAtlas(baseAtlas)
        button.icon:SetVertexColor(ICON_COLOR.r, ICON_COLOR.g, ICON_COLOR.b)
        if questSymbol then
            button.symbol:SetAtlas(marker.atlas, true)
            local width, height = button.icon:GetSize()
            local symbolWidth, symbolHeight = button.symbol:GetSize()
            button.symbolWidthScale, button.symbolHeightScale = symbolWidth / width, symbolHeight / height
        end
    end
    button.symbol:SetShown(questSymbol)
    button.atlas, button.sourceTexture, button.questSymbol = marker.atlas, marker.texture, questSymbol
    button.texLeft, button.texRight, button.texTop, button.texBottom =
        marker.texLeft, marker.texRight, marker.texTop, marker.texBottom
    button.colorR, button.colorG, button.colorB = marker.colorR, marker.colorG, marker.colorB
    button.layoutAtlas, button.renderAlpha = nil, nil
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
local function SmoothMarkerLeft(self, button, targetLeft, scale)
    local C = self.Constants
    local current = button.smoothLeft
    if not current or math.abs(targetLeft - current) >= C.MARKER_SMOOTH_SNAP then
        button.smoothLeft = targetLeft
        return targetLeft
    end
    local elapsed = self.markerSmoothElapsed or 0
    local tau = C.MARKER_SMOOTH_TIME
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
    local focus = self.arrivalMarker or self.arrivalLeaving
    local blending = (self.arrivalBlend or 0) > 0
    local arrived = blending and marker == focus
    local questSymbol = not marker.texture
        and (marker.kind == "quest" or marker.kind == "worldQuest" or QUEST_SYMBOL_ATLASES[marker.atlas] == true)
    if MarkerArtChanged(button, marker, questSymbol) then
        BindMarkerArt(button, marker, questSymbol)
    end
    if button.marker ~= marker then
        self:BindMarker(button, marker)
    end
    if arrived then
        button.revealAt = nil
        button.appearStart = nil
    end
    if marker.overlapGroup and #marker.overlapGroup.markers > 1 then
        button.revealAt = nil
    end
    if button.revealAt and self.markerClock < button.revealAt then
        self.markerRevealPending = true
        if button.renderShown then
            button:Hide()
            button.renderShown = false
            button.smoothLeft = nil
        end
        return false
    end
    button.revealAt = nil
    local baseLevel = self.frame:GetFrameLevel()
    local level = baseLevel + marker.depthLevel
    if button:GetFrameLevel() ~= level then
        button:SetFrameLevel(level)
    end
    local selectionLevel = baseLevel + C.MARKER_BASE_LEVEL + C.MAX_MARKERS
    if button.selectionFrame:GetFrameLevel() ~= selectionLevel then
        button.selectionFrame:SetFrameLevel(selectionLevel)
    end
    local markerSize, hitSize = marker.projectedIconSize, marker.projectedHitSize
    if
        button.layoutSize ~= markerSize
        or button.layoutOutline ~= outline
        or button.layoutHitSize ~= hitSize
        or button.layoutScale ~= scale
        or button.layoutAtlas ~= marker.atlas
    then
        button:SetSize(hitSize, hitSize)
        button.icon:SetSize(markerSize, markerSize)
        button.shadow:SetSize(markerSize + outline, markerSize + outline)
        local inset = Pixel:Snap((hitSize - markerSize) / 2, scale)
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
        local shadowInset = Pixel:Snap((hitSize - markerSize - outline) / 2, scale)
        button.shadow:SetPoint("TOPLEFT", button, "TOPLEFT", shadowInset, -shadowInset)
        if button.symbol:IsShown() then
            local symbolWidth = Pixel:Snap(markerSize * button.symbolWidthScale, scale)
            local symbolHeight = Pixel:Snap(markerSize * button.symbolHeightScale, scale)
            button.symbol:SetSize(symbolWidth, symbolHeight)
            button.symbol:SetPoint(
                "TOPLEFT",
                button,
                "TOPLEFT",
                Pixel:Snap((hitSize - symbolWidth) / 2, scale),
                -Pixel:Snap((hitSize - symbolHeight) / 2, scale)
            )
        end
        local selectionSize = Pixel:Snap(markerSize * C.SELECTION_MARKER_SCALE, scale)
        button.selection:SetSize(selectionSize, selectionSize)
        button.selection:SetPoint(
            "TOPLEFT",
            button.icon,
            "BOTTOMLEFT",
            Pixel:Snap((markerSize - selectionSize) / 2, scale),
            Pixel:Snap(selectionSize / 2, scale)
        )
        button.trackedGlow:SetSize(
            Pixel:Snap(markerSize * C.TRACKED_GLOW_WIDTH_SCALE, scale),
            Pixel:Snap(markerSize * C.TRACKED_GLOW_HEIGHT_SCALE, scale)
        )
        button.layoutSize, button.layoutOutline, button.layoutHitSize = markerSize, outline, hitSize
        button.layoutScale, button.layoutAtlas = scale, marker.atlas
    end
    local centerX, centerY = self.artworkLayout.centerX, self.artworkLayout.centerY
    local left
    if arrived then
        left = marker.projectedLeft - centerX
        button.smoothLeft = left
    else
        left = SmoothMarkerLeft(self, button, marker.projectedLeft - centerX, scale)
    end
    local top = Pixel:Snap(centerY + markerY + hitSize / 2, scale) - centerY
    if button.renderLeft ~= left or button.renderTop ~= top then
        button:SetPoint("TOPLEFT", self.frame, "CENTER", left, top)
        button.renderLeft, button.renderTop = left, top
    end
    button.renderX, button.renderY = left + hitSize / 2, top - hitSize / 2
    x = button.renderX
    local waypoint = marker.navigation == true
    local glow = waypoint or arrived
    if button.renderWaypoint ~= waypoint or button.renderGlow ~= glow then
        button.selection:SetShown(waypoint)
        button.trackedGlow:SetShown(glow)
        button.renderWaypoint, button.renderGlow = waypoint, glow
    end
    if glow then
        local glowAlpha = waypoint and 1 or (self.arrivalEase or 0)
        if button.glowAlpha ~= glowAlpha then
            button.trackedGlow:SetAlpha(glowAlpha)
            button.glowAlpha = glowAlpha
        end
        if button.glowX ~= x or button.glowY ~= self.lineY then
            button.trackedGlow:SetPoint("BOTTOM", self.frame, "CENTER", x, self.lineY)
            button.glowX, button.glowY = x, self.lineY
        end
    end
    if not arrived and not waypoint and marker.distance and marker.distance > self.range * (1 - C.MARKER_RANGE_FADE_FRACTION) then
        local fadeWidth = math.min(self.range * C.MARKER_RANGE_FADE_FRACTION, C.MARKER_RANGE_FADE_YARDS)
        local progress = math.max(0, math.min(1, (self.range - marker.distance) / fadeWidth))
        alpha = alpha * progress * progress * (3 - 2 * progress)
    end
    alpha = alpha * (marker.sourceAlpha or 1)
    if not arrived and button.appearStart then
        local duration = C.MARKER_APPEAR_DURATION
        local progress = duration > 0 and (self.markerClock - button.appearStart) / duration or 1
        if progress < 1 then
            progress = math.max(0, progress)
            alpha = alpha * progress * progress * (3 - 2 * progress)
            self.markerRevealPending = true
        else
            button.appearStart = nil
        end
    end
    if button.renderAlpha ~= alpha then
        button:SetAlpha(alpha)
        button.renderAlpha = alpha
    end
    if not button.renderShown then
        button.renderShown = true
        button:Show()
    end
    return true
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
