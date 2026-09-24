-- Discovery.lua
-- Пошаговый сбор точек карты с ограничением времени кадра.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Number = Compass.Number
local Readable = Compass.Readable
local ReadPosition = Compass.ReadPosition

-- Источники точек и интервалы их обновления.
local SOURCES = {
    { key = "quests", collect = "CollectQuests", interval = 30, refreshPath = "RefreshQuestPath" },
    { key = "vignettes", collect = "CollectVignettes", interval = 2 },
    { key = "map", collect = "CollectMapPoints", interval = math.huge },
    { key = "taxi", collect = "CollectFlightMasters", interval = 60 },
    { key = "directions", collect = "CollectDirections", interval = 30 },
    { key = "links", collect = "CollectMapLinks", interval = 60 },
    { key = "tamers", collect = "CollectPetTamers", interval = 60 },
    { key = "digsites", collect = "CollectDigSites", interval = 30 },
    { key = "content", collect = "CollectTrackedContent", interval = 30 },
    { key = "offers", collect = "CollectQuestOffers", interval = 30 },
    { key = "corpse", collect = "CollectCorpse", interval = 2 },
    { key = "party", collect = "CollectGroupMembers", interval = 0.5 },
    { key = "battlefield", collect = "CollectBattlefield", interval = 0.5 },
}

-- Какие источники помечаются событиями игры.
local EVENT_SOURCES = {
    AREA_POIS_UPDATED = "map",
    VIGNETTES_UPDATED = "vignettes",
    VIGNETTE_MINIMAP_UPDATED = "vignettes",
    QUEST_LOG_UPDATE = { "quests", "offers" },
    QUEST_WATCH_LIST_CHANGED = "quests",
    QUEST_POI_UPDATE = { "quests", "offers" },
    QUEST_DATA_LOAD_RESULT = { "quests", "offers" },
    SUPER_TRACKING_CHANGED = { "quests", "content" },
    SUPER_TRACKING_PATH_UPDATED = "content",
    WORLD_QUEST_COMPLETED_BY_SPELL = "quests",
    TAXI_NODE_STATUS_CHANGED = "taxi",
    DYNAMIC_GOSSIP_POI_UPDATED = "directions",
    SPELLS_CHANGED = "tamers",
    RESEARCH_ARTIFACT_DIG_SITE_UPDATED = "digsites",
    ARTIFACT_DIGSITE_COMPLETE = "digsites",
    CONTENT_TRACKING_UPDATE = "content",
    CONTENT_TRACKING_LIST_UPDATE = "content",
    CONTENT_TRACKING_IS_ENABLED_UPDATE = "content",
    TRACKABLE_INFO_UPDATE = "content",
    TRACKING_TARGET_INFO_UPDATE = "content",
    QUESTLINE_UPDATE = { "offers", "map" },
    MINIMAP_UPDATE_TRACKING = { "offers", "map" },
    QUEST_ACCEPTED = { "quests", "offers" },
    QUEST_TURNED_IN = { "quests", "offers" },
    QUEST_REMOVED = { "quests", "offers" },
    PLAYER_DEAD = "corpse",
    PLAYER_ALIVE = "corpse",
    PLAYER_UNGHOST = "corpse",
    CORPSE_IN_RANGE = "corpse",
    CORPSE_OUT_OF_RANGE = "corpse",
    CEMETERY_PREFERENCE_UPDATED = "corpse",
    REQUEST_CEMETERY_LIST_RESPONSE = "corpse",
    GROUP_ROSTER_UPDATE = "party",
    PVP_VEHICLE_INFO_UPDATED = "battlefield",
    ARENA_OPPONENT_UPDATE = "battlefield",
}

-- Останавливает текущий сбор источника.
local function CancelDiscoveryJob(self)
    self.discoveryJob = nil
end

-- Сравнивает новый набор точек с предыдущим.
local function SourceChanged(self, previous, markers)
    local C = self.Constants
    if #previous ~= #markers then
        return true
    end
    for index, marker in ipairs(markers) do
        local old = previous[index]
        if
            old.key ~= marker.key
            or old.x ~= marker.x
            or old.y ~= marker.y
            or old.name ~= marker.name
            or old.description ~= marker.description
            or old.atlas ~= marker.atlas
            or old.priority ~= marker.priority
            or old.kind ~= marker.kind
            or old.destination.mapID ~= marker.destination.mapID
            or old.destination.x ~= marker.destination.x
            or old.destination.y ~= marker.destination.y
        then
            return true
        end
        for _, field in ipairs(C.MARKER_ART_FIELDS) do
            if old[field] ~= marker[field] then
                return true
            end
        end
        self:DiscoveryCheckpoint()
    end
    return false
