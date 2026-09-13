-- Bearings.lua
-- Азимуты, дальность и направление взгляда.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Number = Compass.Number

-- Сортирует точки: сначала выбранная цель, затем приоритет и расстояние.
local function MarkerBefore(a, b)
    if a.navigation ~= b.navigation then
        return a.navigation
    end
    if a.priority ~= b.priority then
        return a.priority < b.priority
    end
    if a.selectionDistanceSquared ~= b.selectionDistanceSquared then
        return a.selectionDistanceSquared < b.selectionDistanceSquared
    end
    return a.key < b.key
end

-- Пересобирает список точек с азимутом.
local function OrderBearings(self, forceSort)
    local C = self.Constants
    self.selectionDirty = true
    if forceSort or self.sortElapsed >= C.SORT_INTERVAL then
        for _, marker in ipairs(self.markers) do
            local bias = self.selectionKeys[marker.key] and C.MARKER_RETAINED_DISTANCE_SQUARED or 1
            marker.selectionDistanceSquared = marker.distanceSquared * bias
        end
        table.sort(self.markers, MarkerBefore)
        self.sortElapsed, self.sortPending = 0, false
    else
        self.sortPending = true
    end
    wipe(self.bearings)
    for _, marker in ipairs(self.markers) do
        if marker.bearing then
            self.bearings[#self.bearings + 1] = marker
        end
    end
end

-- Считает азимут одной точки относительно игрока.
function Compass:RefreshMarkerBearing(marker)
    if marker.bearingRevision == self.bearingRevision then
        return
    end
    local C = self.Constants
    local x, y = self.bearingPlayerX, self.bearingPlayerY
    local east, north = (marker.x - x) * self.mapWidth, (y - marker.y) * self.mapHeight
    marker.distanceSquared = east * east + north * north
    if marker.distanceSquared <= self.rangeSquared or marker.navigation or marker.priority == C.WAYPOINT_PRIORITY then
        marker.bearing, marker.distance = self:Bearing(east, north, marker.distanceSquared)
    else
        marker.bearing, marker.distance = nil, nil
    end
    marker.bearingRevision = self.bearingRevision
end

-- Обновляет азимуты при движении или смене набора точек.
function Compass:UpdateBearings(x, y)
    local C = self.Constants
    local resort = self.sortPending and self.sortElapsed >= C.SORT_INTERVAL
    local settle = x
        and self.bearingSampleX
        and (x ~= self.bearingSampleX or y ~= self.bearingSampleY)
        and self.discoveryClock >= self.bearingNextRefresh
    if not self.bearingsDirty and not settle and x == self.bearingPlayerX and y == self.bearingPlayerY then
        if resort and x and y then
            OrderBearings(self, true)
            self.renderDirty = true
        end
        return
    end
    local forceSort = self.bearingsDirty
    if forceSort or x ~= self.bearingPlayerX or y ~= self.bearingPlayerY then
        self.bearingRevision = (self.bearingRevision or 0) + 1
    end
    self.bearingsDirty, self.renderDirty = false, true
    self.bearingPlayerX, self.bearingPlayerY = x, y
    if not x or not y then
        self.navigationTarget, self.bearingSampleX = nil, nil
        wipe(self.arrivalMarkers)
        wipe(self.arrivalKeys)
        wipe(self.arrivalLeaving)
        self.arrivalBlend, self.arrivalEase, self.arrivalBlendPending = 0, 0, false
        self.selectionDirty = true
        wipe(self.bearings)
        return
    end
    local fullRefresh = forceSort or not self.bearingSampleX or self.discoveryClock >= self.bearingNextRefresh
    if not fullRefresh then
        local east, north = (x - self.bearingSampleX) * self.mapWidth, (y - self.bearingSampleY) * self.mapHeight
        fullRefresh = east * east + north * north >= C.BEARING_RESET_DISTANCE * C.BEARING_RESET_DISTANCE
    end
    if fullRefresh then
        self.bearingNextRefresh = self.discoveryClock + C.BEARING_REFRESH_INTERVAL
        self.bearingSampleX, self.bearingSampleY = x, y
        self.rangeSquared = self.range * self.range
        self.navigationTarget = nil
        for _, marker in ipairs(self.markers) do
            self:RefreshMarkerBearing(marker)
            if marker.key == self.navigationKey then
                self.navigationTarget = marker
            end
        end
        OrderBearings(self, forceSort)
    else
        if self.navigationTarget then
            self:RefreshMarkerBearing(self.navigationTarget)
        end
        for _, marker in ipairs(self.arrivalMarkers) do
            self:RefreshMarkerBearing(marker)
        end
        for _, slot in ipairs(self.markerSlots) do
            if slot.selected then
                self:RefreshMarkerBearing(slot.marker)
            end
        end
    end
    self:RefreshArrival()
end

-- Возвращает текущие или гаснущие точки режима «поблизости».
function Compass:GetNearbyFoci()
    if #self.arrivalMarkers > 0 then
        return self.arrivalMarkers
    end
    return self.arrivalLeaving
end

-- Проверяет, входит ли точка в набор «поблизости».
function Compass:IsNearbyFocus(marker)
    if not marker then
        return false
    end
    if self.arrivalKeys[marker.key] then
        return true
    end
    local leaving = self.arrivalLeaving
    for index = 1, #leaving do
        if leaving[index].key == marker.key then
            return true
        end
    end
    return false
end

-- Собирает до трёх точек в радиусе прибытия и удерживает их, пока игрок внутри зоны.
function Compass:RefreshArrival()
    local C = self.Constants
    local limit = C.NEARBY_YARDS_SQUARED
    local maxCount = C.NEARBY_MAX
    local held, keys, list = self.arrivalMarkers, self.arrivalKeys, self.markers
    local changed = false
    local write = 1
    for index = 1, #held do
        local previous = held[index]
        local live
        for _, marker in ipairs(list) do
            if marker.key == previous.key then
                live = marker
                break
            end
        end
        if live then
            self:RefreshMarkerBearing(live)
        end
        if live and live.distanceSquared and live.distanceSquared <= limit then
            if held[write] ~= live then
                changed = true
            end
            held[write] = live
            write = write + 1
        else
            changed = true
        end
    end
    for index = #held, write, -1 do
        held[index] = nil
    end
    wipe(keys)
    for index = 1, #held do
        keys[held[index].key] = true
    end
    while #held < maxCount do
        local best
        for _, marker in ipairs(list) do
            local distanceSquared = marker.distanceSquared
            if distanceSquared and distanceSquared <= limit and not keys[marker.key] then
                if
                    not best
                    or distanceSquared < best.distanceSquared
                    or (distanceSquared == best.distanceSquared and marker.key < best.key)
                then
                    best = marker
                end
            end
        end
        if not best then
            break
        end
        held[#held + 1] = best
        keys[best.key] = true
        changed = true
    end
    if changed then
        self.selectionDirty = true
        self.renderDirty = true
    end
end

-- Выбирает дальность по способу передвижения.
function Compass:GetTravelRange()
    local C = self.Constants
    local mounted = Compass.Readable(IsMounted()) == true
    local flying = Compass.Readable(IsFlying()) == true
    local canGlide
    if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
        _, canGlide = C_PlayerInfo.GetGlidingInfo()
        canGlide = Compass.Readable(canGlide) == true
    end
    if flying or (mounted and canGlide) then
        return C.RANGE_FLYING
    end
    if mounted then
        return C.RANGE_MOUNT
    end
    return C.RANGE_WALK
end

-- Подставляет дальность пешком, на наземном или летающем средстве передвижения.
function Compass:RefreshRange()
    local range = self:GetTravelRange()
    if self.range == range then
        return
    end
    self.range = range
    self.rangeSquared = range * range
    self.bearingsDirty = true
    self.selectionDirty = true
    self.renderDirty = true
    self.rangeChanged = true
end

-- Считывает положение и обновляет азимуты.
function Compass:RefreshBearings()
    local x, y
    if self.mapID and self.mapWidth then
        x, y = self:ReadPositionOnMap()
    end
    self:UpdateBearings(x, y)
end

-- Возвращает направление взгляда в градусах.
function Compass:GetFacing()
    local facing = Number(GetPlayerFacing())
    return facing and math.deg(facing)
end
