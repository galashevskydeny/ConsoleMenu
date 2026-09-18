-- Sources.lua
-- Сборщики точек карты, заданий и выбранной цели.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Readable = Compass.Readable
local Number = Compass.Number
local ReadPosition = Compass.ReadPosition
local POI_RETRY_INTERVAL = 30
local QUEST_COMPLETE_ATLAS = "UI-QuestIcon-TurnIn-Normal"
local WORLD_QUEST_ATLAS = "Worldquest-icon"
local PREY_ATLAS = "worldquest-prey-crystal"
local PREY_TAG = Enum.QuestTagType and Enum.QuestTagType.Prey
local BONUS_OBJECTIVE_ATLAS = "Bonus-Objective-Star"
local THREAT_ATLAS = "worldquest-icon-nzoth"
local DIRECTIONS_ATLAS = "poi-traveldirections-arrow"
local DIG_SITE_ATLAS = "worldquest-icon-archaeology"
local PET_TAMER_ATLAS = "worldquest-icon-petbattle"
local CONTENT_ATLAS = "waypoint-mappin-minimap-untracked"
local POI_ICONS = "Interface/Minimap/POIIcons"
local VIGNETTE_KINDS = { vignettekill = "rare", vignettekillelite = "rareElite", vignettekillboss = "worldBoss" }
local NAVIGATION_RANK = { corpse = 1, selected = 2, directions = 3 }
local MAP_PIN_PREFIXES = {
    [Enum.SuperTrackingMapPinType.AreaPOI] = { "poi:", "mapLink:", "petTamer:" },
    [Enum.SuperTrackingMapPinType.QuestOffer] = { "offer:" },
    [Enum.SuperTrackingMapPinType.TaxiNode] = { "taxi:" },
    [Enum.SuperTrackingMapPinType.DigSite] = { "digSite:" },
}
local POI_GROUPS = {
    { query = C_AreaPoiInfo.GetEventsForMap, kind = "event" },
    { query = C_AreaPoiInfo.GetDragonridingRacesForMap, kind = "race" },
    -- Центры заданий только помечаются, чтобы не попасть на полосу из общего списка точек.
    { query = C_AreaPoiInfo.GetQuestHubsForMap, kind = "questHub", omit = true },
    { query = C_AreaPoiInfo.GetDelvesForMap, kind = "delve" },
    { query = C_AreaPoiInfo.GetAreaPOIForMap, kind = "poi" },
}
local OFFER_ATLASES = {
    [Enum.QuestClassification.Normal] = "QuestNormal",
    [Enum.QuestClassification.Questline] = "QuestNormal",
    [Enum.QuestClassification.Recurring] = "UI-QuestPoiRecurring-QuestBang",
    [Enum.QuestClassification.Meta] = "quest-wrapper-available",
    [Enum.QuestClassification.Calling] = "Quest-DailyCampaign-Available",
    [Enum.QuestClassification.Campaign] = "Quest-Campaign-Available",
    [Enum.QuestClassification.Legendary] = "UI-QuestPoiLegendary-QuestBang",
    [Enum.QuestClassification.Important] = "importantavailablequesticon",
}
-- Символы сдачи задания по классу, как на карте.
local COMPLETE_ATLASES = {
    [Enum.QuestClassification.Legendary] = "UI-QuestPoiLegendary-QuestBangTurnIn",
    [Enum.QuestClassification.Campaign] = "UI-QuestPoiCampaign-QuestBangTurnIn",
    [Enum.QuestClassification.Calling] = "UI-DailyQuestPoiCampaign-QuestBangTurnIn",
    [Enum.QuestClassification.Recurring] = "UI-QuestPoiRecurring-QuestBangTurnIn",
    [Enum.QuestClassification.Important] = "UI-QuestPoiImportant-QuestBangTurnIn",
    [Enum.QuestClassification.Meta] = "UI-QuestPoiWrapper-QuestBangTurnIn",
}

-- Текущее задание охоты, если игра его сообщает.
local function ActivePreyQuest()
    local getter = C_QuestLog.GetActivePreyQuest
    return getter and Number(getter())
end

-- Тип мирового задания из метки журнала или точки на карте.
local function WorldQuestType(questID, position)
    local tagInfo = Readable(C_QuestLog.GetQuestTagInfo(questID))
    local fromTag = tagInfo and Number(tagInfo.worldQuestType)
    if fromTag then
        return fromTag, tagInfo
    end
    return position and Number(position.questTagType), tagInfo
end

-- Мировое задание или охота, которые на карте рисуются особым символом.
local function IsWorldQuestPin(questID, worldQuestType)
    if Readable(C_QuestLog.IsWorldQuest(questID)) == true or worldQuestType then
        return true
    end
    local preyID = ActivePreyQuest()
    if preyID and preyID == questID then
        return true
    end
    return Number(C_QuestInfoSystem.GetQuestClassification(questID)) == Enum.QuestClassification.WorldQuest
end