end

-- Приостанавливает сбор, если исчерпан бюджет кадра.
function Compass:DiscoveryCheckpoint()
    local C = self.Constants
    self.discoverySteps = (self.discoverySteps or 0) + 1
    local deadline = self.discoveryDeadline
    local overBudget = self.discoverySteps >= C.DISCOVERY_STEPS
        or (type(deadline) == "number" and debugprofilestop() >= deadline)
    if overBudget and coroutine.running() then
        coroutine.yield()
    end
end

-- Сбрасывает состояние всех источников.
function Compass:InitializeDiscovery()
    local C = self.Constants
    CancelDiscoveryJob(self)
    self.compassOfferMapID = nil
    self.discoveryClock, self.discoveryNext = 0, 0
    self.bearingSampleX = nil
    self.selectionKeys = {}
    if self.questAreaState then
        wipe(self.questAreaState)
    else
        self.questAreaState = {}
    end
    self.hideNavigationState = nil
    self.compassSources = {}
    for _, definition in ipairs(SOURCES) do
        self.compassSources[definition.key] = { markers = {}, dirty = true, nextAllowed = 0, nextRefresh = 0 }
    end
end

-- Убирает сданные и отменённые задания из готового списка точек.
function Compass:StripRetiredQuestMarkers(markers)
    if not markers then
        return false
    end
    local retired = self.retiredQuests
    local removed = false
    for index = #markers, 1, -1 do
        local questID = markers[index].questID
        if questID and retired[questID] then
            table.remove(markers, index)
            removed = true
        end
    end
    return removed
end

