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
    local tracked = marker.navigation
        or (self.navigationKey and marker.key == self.navigationKey)
        or self:IsTrackedPoint(marker, self.navigationTarget)
    local inRange = marker.distanceSquared <= self.rangeSquared
        or tracked
        or marker.priority == C.WAYPOINT_PRIORITY
    if inRange and marker.distanceSquared <= C.BEARING_HOLD_YARDS_SQUARED then
        marker.distance = math.sqrt(marker.distanceSquared)
        if type(marker.bearing) ~= "number" then
            marker.bearing = self:GetFacing() or 0
        end
    elseif inRange then
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
        wipe(self.nearbyFading)
        wipe(self.rangeLeaving)
        self.nearbyDisplayWidth, self.nearbySlotWidth = nil, nil
        self.nearbyLiveCount = 0
        wipe(self.nearbyLiveKeys)
        self:ClearNearbyReflow()
        self.arrivalBlend, self.arrivalEase, self.arrivalBlendPending = 0, 0, false
        self.arrivalBlendFrom, self.arrivalBlendGoal, self.arrivalBlendElapsed = 0, 0, 0
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
    local fading = self.nearbyFading
    for index = 1, #fading do
        if fading[index].key == marker.key then
            return true
        end
    end
    return false
end

-- Оставляет ушедшую точку на месте, пока она не догаснет.
function Compass:QueueNearbyFade(marker)
    if not marker then
        return
    end
    local fading = self.nearbyFading
    for index = 1, #fading do
        if fading[index].key == marker.key then
            return
        end
    end
    marker.nearbyHoldX = marker.nearbyX or marker.projectedX or 0
    fading[#fading + 1] = marker
    self.nearbyMotionPending = true
    self.selectionDirty = true
    self.renderDirty = true
end

-- Убирает точку из догасающих, если она снова в наборе.
local function CancelNearbyFade(self, marker)
    local fading = self.nearbyFading
    for index = #fading, 1, -1 do
        if fading[index].key == marker.key then
            table.remove(fading, index)
        end
    end
    marker.nearbyHoldX = nil
end

-- Убирает выбранную цель из списка, если её рисует игровой указатель.
local function RemoveHiddenNavigation(self, list)
    local write = 1
    local changed = false
    for index = 1, #list do
        local marker = list[index]
        if self:ShouldHideNavigationMarker(marker) then
            changed = true
            marker.nearbyHoldX = nil
        else
            if write ~= index then
                list[write] = marker
            end
            write = write + 1
        end
    end
    for index = #list, write, -1 do
        list[index] = nil
    end
    return changed
end

-- Возвращает имя для объединения одинаковых точек «поблизости».
local function NearbyCollapseName(marker)
    local name = marker and marker.name
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return name
end

-- Истина, если первая точка ближе второй или при равной дальности её ключ меньше.
local function NearbyCloser(a, b)
    local first = type(a.distanceSquared) == "number" and a.distanceSquared or math.huge
    local second = type(b.distanceSquared) == "number" and b.distanceSquared or math.huge
    if first ~= second then
        return first < second
    end
    return a.key < b.key
end

-- Истина, если первая точка заметно ближе второй, без обмена на каждом шаге.
local function NearbyClearlyCloser(a, b)
    local first = type(a.distanceSquared) == "number" and a.distanceSquared or math.huge
    local second = type(b.distanceSquared) == "number" and b.distanceSquared or math.huge
    return first + Compass.Constants.NEARBY_NAME_SWAP_YARDS_SQUARED < second
end

-- Строит соответствие имени к номеру слота в ряду «поблизости».
local function NearbyNameSlots(held)
    local names = {}
    for index = 1, #held do
        local name = NearbyCollapseName(held[index])
        if name then
            names[name] = index
        end
    end
    return names
end

-- Оставляет в ряду одну точку на имя: ближайшую.
local function CollapseNearbyNames(held, keys, dropped)
    local seen = {}
    local write = 1
    for index = 1, #held do
        local marker = held[index]
        local name = NearbyCollapseName(marker)
        if not name then
            if write ~= index then
                held[write] = marker
            end
            write = write + 1
        elseif not seen[name] then
            seen[name] = write
            if write ~= index then
                held[write] = marker
            end
            write = write + 1
        elseif NearbyCloser(marker, held[seen[name]]) then
            local other = held[seen[name]]
            dropped = dropped or {}
            dropped[#dropped + 1] = other
            keys[other.key] = nil
            held[seen[name]] = marker
        else
            dropped = dropped or {}
            dropped[#dropped + 1] = marker
            keys[marker.key] = nil
        end
    end
    for index = #held, write, -1 do
        held[index] = nil
    end
    return dropped
end

-- Истина, если набор точек ряда отличается от предыдущего.
local function NearbySetChanged(previousKeys, held)
    local count = #held
    local seen = 0
    if previousKeys then
        for _ in pairs(previousKeys) do
            seen = seen + 1
        end
    end
    if seen ~= count then
        return true
    end
    for index = 1, count do
        if not previousKeys[held[index].key] then
            return true
        end
    end
    return false
end

-- Запоминает ключи точек текущего ряда.
local function StoreNearbyKeys(keys, held)
    wipe(keys)
    for index = 1, #held do
        keys[held[index].key] = true
    end
end

-- Собирает до трёх точек в радиусе прибытия или в области выполнения задания.
function Compass:RefreshArrival()
    local C = self.Constants
    local enterLimit = C.NEARBY_YARDS_SQUARED
    local leaveLimit = C.NEARBY_LEAVE_YARDS_SQUARED
    local maxCount = C.NEARBY_MAX
    local held, keys, list = self.arrivalMarkers, self.arrivalKeys, self.markers
    local changed = RemoveHiddenNavigation(self, held)
    changed = RemoveHiddenNavigation(self, self.arrivalLeaving) or changed
    changed = RemoveHiddenNavigation(self, self.nearbyFading) or changed
    local dropped
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
        if live and not self:ShouldHideNavigationMarker(live) and self:IsNearbyCandidate(live, leaveLimit) then
            if held[write] ~= live then
                changed = true
            end
            held[write] = live
            write = write + 1
        else
            changed = true
            if not (live and self:ShouldHideNavigationMarker(live)) then
                dropped = dropped or {}
                dropped[#dropped + 1] = previous
            end
        end
    end
    for index = #held, write, -1 do
        held[index] = nil
    end
    wipe(keys)
    for index = 1, #held do
        keys[held[index].key] = true
    end
    local droppedCount = dropped and #dropped or 0
    dropped = CollapseNearbyNames(held, keys, dropped)
    if (dropped and #dropped or 0) ~= droppedCount then
        changed = true
    end
    local names = NearbyNameSlots(held)
    -- Более близкая точка с тем же именем занимает слот, число секций не растёт.
    for _, marker in ipairs(list) do
        if not keys[marker.key] and not self:ShouldHideNavigationMarker(marker) and self:IsNearbyCandidate(marker, enterLimit) then
            local name = NearbyCollapseName(marker)
            local slot = name and names[name]
            if slot and NearbyClearlyCloser(marker, held[slot]) then
                local other = held[slot]
                dropped = dropped or {}
                dropped[#dropped + 1] = other
                keys[other.key] = nil
                CancelNearbyFade(self, marker)
                held[slot] = marker
                keys[marker.key] = true
                changed = true
            end
        end
    end
    while #held < maxCount do
        local best, bestDistance
        for _, marker in ipairs(list) do
            if not keys[marker.key] and not self:ShouldHideNavigationMarker(marker) and self:IsNearbyCandidate(marker, enterLimit) then
                local name = NearbyCollapseName(marker)
                if not (name and names[name]) then
                    local distanceSquared = marker.distanceSquared
                    if type(distanceSquared) ~= "number" then
                        distanceSquared = math.huge
                    end
                    if
                        not best
                        or distanceSquared < bestDistance
                        or (distanceSquared == bestDistance and marker.key < best.key)
                    then
                        best, bestDistance = marker, distanceSquared
                    end
                end
            end
        end
        if not best then
            break
        end
        CancelNearbyFade(self, best)
        held[#held + 1] = best
        keys[best.key] = true
        local name = NearbyCollapseName(best)
        if name then
            names[name] = #held
        end
        changed = true
    end
    -- Последняя точка гаснет вместе с режимом, остальные — на своём месте.
    if #held > 0 and dropped then
        for index = 1, #dropped do
            self:QueueNearbyFade(dropped[index])
        end
    end
    local newCount = #held
    if not self.nearbyLiveKeys then
        self.nearbyLiveKeys = {}
    end
    local compositionChanged = NearbySetChanged(self.nearbyLiveKeys, held)
    if newCount == 0 then
        self:ClearNearbyReflow()
        wipe(self.nearbyLiveKeys)
    elseif
        not self.snapArrivalOnShow
        and (self.arrivalBlend or 0) >= 1
        and (self.nearbyLiveCount or 0) > 0
        and compositionChanged
    then
        self:BeginNearbyReflow()
    end
    self.nearbyLiveCount = newCount
    StoreNearbyKeys(self.nearbyLiveKeys, held)
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