-- Показатель карты пропускаем, кроме охоты и прочих мировых заданий.
local function SkipMapIndicator(info)
    if Readable(info.isMapIndicatorQuest) ~= true then
        return false
    end
    local id = Number(info.questID)
    if not id then
        return true
    end
    local worldQuestType = WorldQuestType(id, info)
    return not IsWorldQuestPin(id, worldQuestType)
end

-- Символ мирового задания, в том числе кристалл охоты.
local function WorldQuestPinArt(self, questID, tagInfo, worldQuestType)
    local atlas, innerWidth, innerHeight, underlayAtlas = WORLD_QUEST_ATLAS
    if not worldQuestType and PREY_TAG and ActivePreyQuest() == questID then
        worldQuestType = PREY_TAG
    end
    local info = tagInfo
    if worldQuestType and (not info or Number(info.worldQuestType) ~= worldQuestType) then
        info = {
            worldQuestType = worldQuestType,
            isElite = info and info.isElite,
            tradeskillLineID = info and info.tradeskillLineID,
            quality = info and info.quality,
        }
    end
    if info and QuestUtil and QuestUtil.GetWorldQuestAtlasInfo then
        local worldAtlas, worldWidth, worldHeight = QuestUtil.GetWorldQuestAtlasInfo(questID, info, false)
        worldAtlas = Readable(worldAtlas)
        if type(worldAtlas) == "string" and worldAtlas ~= "" then
            atlas = worldAtlas
        end
        worldWidth, worldHeight = Number(worldWidth), Number(worldHeight)
        if worldWidth and worldHeight and worldWidth > 0 and worldHeight > 0 then
            innerWidth, innerHeight = worldWidth, worldHeight
        end
        if Readable(info.isElite) == true then
            underlayAtlas = self.Constants.ELITE_WORLD_QUEST_UNDERLAY
        end
    elseif PREY_TAG and worldQuestType == PREY_TAG then
        atlas = PREY_ATLAS
        innerWidth, innerHeight = self.AtlasSize(PREY_ATLAS)
    end
    return atlas, innerWidth, innerHeight, underlayAtlas
end

-- Интервал повторного опроса точки интереса.
local function POIRefreshInterval(id)
    local timed = Readable(C_AreaPoiInfo.IsAreaPOITimed(id))
    if timed == false then
        return math.huge
    end
    local seconds = timed == true and Number(C_AreaPoiInfo.GetAreaPOISecondsLeft(id))
    return seconds and seconds > 0 and seconds or POI_RETRY_INTERVAL
end

-- Определяет тип особой метки по атласу.
local function VignetteKind(info)
    local atlas = Readable(info.atlasName)
    atlas = type(atlas) == "string" and atlas:lower() or ""
    if Number(info.type) == Enum.VignetteType.Treasure or atlas:find("^vignetteloot") then
        return "treasure"
    end
    return VIGNETTE_KINDS[atlas] or "poi"
end

-- Возвращает символ события, как на карте.
local function EventPinAtlas(info)
    local C = Compass.Constants
    if Readable(info.isCurrentEvent) ~= true then
        return C.EVENT_PIN_ATLAS
    end
    local atlas = Readable(info.atlasName)
    if atlas == "minimap-genericevent-hornicon" then
        return C.EVENT_PIN_ATLAS
    end
    if type(atlas) == "string" and atlas ~= "" then
        return atlas
    end
end

-- Ставит событию пышный круг и уменьшенный символ, как на карте.
local function ApplyEventPinArt(self, marker)
    local C = self.Constants
    local innerWidth, innerHeight = self.AtlasSize(marker.atlas)
    local scale = C.EVENT_PIN_ICON_SCALE
    self:ApplyQuestPinArt(
        marker,
        marker.atlas,
        C.EVENT_PIN_BACKGROUND,
        nil,
        innerWidth * scale,
        innerHeight * scale,
        C.EVENT_PIN_BACKGROUND_FOCUSED
    )
end