-- Собирает копию списка без сданных и отменённых заданий.
local function WithoutRetiredQuests(self, markers)
    local retired = self.retiredQuests
    local kept, removed = {}, false
    for _, marker in ipairs(markers) do
        local questID = marker.questID
        if questID and retired[questID] then
            removed = true
        else
            kept[#kept + 1] = marker
        end
    end
    return kept, removed
end

-- Сразу снимает значок с полосы и из ещё не законченного сбора заданий.
function Compass:DropRetiredQuestMarker()
    local quests = self.compassSources and self.compassSources.quests
    if not quests then
        return
    end
    -- Новый список, чтобы незавершённый обход прежнего не пропустил соседнюю точку.
    local kept, removed = WithoutRetiredQuests(self, quests.markers)
    if removed then
        quests.markers = kept
        if self.markers then
            self:RebuildMarkers()
        end
    end
    local job = self.discoveryJob
    if job and job.definition and job.definition.key == "quests" then
        self:StripRetiredQuestMarkers(job.markers)
    end
end

-- Запоминает сданное или отменённое задание, чтобы устаревшая карта не вернула значок.
function Compass:RememberRetiredQuest(questID)
    questID = Number(questID)
    if not questID or questID <= 0 then
        return
    end
    self.retiredQuests[questID] = true
    self:DropRetiredQuestMarker()
end

-- Разрешает снова показать задание, если его взяли заново.
function Compass:ForgetRetiredQuest(questID)
    questID = Number(questID)
    if not questID then
        return
    end
    self.retiredQuests[questID] = nil
end

-- Проверяет, что задание недавно сдано или отменено и его рано возвращать на полосу.
function Compass:IsQuestRetired(questID)
    return questID ~= nil and self.retiredQuests[questID] == true
end

-- Забывает задание, когда журнал, местные цели и карта его больше не сообщают.
function Compass:ReleaseRetiredQuests(onMap)
    if not onMap then
        return
    end
    local retired = self.retiredQuests
    for questID in pairs(retired) do
        local stillReported = onMap[questID] == true
            or Readable(C_QuestLog.IsOnQuest(questID)) == true
            or Readable(C_TaskQuest.IsActive(questID)) == true
        if not stillReported then
            retired[questID] = nil
        end
        self:DiscoveryCheckpoint()
    end
end

-- Помечает источник к пересбору после смены настроек или карты.
function Compass:InvalidateSourceSettings(key)
    local source = self.compassSources[key]
    if not source then
        return
    end
    if self.discoveryJob and self.discoveryJob.source == source then
        CancelDiscoveryJob(self)
    end
    source.mapArtID = nil
    wipe(source.markers)
    source.dirty, source.pathDirty, source.nextAllowed = true, false, self.discoveryClock
    self.discoveryPending, self.waypointDirty = true, true
end

-- Разбирает игровое событие и помечает нужные источники.
function Compass:InvalidateSource(event)
    if event == "USER_WAYPOINT_UPDATED" then
        self.waypointDirty = true
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UNIT_PHASE" then
        self.discoveryDirty = true
    elseif event:find("^ZONE_CHANGED") then
        local mapID = Number(C_Map.GetBestMapForUnit("player"))
        if mapID and mapID == self.mapID and self.mapWidth then
            local taxi, job = self.compassSources.taxi, self.discoveryJob
            local retainTaxi = not taxi.dirty and not taxi.pathDirty and not (job and job.source == taxi)
            if retainTaxi then
                local mapArtID = Number(C_Map.GetMapArtID(mapID))
                retainTaxi = mapArtID ~= nil and mapArtID == taxi.mapArtID
            end
            CancelDiscoveryJob(self)
            for key, source in pairs(self.compassSources) do
                if key ~= "taxi" or not retainTaxi then
                    source.dirty, source.pathDirty, source.nextAllowed = true, false, self.discoveryClock
                end
            end
            self.discoveryPending, self.waypointDirty = true, true
        else
            self.discoveryDirty = true
        end
    else
        local sources = EVENT_SOURCES[event]
        if type(sources) == "table" then
            for _, key in ipairs(sources) do
                self.compassSources[key].dirty = true
            end
        elseif sources then
            self.compassSources[sources].dirty = true
        end
        self.discoveryPending = true
        if event == "SUPER_TRACKING_PATH_UPDATED" then
            self.compassSources.quests.pathDirty = true
        elseif event == "SUPER_TRACKING_CHANGED" then
            self.waypointDirty = true
        end
    end
end

-- Выбирает следующий источник, которому пора обновиться.
local function NextSource(self)
    local nextRefresh = math.huge
    for _, definition in ipairs(SOURCES) do
        local source = self.compassSources[definition.key]
        local due = (source.dirty or source.pathDirty) and math.min(source.nextAllowed, source.nextRefresh)
            or source.nextRefresh
        if self.discoveryClock >= due then
            return source, definition
        end
        nextRefresh = math.min(nextRefresh, due)
    end
    self.discoveryNext, self.discoveryPending = nextRefresh, false
end

-- Ищет совпадающую точку для подписи путевой точки.
local function FindWaypointMarker(self, markers, position, sourceKey)
    local C = self.Constants
    local x, y = ReadPosition(position)
    local match
    if x and y then
        for _, marker in ipairs(markers) do
            if
                math.abs(marker.x - x) < C.WAYPOINT_MATCH_EPSILON
                and math.abs(marker.y - y) < C.WAYPOINT_MATCH_EPSILON
                and (not sourceKey or marker.key == sourceKey)
                and (
                    not match
                    or marker.priority < match.priority
                    or (marker.priority == match.priority and marker.key < match.key)
                )
            then
                match = marker
            end
        end
    end
    return match
end

-- Читает пользовательскую путевую точку карты.
local function ReadWaypoint(self)
    local point = Readable(C_Map.GetUserWaypoint())
    local mapID = point and Number(point.uiMapID)
    local position = point and Readable(point.position)
    if not mapID or not position then
        self.waypointLabel = nil
        return
    end
    local x, y = ReadPosition(position)
    if not x or not y then
        self.waypointLabel = nil
        return
    end
    local title, description, sourceKey = self:GetWaypointTitle(mapID, x, y)
    return mapID, x, y, title, description, sourceKey
end

-- Добавляет путевую точку в общий список после остальных источников.
local function CollectWaypoint(self, mapID, x, y, title, description, sourceKey)
    local C = self.Constants
    if not mapID then
        return
    end
    local position = self:ProjectDestination(mapID, x, y)
    if not position then
        return
    end
    local match = FindWaypointMarker(self, self.markers, position, sourceKey)
    if sourceKey and match then
        title, description = match.name, match.description
        if self.waypointLabel then
            self.waypointLabel.title, self.waypointLabel.description = title, description
        end
    end
    local marker = self:AddMarker(
        self.markers,
        "waypoint",
        position,
        title,
        match and match.atlas or C.FALLBACK_ATLAS,
        C.WAYPOINT_PRIORITY,
        match and match.kind or "waypoint",
        { mapID = mapID, x = x, y = y }
    )
    if marker then
        marker.description = description
        marker.sourceKey = sourceKey
        if match then
            for _, field in ipairs(C.MARKER_ART_FIELDS) do
                marker[field] = match[field]
            end
        end
    end
end

-- Собирает общий список точек и отмечает выбранную цель.
function Compass:RebuildMarkers()
    self.bearingsDirty = true
    wipe(self.markers)
    if not self.mapWidth then
        return
    end
    local mapID, x, y, title, description, sourceKey = ReadWaypoint(self)
    for _, source in pairs(self.compassSources) do
        for _, marker in ipairs(source.markers) do
            self.markers[#self.markers + 1] = marker
        end
    end
    CollectWaypoint(self, mapID, x, y, title, description, sourceKey)
    self:SelectNavigation()
end

-- Выполняет очередной шаг сбора источников.
function Compass:DiscoverMarkers()
    local C = self.Constants
    if self.discoveryDirty or not self.mapWidth then
        self:InitializeDiscovery()
        self.discoveryDirty, self.waypointDirty = false, true
        self:RefreshMap()
    end
    if self.waypointDirty then
        self:RebuildMarkers()
        self.waypointDirty = false
    end
    if not self.mapWidth then
        self.discoveryNext, self.discoveryPending = self.discoveryClock + C.DISCOVERY_INTERVAL, false
        return
    end
    self.discoveryDeadline = debugprofilestop() + C.DISCOVERY_BUDGET_MS
    self.discoverySteps = 0
    local changed = false
    repeat
        local job = self.discoveryJob
        if not job then
            local source, definition = NextSource(self)
            if not source then
                break
            end
            local pathOnly = definition.refreshPath
                and source.pathDirty
                and not source.dirty
                and self.discoveryClock < source.nextRefresh
            local collect = pathOnly and definition.refreshPath or definition.collect
            source.dirty, source.pathDirty = false, false
            source.nextAllowed = self.discoveryClock + C.DISCOVERY_MIN_INTERVAL
            source.mapArtID = nil
            local markers = {}
            job = {
                source = source,
                definition = definition,
                pathOnly = pathOnly,
                mapArtID = definition.key == "taxi" and Number(C_Map.GetMapArtID(self.mapID)) or nil,
                markers = markers,
                thread = coroutine.create(function()
                    local refreshInterval = self[collect](self, markers)
                    job.nextRefresh = refreshInterval and self.discoveryClock + refreshInterval
                    return SourceChanged(self, source.markers, markers)
                end),
            }
            self.discoveryJob = job
        end
        local ok, result = coroutine.resume(job.thread)
        if self.discoveryJob ~= job then
            if not ok then
                geterrorhandler()(result)
            end
            break
        end
        if not ok then
            self.discoveryJob = nil
            if not job.pathOnly then
                job.source.nextRefresh = self.discoveryClock + job.definition.interval
            end
            geterrorhandler()(result)
            break
        end
        if coroutine.status(job.thread) ~= "dead" then
            break
        end
        -- Сбор мог начаться раньше сдачи и ещё держать значок в готовом списке.
        if job.definition.key == "quests" and self:StripRetiredQuestMarkers(job.markers) then
            result = true
        end
        if result then
            job.source.markers = job.markers
            changed = true
        end
        job.source.nextAllowed = self.discoveryClock + C.DISCOVERY_MIN_INTERVAL
        job.source.mapArtID = job.mapArtID
        if not job.pathOnly then
            job.source.nextRefresh = job.nextRefresh or self.discoveryClock + job.definition.interval
        end
        self.discoveryJob = nil
    until self.discoverySteps >= C.DISCOVERY_STEPS or debugprofilestop() >= self.discoveryDeadline
    if changed then
        self:RebuildMarkers()
    end
end