-- Собирает точки интереса, события, гонки, вылазки и входы. Центры заданий отбрасываются.
function Compass:CollectMapPoints(markers)
    local C = self.Constants
    local seen, refreshAt = {}, math.huge
    for _, group in ipairs(POI_GROUPS) do
        local ids = Readable(group.query(self.mapID))
        if type(ids) ~= "table" then
            ids = nil
            refreshAt = math.min(refreshAt, self.discoveryClock + POI_RETRY_INTERVAL)
        end
        self:DiscoveryCheckpoint()
        for _, id in ipairs(ids or {}) do
            id = Number(id)
            if not id then
                refreshAt = math.min(refreshAt, self.discoveryClock + POI_RETRY_INTERVAL)
            elseif not seen[id] then
                seen[id] = true
                if not group.omit then
                    local info = Readable(C_AreaPoiInfo.GetAreaPOIInfo(self.mapID, id))
                    local marker
                    if type(info) == "table" then
                        local atlas = info.atlasName
                        local eventAtlas
                        if group.kind == "event" then
                            eventAtlas = EventPinAtlas(info)
                            atlas = eventAtlas
                        end
                        marker = self:AddMarker(
                            markers,
                            "poi:" .. id,
                            info.position,
                            info.name,
                            atlas,
                            C.POI_PRIORITY,
                            group.kind
                        )
                        if marker and eventAtlas then
                            ApplyEventPinArt(self, marker)
                        end
                    end
                    local interval = marker and POIRefreshInterval(id) or POI_RETRY_INTERVAL
                    refreshAt = math.min(refreshAt, self.discoveryClock + interval)
                end
            end
            self:DiscoveryCheckpoint()
        end
    end
    local entrances = Readable(C_EncounterJournal.GetDungeonEntrancesForMap(self.mapID))
    if type(entrances) ~= "table" then
        entrances = nil
        refreshAt = math.min(refreshAt, self.discoveryClock + POI_RETRY_INTERVAL)
    end
    self:DiscoveryCheckpoint()
    for _, info in ipairs(entrances or {}) do
        info = Readable(info)
        local id = type(info) == "table" and Number(info.areaPoiID)
        if not id then
            refreshAt = math.min(refreshAt, self.discoveryClock + POI_RETRY_INTERVAL)
        elseif not seen[id] then
            seen[id] = true
            local marker = self:AddMarker(
                markers,
                "poi:" .. id,
                info.position,
                info.name,
                info.atlasName,
                C.POI_PRIORITY,
                "poi"
            )
            if not marker then
                refreshAt = math.min(refreshAt, self.discoveryClock + POI_RETRY_INTERVAL)
            end
        end
        self:DiscoveryCheckpoint()
    end
    if refreshAt < math.huge then
        return math.max(self.Constants.DISCOVERY_MIN_INTERVAL, refreshAt - self.discoveryClock)
    end
end

-- Собирает редких существ и сокровища.
function Compass:CollectVignettes(markers)
    local C = self.Constants
    local ids = Readable(C_VignetteInfo.GetVignettes())
    self:DiscoveryCheckpoint()
    for _, id in ipairs(ids or {}) do
        id = Readable(id)
        local info = id and Readable(C_VignetteInfo.GetVignetteInfo(id))
        if
            info
            and Readable(info.isDead) == false
            and Readable(info.inFogOfWar) == false
            and (Readable(info.onWorldMap) == true or Readable(info.onMinimap) == true)
        then
            local position = C_VignetteInfo.GetVignettePosition(id, self.mapID)
            self:AddMarker(
                markers,
                "vignette:" .. id,
                position,
                info.name,
                info.atlasName,
                C.VIGNETTE_PRIORITY,
                VignetteKind(info)
            )
        end
        self:DiscoveryCheckpoint()
    end
end

-- Добавляет одно задание на полосу.
local function AddQuest(self, markers, questID, position, watched, seen, taskOnly)
    local C = self.Constants
    if not questID or questID <= 0 or seen[questID] then
        return
    end
    local x, y = ReadPosition(position)
    if not x or not y then
        return
    end
    local worldQuestType, tagInfo = WorldQuestType(questID, position)
    local isWorldPin = IsWorldQuestPin(questID, worldQuestType)
    local isActiveTask = Readable(C_TaskQuest.IsActive(questID)) == true
    local onQuest = Readable(C_QuestLog.IsOnQuest(questID)) == true
    local title, atlas, priority, kind
    local backgroundAtlas, focusedBackground, underlayAtlas, innerWidth, innerHeight
    local markerProgress, markerComplete, markerClassification
    if isWorldPin and (isActiveTask or (not taskOnly and onQuest)) then
        title = C_TaskQuest.GetQuestInfoByQuestID(questID) or C_QuestLog.GetTitleForQuestID(questID)
        atlas, innerWidth, innerHeight, underlayAtlas = WorldQuestPinArt(self, questID, tagInfo, worldQuestType)
        priority, kind = C.WORLD_QUEST_PRIORITY, "worldQuest"
        backgroundAtlas = C.QUEST_PIN_BACKGROUND
        focusedBackground = C.QUEST_PIN_BACKGROUND_FOCUSED
    elseif not isWorldPin then
        local classification = Number(C_QuestInfoSystem.GetQuestClassification(questID))
        if
            classification == Enum.QuestClassification.BonusObjective
            or classification == Enum.QuestClassification.Threat
        then
            if Readable(C_TaskQuest.IsActive(questID)) ~= true then
                return
            end
            if
                taskOnly
                and (
                    Number(position.mapID) ~= self.mapID
                    or (Readable(position.isQuestStart) == true and Readable(position.inProgress) == true)
                )
            then
                return
            end
            title = C_TaskQuest.GetQuestInfoByQuestID(questID)
            if classification == Enum.QuestClassification.BonusObjective then
                atlas = BONUS_OBJECTIVE_ATLAS
                backgroundAtlas = C.BONUS_OBJECTIVE_BACKGROUND
                focusedBackground = C.BONUS_OBJECTIVE_BACKGROUND_FOCUSED
            else
                local theme = Readable(C_QuestLog.GetQuestDetailsTheme(questID))
                atlas = theme and Readable(theme.poiIcon) or THREAT_ATLAS
                backgroundAtlas = C.QUEST_PIN_BACKGROUND
                focusedBackground = C.QUEST_PIN_BACKGROUND_FOCUSED
            end
        elseif not taskOnly and Readable(C_QuestLog.IsOnQuest(questID)) == true then
            title = C_QuestLog.GetTitleForQuestID(questID)
            backgroundAtlas = Compass.QuestPinBackground(classification)
            focusedBackground = Compass.QuestPinBackgroundFocused(classification)
            markerClassification = classification
            if Readable(C_QuestLog.IsComplete(questID)) == true then
                atlas = COMPLETE_ATLASES[classification] or QUEST_COMPLETE_ATLAS
                markerComplete = true
            else
                atlas = C.QUEST_PROGRESS_ATLAS
                markerProgress = true
            end
        else
            return
        end
        priority = C.QUEST_PRIORITY
        kind = "quest"
    else
        return
    end
    if watched[questID] then
        priority = C.TRACKED_QUEST_PRIORITY
    end
    local marker = self:AddMarker(markers, "quest:" .. questID, position, title, atlas, priority, kind)
    if marker then
        marker.questID = questID
        marker.questProgress = markerProgress
        marker.questComplete = markerComplete
        marker.questClassification = markerClassification
        self:ApplyQuestPinArt(marker, atlas, backgroundAtlas, underlayAtlas, innerWidth, innerHeight, focusedBackground)
        if markerProgress then
            marker.iconWidthFocused, marker.iconHeightFocused = self.AtlasSize(C.QUEST_PROGRESS_FOCUSED_ATLAS)
        end
        seen[questID] = true
    end
end

-- Добавляет следующую путевую точку задания.
local function AddQuestWaypoint(self, markers, questID, watched, seen)
    local x, y = C_QuestLog.GetNextWaypointForMap(questID, self.mapID)
    AddQuest(self, markers, questID, { x = x, y = y }, watched, seen)
end

-- Собирает цели заданий и локальные задания.
function Compass:CollectQuests(markers)
    local watched, seen = {}, {}
    for index = 1, Number(C_QuestLog.GetNumQuestWatches()) or 0 do
        local id = Number(C_QuestLog.GetQuestIDForQuestWatchIndex(index))
        if id then
            watched[id] = true
        end
        self:DiscoveryCheckpoint()
    end
    for index = 1, Number(C_QuestLog.GetNumWorldQuestWatches()) or 0 do
        local id = Number(C_QuestLog.GetQuestIDForWorldQuestWatchIndex(index))
        if id then
            watched[id] = true
        end
        self:DiscoveryCheckpoint()
    end
    local superTracked = Number(C_SuperTrack.GetSuperTrackedQuestID())
    if superTracked and superTracked > 0 then
        watched[superTracked] = true
    end
    for id in pairs(watched) do
        AddQuestWaypoint(self, markers, id, watched, seen)
        self:DiscoveryCheckpoint()
    end
    local quests = Readable(C_QuestLog.GetQuestsOnMap(self.mapID))
    self:DiscoveryCheckpoint()
    for _, info in ipairs(quests or {}) do
        info = Readable(info)
        if info and Readable(info.isQuestStart) == false and not SkipMapIndicator(info) then
            AddQuest(self, markers, Number(info.questID), info, watched, seen)
        end
        self:DiscoveryCheckpoint()
    end
    quests = Readable(C_TaskQuest.GetQuestsOnMap(self.mapID))
    self:DiscoveryCheckpoint()
    for _, info in ipairs(quests or {}) do
        info = Readable(info)
        if info then
            AddQuest(self, markers, Number(info.questID), info, watched, seen, true)
        end
        self:DiscoveryCheckpoint()
    end
end

-- Запасной поиск пути выбранного задания на карте.
local function CollectQuestPathFallback(self, markers, questID, watched, seen)
    local quests = Readable(C_QuestLog.GetQuestsOnMap(self.mapID))
    self:DiscoveryCheckpoint()
    for _, info in ipairs(quests or {}) do
        info = Readable(info)
        if
            info
            and Number(info.questID) == questID
            and Readable(info.isQuestStart) == false
            and not SkipMapIndicator(info)
        then
            AddQuest(self, markers, questID, info, watched, seen)
            if seen[questID] then
                return
            end
        end
        self:DiscoveryCheckpoint()
    end
    quests = Readable(C_TaskQuest.GetQuestsOnMap(self.mapID))
    self:DiscoveryCheckpoint()
    for _, info in ipairs(quests or {}) do
        info = Readable(info)
        if info and Number(info.questID) == questID then
            AddQuest(self, markers, questID, info, watched, seen, true)
            if seen[questID] then
                return
            end
        end
        self:DiscoveryCheckpoint()
    end
end

-- Обновляет только путь выбранного задания.
function Compass:RefreshQuestPath(markers)
    local tracking = Number(C_SuperTrack.GetHighestPrioritySuperTrackingType())
    local questID = tracking == Enum.SuperTrackingType.Quest and Number(C_SuperTrack.GetSuperTrackedQuestID())
    local key, replacement
    if questID and questID > 0 then
        key = "quest:" .. questID
        local candidates, watched, seen = {}, { [questID] = true }, {}
        AddQuestWaypoint(self, candidates, questID, watched, seen)
        self:DiscoveryCheckpoint()
        if not seen[questID] then
            CollectQuestPathFallback(self, candidates, questID, watched, seen)
        end
        replacement = candidates[1]
    end
    local found = false
    for _, marker in ipairs(self.compassSources.quests.markers) do
        if marker.key == key then
            found = true
            if replacement then
                markers[#markers + 1] = replacement
            end
        else
            markers[#markers + 1] = marker
        end
        self:DiscoveryCheckpoint()
    end
    if replacement and not found then
        markers[#markers + 1] = replacement
    end
end

-- Собирает дружественных мастеров полёта.
function Compass:CollectFlightMasters(markers)
    local C = self.Constants
    local faction = Readable(UnitFactionGroup("player"))
    local nodes = Readable(C_TaxiMap.GetTaxiNodesForMap(self.mapID))
    self:DiscoveryCheckpoint()
    for _, node in ipairs(nodes or {}) do
        node = Readable(node)
        if node then
            local id, side = Number(node.nodeID), Number(node.faction)
            local friendly = side == Enum.FlightPathFaction.Neutral
                or (side == Enum.FlightPathFaction.Alliance and faction == "Alliance")
                or (side == Enum.FlightPathFaction.Horde and faction == "Horde")
            if id and friendly then
                self:AddMarker(
                    markers,
                    "taxi:" .. id,
                    node.position,
                    node.name,
                    node.atlasName,
                    C.POI_PRIORITY,
                    "flightMaster"
                )
            end
        end
        self:DiscoveryCheckpoint()
    end
end

-- Собирает однотипные записи карты с идентификатором.
local function CollectMapRecords(self, markers, records, idField, kind, fallbackAtlas)
    local C = self.Constants
    records = Readable(records)
    self:DiscoveryCheckpoint()
    local seen = {}
    for _, info in ipairs(records or {}) do
        info = Readable(info)
        local id = info and Number(info[idField])
        if id and not seen[id] and Compass.IsMapPosition(info.position) then
            local atlas = Readable(info.atlasName) or fallbackAtlas
            if self:AddMarker(markers, kind .. ":" .. id, info.position, info.name, atlas, C.POI_PRIORITY, kind) then
                seen[id] = true
            end
        end
        self:DiscoveryCheckpoint()
    end
end

-- Собирает указание стражника.
function Compass:CollectDirections(markers)
    local C = self.Constants
    local id = Number(C_GossipInfo.GetPoiForUiMapID(self.mapID))
    self:DiscoveryCheckpoint()
    if id then
        local info = Readable(C_GossipInfo.GetPoiInfo(self.mapID, id))
        if info and Compass.IsMapPosition(info.position) then
            self:AddMarker(
                markers,
                "directions:" .. id,
                info.position,
                info.name,
                DIRECTIONS_ATLAS,
                C.TRACKED_QUEST_PRIORITY,
                "directions"
            )
        end
        self:DiscoveryCheckpoint()
    end
end

-- Собирает переходы между картами.
function Compass:CollectMapLinks(markers)
    CollectMapRecords(self, markers, C_Map.GetMapLinksForMap(self.mapID), "areaPoiID", "mapLink")
end

-- Собирает укротителей, если включено отслеживание питомцев.
function Compass:CollectPetTamers(markers)
    if Readable(C_Minimap.CanTrackBattlePets()) == true then
        CollectMapRecords(
            self,
            markers,
            C_PetInfo.GetPetTamersForMap(self.mapID),
            "areaPoiID",
            "petTamer",
            PET_TAMER_ATLAS
        )
    end
end

-- Собирает места раскопок.
function Compass:CollectDigSites(markers)
    CollectMapRecords(
        self,
        markers,
        C_ResearchInfo.GetDigSitesForMap(self.mapID),
        "researchSiteID",
        "digSite",
        DIG_SITE_ATLAS
    )
end

-- Собирает отслеживаемые предметы коллекции.
function Compass:CollectTrackedContent(markers)
    local C = self.Constants
    if Readable(C_ContentTracking.GetCollectableSourceTrackingEnabled()) ~= true then
        return
    end
    local types = Readable(C_ContentTracking.GetCollectableSourceTypes())
    self:DiscoveryCheckpoint()
    local seen, titles = {}, {}
    for _, trackableType in ipairs(types or {}) do
        trackableType = Number(trackableType)
        if trackableType then
            local _, records = C_ContentTracking.GetTrackablesOnMap(trackableType, self.mapID)
            records = Readable(records)
            self:DiscoveryCheckpoint()
            for _, info in ipairs(records or {}) do
                info = Readable(info)
                local id = info and Number(info.trackableID)
                local targetType = info and Number(info.targetType)
                local targetID = info and Number(info.targetID)
                if
                    id
                    and targetType
                    and targetID
                    and Number(info.trackableType) == trackableType
                    and Compass.IsMapPosition(info)
                then
                    local titleKey = trackableType .. ":" .. id
                    local key = "content:" .. titleKey .. ":" .. targetType .. ":" .. targetID
                    if not seen[key] then
                        local title = titles[titleKey]
                        if title == nil then
                            title = Readable(C_ContentTracking.GetTitle(trackableType, id))
                            titles[titleKey] = title or false
                        end
                        if
                            self:AddMarker(
                                markers,
                                key,
                                info,
                                title,
                                CONTENT_ATLAS,
                                C.TRACKED_QUEST_PRIORITY,
                                "content"
                            )
                        then
                            seen[key] = true
                        end
                    end
                end
                self:DiscoveryCheckpoint()
            end
        end
        self:DiscoveryCheckpoint()
    end
end

-- Проверяет, начинается ли задание на текущей или дочерней карте.
local function StartsOnMap(self, startMapID, cache)
    if cache[startMapID] ~= nil then
        return cache[startMapID]
    end
    local mapID, visited = startMapID, {}
    while mapID and mapID > 0 and mapID ~= self.mapID and not visited[mapID] do
        visited[mapID] = true
        local mapInfo = Readable(C_Map.GetMapInfo(mapID))
        mapID = mapInfo and Number(mapInfo.parentMapID)
        self:DiscoveryCheckpoint()
    end
    local matches = mapID == self.mapID
    cache[startMapID] = matches
    return matches
end

-- Добавляет доступное задание, если оно видно на карте.
local function AddOffer(self, markers, info, seen, mapCache, showHidden, showCompleted)
    local C = self.Constants
    info = Readable(info)
    local id = info and Number(info.questID)
    if not id or id <= 0 or seen[id] then
        return
    end
    local atlas = OFFER_ATLASES[Number(C_QuestInfoSystem.GetQuestClassification(id))]
    if not atlas then
        return
    end
    seen[id] = true
    local startMapID = Number(info.startMapID)
    if not startMapID or Readable(info.inProgress) ~= false or not Compass.IsMapPosition(info) then
        return
    end
    local hidden = Readable(info.isHidden)
    if hidden == nil or (hidden and not showHidden) or not StartsOnMap(self, startMapID, mapCache) then
        return
    end
    local completed = Readable(info.isAccountCompleted)
    if completed == nil then
        return
    end
    if completed and not showCompleted then
        local lineID = Number(info.questLineID)
        local lineIgnores = lineID
            and Readable(C_QuestLine.QuestLineIgnoresAccountCompletedFiltering(self.mapID, lineID)) == true
        if not lineIgnores and Readable(C_QuestLog.QuestIgnoresAccountCompletedFiltering(id)) ~= true then
            return
        end
    end
    self:AddMarker(markers, "offer:" .. id, info, info.questName, atlas, C.QUEST_PRIORITY, "questOffer")
end

-- Собирает доступные задания на карте.
function Compass:CollectQuestOffers(markers)
    if self.compassOfferMapID ~= self.mapID or self.compassOfferRequestRequired then
        self.compassOfferMapID, self.compassOfferRequestRequired = self.mapID, false
        C_QuestLine.RequestQuestLinesForMap(self.mapID)
        self:DiscoveryCheckpoint()
    end
    local showHidden = Readable(C_Minimap.IsTrackingHiddenQuests()) == true
    local showCompleted = Readable(C_Minimap.IsTrackingAccountCompletedQuests()) == true
    local seen, mapCache = {}, {}
    local offers = Readable(C_QuestLine.GetAvailableQuestLines(self.mapID))
    self:DiscoveryCheckpoint()
    for _, info in ipairs(offers or {}) do
        AddOffer(self, markers, info, seen, mapCache, showHidden, showCompleted)
        self:DiscoveryCheckpoint()
    end
    local forced = Readable(C_QuestLine.GetForceVisibleQuests(self.mapID))
    self:DiscoveryCheckpoint()
    for _, id in ipairs(forced or {}) do
        id = Number(id)
        if id and not seen[id] then
            AddOffer(
                self,
                markers,
                C_QuestLine.GetQuestLineInfo(id, self.mapID),
                seen,
                mapCache,
                showHidden,
                showCompleted
            )
        end
        self:DiscoveryCheckpoint()
    end
    local tasks = Readable(C_TaskQuest.GetQuestsOnMap(self.mapID))
    self:DiscoveryCheckpoint()
    for _, info in ipairs(tasks or {}) do
        info = Readable(info)
        local id = info and Number(info.questID)
        if id and id > 0 and not seen[id] and Readable(info.inProgress) == false then
            local offer = {
                questID = id,
                startMapID = self.mapID,
                x = info.x,
                y = info.y,
                inProgress = false,
                questName = C_TaskQuest.GetQuestInfoByQuestID(id),
                isHidden = C_QuestLog.IsQuestTrivial(id),
                isAccountCompleted = C_QuestLog.IsQuestFlaggedCompletedOnAccount(id),
            }
            AddOffer(self, markers, offer, seen, mapCache, showHidden, showCompleted)
        end
        self:DiscoveryCheckpoint()
    end
end

-- Назначает значку текстуру точки интереса с карты.
local function ApplyPOITexture(marker, textureIndex)
    textureIndex = Number(textureIndex)
    if not marker or not textureIndex then
        return
    end
    local left, right, top, bottom = C_Minimap.GetPOITextureCoords(textureIndex)
    left, right, top, bottom = Number(left), Number(right), Number(top), Number(bottom)
    if left and right and top and bottom then
        marker.texture = POI_ICONS
        marker.texLeft, marker.texRight, marker.texTop, marker.texBottom = left, right, top, bottom
        Compass:UseTextureSize(marker)
    end
end

-- Собирает кладбища, пока персонаж призрак.
function Compass:CollectGraveyards(markers)
    local C = self.Constants
    local graveyards = Readable(C_DeathInfo.GetGraveyardsForMap(self.mapID))
    local preferred = Number(GetCemeteryPreference())
    self:DiscoveryCheckpoint()
    for _, info in ipairs(graveyards or {}) do
        info = Readable(info)
        local id = info and Number(info.graveyardID)
        local areaPoiID = info and Number(info.areaPoiID)
        if id and Compass.IsMapPosition(info.position) then
            local poi = areaPoiID and Readable(C_AreaPoiInfo.GetAreaPOIInfo(self.mapID, areaPoiID))
            local atlas = poi and Readable(poi.atlasName)
            local priority = id == preferred and C.TRACKED_QUEST_PRIORITY or C.POI_PRIORITY
            local marker = self:AddMarker(
                markers,
                "graveyard:" .. id,
                info.position,
                info.name,
                atlas,
                priority,
                "graveyard"
            )
            if marker and not atlas then
                ApplyPOITexture(marker, info.textureIndex)
            end
        end
        self:DiscoveryCheckpoint()
    end
end

-- Собирает положение тела, если персонаж призрак.
function Compass:CollectCorpse(markers)
    local C = self.Constants
    if Readable(UnitIsGhost("player")) ~= true then
        return
    end
    local position = Readable(C_DeathInfo.GetCorpseMapPosition(self.mapID))
    if Compass.IsMapPosition(position) then
        self:AddMarker(
            markers,
            "corpse",
            position,
            self.L.CORPSE,
            C.FALLBACK_ATLAS,
            C.TRACKED_QUEST_PRIORITY,
            "corpse"
        )
    end
    self:CollectGraveyards(markers)
end

-- Переносит мировые координаты юнита на текущую карту относительно игрока.
local function UnitMapPosition(self, unit)
    local position = Readable(C_Map.GetPlayerMapPosition(self.mapID, unit))
    if Compass.IsMapPosition(position) then
        return position
    end
    local north, west, _, instance = UnitPosition(unit)
    local playerNorth, playerWest, _, playerInstance = UnitPosition("player")
    north, west, instance = Number(north), Number(west), Number(instance)
    playerNorth, playerWest, playerInstance = Number(playerNorth), Number(playerWest), Number(playerInstance)
    if not north or not west or not playerNorth or not playerWest or instance ~= playerInstance then
        return
    end
    local playerX, playerY = ReadPosition(C_Map.GetPlayerMapPosition(self.mapID, "player"))
    if not playerX or not playerY then
        return
    end
    position = {
        x = playerX - (west - playerWest) / self.mapWidth,
        y = playerY - (north - playerNorth) / self.mapHeight,
    }
    if Compass.IsMapPosition(position) then
        return position
    end
end

-- Собирает участников группы на текущей карте.
function Compass:CollectGroupMembers(markers)
    local C = self.Constants
    if Readable(IsInGroup()) ~= true then
        return
    end
    local hideIcons = Readable(C_Map.GetMapDisplayInfo(self.mapID))
    if hideIcons == true then
        return
    end
    local prefix, count
    if Readable(IsInRaid()) == true then
        prefix, count = "raid", Number(GetNumGroupMembers()) or 0
    else
        prefix, count = "party", Number(GetNumSubgroupMembers()) or 0
    end
    self:DiscoveryCheckpoint()
    for index = 1, count do
        local unit = prefix .. index
        if
            Readable(UnitExists(unit)) == true
            and Readable(UnitIsUnit(unit, "player")) ~= true
            and Readable(UnitIsConnected(unit)) == true
            and not Readable(UnitPhaseReason(unit))
        then
            local guid = Readable(UnitGUID(unit))
            local name = Readable(GetUnitName(unit, true)) or Readable(UnitName(unit))
            local _, classFile = UnitClass(unit)
            classFile = Readable(classFile)
            local atlas = classFile and Readable(GetClassAtlas(classFile))
            if type(guid) == "string" and type(name) == "string" and name ~= "" then
                local position = UnitMapPosition(self, unit)
                if position then
                    self:AddMarker(markers, "party:" .. guid, position, name, atlas, C.TRACKED_QUEST_PRIORITY, "party")
                end
            end
        end
        self:DiscoveryCheckpoint()
    end
end

-- Собирает флаги и технику поля боя.
function Compass:CollectBattlefield(markers)
    local C = self.Constants
    local flagCount = Number(GetNumBattlefieldFlagPositions()) or 0
    self:DiscoveryCheckpoint()
    for index = 1, flagCount do
        local x, y, texture = C_PvP.GetBattlefieldFlagPosition(index, self.mapID)
        x, y, texture = Number(x), Number(y), Readable(texture)
        if Compass.IsMapPosition({ x = x, y = y }) then
            local marker = self:AddMarker(
                markers,
                "flag:" .. index,
                { x = x, y = y },
                self.L.FLAG,
                C.FALLBACK_ATLAS,
                C.TRACKED_QUEST_PRIORITY,
                "flag"
            )
            if marker and texture then
                marker.texture = texture
                self:UseTextureSize(marker)
            end
        end
        self:DiscoveryCheckpoint()
    end
    local mapInfo = Readable(C_Map.GetMapInfo(self.mapID))
    local mapType = mapInfo and Number(mapInfo.mapType)
    if mapType and mapType < Enum.UIMapType.Zone then
        return
    end
    local vehicles = Readable(C_PvP.GetBattlefieldVehicles(self.mapID))
    self:DiscoveryCheckpoint()
    for index, info in ipairs(vehicles or {}) do
        info = Readable(info)
        if
            info
            and Readable(info.isAlive) == true
            and Readable(info.isPlayer) ~= true
            and Compass.IsMapPosition(info)
        then
            self:AddMarker(
                markers,
                "vehicle:" .. index,
                info,
                info.name,
                info.atlas,
                C.TRACKED_QUEST_PRIORITY,
                "vehicle"
            )
        end
        self:DiscoveryCheckpoint()
    end
end

-- Возвращает ключи выбранной игрой цели.
local function NativeSelection()
    local tracking = C_SuperTrack.GetHighestPrioritySuperTrackingType()
    if Compass.IsSecret(tracking) then
        return {}
    end
    tracking = Number(tracking)
    if tracking == Enum.SuperTrackingType.Quest then
        local id = Number(C_SuperTrack.GetSuperTrackedQuestID())
        return id and { "quest:" .. id } or {}
    elseif tracking == Enum.SuperTrackingType.Content then
        local contentType, id = C_SuperTrack.GetSuperTrackedContent()
        contentType, id = Number(contentType), Number(id)
        return contentType and id and { "content:" .. contentType .. ":" .. id .. ":" } or {}, true
    elseif tracking == Enum.SuperTrackingType.MapPin then
        local pinType, id = C_SuperTrack.GetSuperTrackedMapPin()
        pinType, id = Number(pinType), Number(id)
        local prefixes = pinType and MAP_PIN_PREFIXES[pinType]
        if prefixes and id then
            local keys = {}
            for _, prefix in ipairs(prefixes) do
                keys[#keys + 1] = prefix .. id
            end
            return keys
        end
        return {}
    elseif tracking == Enum.SuperTrackingType.Vignette then
        local guid = Readable(C_SuperTrack.GetSuperTrackedVignette())
        if type(guid) == "string" then
            return { "vignette:" .. guid }
        end
        return {}
    elseif tracking == Enum.SuperTrackingType.PartyMember then
        local unit = Readable(C_Navigation.GetNearestPartyMemberToken())
        local guid = type(unit) == "string" and unit ~= "" and Readable(UnitGUID(unit))
        return type(guid) == "string" and { "party:" .. guid } or {}
    elseif tracking and tracking ~= Enum.SuperTrackingType.UserWaypoint then
        return {}
    end
end

-- Отмечает на полосе выбранную цель: тело, отслеживание, путевую точку или указание.
function Compass:SelectNavigation()
    local keys, prefix = NativeSelection()
    local selectionID = keys and (keys[1] or "unavailable")
    if self.nativeNavigationID ~= selectionID then
        self.nativeNavigationID = selectionID
        self.dismissedNavigationKey = nil
    end
    local x, y, positionRead
    local target, bestRank, bestDistance
    for _, marker in ipairs(self.markers) do
        marker.navigation = false
        local rank
        if marker.kind == "corpse" then
            rank = NAVIGATION_RANK.corpse
        elseif marker.key == "waypoint" and not keys then
            rank = NAVIGATION_RANK.selected
        elseif keys then
            for _, key in ipairs(keys) do
                if marker.key == key or (prefix and marker.key:sub(1, #key) == key) then
                    rank = NAVIGATION_RANK.selected
                    break
                end
            end
        end
        if not rank and not keys and marker.kind == "directions" then
            rank = NAVIGATION_RANK.directions
        end
        if rank and marker.key ~= self.dismissedNavigationKey then
            if not positionRead then
                x, y = ReadPosition(C_Map.GetPlayerMapPosition(self.mapID, "player"))
                positionRead = true
            end
            local distance = x and y and ((marker.x - x) * self.mapWidth) ^ 2 + ((marker.y - y) * self.mapHeight) ^ 2
                or 0
            if
                not target
                or rank < bestRank
                or (
                    rank == bestRank
                    and (distance < bestDistance or (distance == bestDistance and marker.key < target.key))
                )
            then
                target, bestRank, bestDistance = marker, rank, distance
            end
        end
    end
    self.navigationKey = target and target.key
    if target then
        target.navigation = true
    end
end
