-- Frame.lua
-- Создание полосы, события, показ и цикл обновления.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass

-- События, по которым пересобираются точки карты.
local EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED",
    "ZONE_CHANGED_INDOORS",
    "ZONE_CHANGED_NEW_AREA",
    "AREA_POIS_UPDATED",
    "USER_WAYPOINT_UPDATED",
    "VIGNETTES_UPDATED",
    "VIGNETTE_MINIMAP_UPDATED",
    "QUEST_LOG_UPDATE",
    "QUEST_WATCH_LIST_CHANGED",
    "QUEST_POI_UPDATE",
    "QUEST_DATA_LOAD_RESULT",
    "SUPER_TRACKING_CHANGED",
    "WORLD_QUEST_COMPLETED_BY_SPELL",
    "TAXI_NODE_STATUS_CHANGED",
    "UI_SCALE_CHANGED",
    "DISPLAY_SIZE_CHANGED",
    "DYNAMIC_GOSSIP_POI_UPDATED",
    "SPELLS_CHANGED",
    "RESEARCH_ARTIFACT_DIG_SITE_UPDATED",
    "ARTIFACT_DIGSITE_COMPLETE",
    "CONTENT_TRACKING_UPDATE",
    "CONTENT_TRACKING_LIST_UPDATE",
    "CONTENT_TRACKING_IS_ENABLED_UPDATE",
    "TRACKABLE_INFO_UPDATE",
    "TRACKING_TARGET_INFO_UPDATE",
    "QUESTLINE_UPDATE",
    "MINIMAP_UPDATE_TRACKING",
    "QUEST_ACCEPTED",
    "QUEST_TURNED_IN",
    "PLAYER_DEAD",
    "PLAYER_ALIVE",
    "PLAYER_UNGHOST",
    "CORPSE_IN_RANGE",
    "CORPSE_OUT_OF_RANGE",
    "CEMETERY_PREFERENCE_UPDATED",
    "REQUEST_CEMETERY_LIST_RESPONSE",
    "GROUP_ROSTER_UPDATE",
    "PVP_VEHICLE_INFO_UPDATED",
    "ARENA_OPPONENT_UPDATE",
    "SUPER_TRACKING_PATH_UPDATED",
    "MODIFIER_STATE_CHANGED",
    "CVAR_UPDATE",
    "NAVIGATION_FRAME_CREATED",
    "NAVIGATION_FRAME_DESTROYED",
}

-- Смещает полосу вниз при включённом вырезе экрана.
local function DefaultOffsetY()
    local C = Compass.Constants
    local offset = C.DEFAULT_Y
    if ConsoleMenuDB and ConsoleMenuDB.enableMacBook == 1 then
        offset = offset - C.MACBOOK_OFFSET
    end
    return offset
end

-- Возвращает истину, пока рамка полосы проявляется.
function Compass:IsFadeInPlaying()
    local fadeIn = self.frame and self.frame.fadeIn
    return fadeIn and fadeIn:IsPlaying() and true or false
end

-- После проявления рамки возвращает прозрачность дочерних элементов.
local function RestoreAfterFadeIn(self)
    local fadeIn = self.frame and self.frame.fadeIn
    if fadeIn then
        fadeIn:SetScript("OnFinished", nil)
    end
    self:RestoreViewAlpha()
end

-- Показывает или скрывает полосу с учётом подземелья, поля боя и окон.
function Compass:RefreshVisibility()
    local hidden = self.inInstance or self.hiddenByGame or self.hiddenByContext or self.hiddenByProgress
    if hidden then
        if self.updating then
            self.events:SetScript("OnUpdate", nil)
            self.updating = false
        end
        if self.frame and self.frame.fadeIn then
            self.frame.fadeIn:SetScript("OnFinished", nil)
        end
        self:ClearMarkers()
        self.navigationTarget = nil
        self:InitializeDiscovery()
        wipe(self.markers)
        wipe(self.bearings)
        if self.frame then
            ConsoleMenu:AnimatedHide(self.frame)
            if self.inInstance or self.hiddenByGame then
                if self.frame.fadeOut then
                    self.frame.fadeOut:Stop()
                    self.frame.fadeOut:SetScript("OnFinished", nil)
                end
                self.frame:Hide()
            end
        end
        return
    end
    if self.frame then
        ConsoleMenu:AnimatedShow(self.frame)
        self.discoveryDirty = true
        self.sortElapsed = 0
        self.renderDirty = true
        self.selectionDirty = true
        self.markerSlotsDirty = true
        self.headingsDirty = true
        -- Значки проявятся вместе с полосой или отдельно, если сбор точек задержится.
        self.markerFadeIn = true
        local fadeIn = self.frame.fadeIn
        if fadeIn and fadeIn:IsPlaying() then
            fadeIn:SetScript("OnFinished", function()
                RestoreAfterFadeIn(self)
            end)
        else
            RestoreAfterFadeIn(self)
        end
        if not self.updating then
            self.events:SetScript("OnUpdate", function(_, elapsed)
                self:OnUpdate(elapsed)
            end)
            self.updating = true
        end
    end
end

-- Запоминает скрытие полосы окнами интерфейса.
function Compass:SetContextHidden(hidden)
    if self.hiddenByContext == hidden then
        return
    end
    self.hiddenByContext = hidden
    self:RefreshVisibility()
end

-- Запоминает скрытие полосы индикатором опыта.
function Compass:SetProgressHidden(hidden)
    if self.hiddenByProgress == hidden then
        return
    end
    self.hiddenByProgress = hidden
    self:RefreshVisibility()
end

-- Обновляет скрытие в подземелье, битве питомцев и транспорте; поле боя оставляет видимым.
function Compass:RefreshInstanceState()
    local inInstance, instanceType = IsInInstance()
    self.inInstance = inInstance and instanceType ~= "pvp"
    self.hiddenByGame = C_PetBattles.IsInBattle() or UnitHasVehicleUI("player")
    self:RefreshVisibility()
end

-- Обрабатывает кадр: сбор точек, азимуты и отрисовка.
function Compass:OnUpdate(elapsed)
    if self.inInstance or self.hiddenByGame or self.hiddenByContext or self.hiddenByProgress or not self.frame:IsVisible() then
        self:HidePeek()
        return
    end
    self.discoveryClock = self.discoveryClock + elapsed
    self.markerClock = self.markerClock + elapsed
    self.sortElapsed = self.sortElapsed + elapsed
    if
        self.discoveryDirty
        or self.waypointDirty
        or self.discoveryJob
        or self.discoveryPending
        or self.discoveryClock >= self.discoveryNext
    then
        self:DiscoverMarkers()
    end
    self:RefreshNavigationHide()
    self:RefreshRange()
    self:RefreshBearings()
    local facing = self:GetFacing()
    local geometryReady = self:LayoutArtwork()
    if
        geometryReady
        and (
            self.renderDirty
            or self.markerRevealPending
            or self.markerSmoothPending
            or self.arrivalBlendPending
            or self.nearbyMotionPending
            or self.renderFacing ~= facing
        )
    then
        self:Render(facing, true, elapsed)
    end
end

-- Обрабатывает игровые события полосы.
function Compass:OnEvent(event, payload)
    if event == "MODIFIER_STATE_CHANGED" then
        if payload == "LALT" or payload == "RALT" then
            self:RefreshPeekModifier()
        end
        return
    end
    if event == "CVAR_UPDATE" or event == "NAVIGATION_FRAME_CREATED" or event == "NAVIGATION_FRAME_DESTROYED" then
        self:RefreshNavigationHide()
        return
    end
    if event == "QUESTLINE_UPDATE" and Compass.Readable(payload) == true then
        self.compassOfferRequestRequired = true
    elseif event == "USER_WAYPOINT_UPDATED" then
        self.dismissedNavigationKey = nil
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        self.dismissedNavigationKey = nil
    end
    if event == "PLAYER_ENTERING_WORLD" then
        self:RefreshInstanceState()
    end
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        self.headingsDirty = true
        self.renderDirty = true
        if not self.inInstance then
            self:LayoutArtwork()
        end
    elseif not self.inInstance then
        self:InvalidateSource(event)
    end
end

-- Создаёт полосу навигации и запускает её.
function ConsoleMenu:SetCompassFrame()
    if Compass.frame then
        return
    end
    local C = Compass.Constants
    Compass:InitLocale()
    Compass:InitPixel()
    Compass.markers, Compass.bearings = {}, {}
    Compass.selectionKeys = {}
    Compass.arrivalMarkers, Compass.arrivalKeys, Compass.arrivalLeaving, Compass.nearbyFading = {}, {}, {}, {}
    Compass.hideNavigationOnBar = false
    Compass.arrivalBlend, Compass.arrivalEase, Compass.arrivalBlendPending, Compass.arrivalFanReveal = 0, 0, false, false
    Compass.viewAngle = C.VIEW_ANGLE
    Compass.range = C.RANGE_WALK
    Compass.iconSize = C.ICON_SIZE
    Compass.hiddenByContext = false
    Compass.hiddenByProgress = ConsoleMenuFrame.StatusTrackingFrame
        and ConsoleMenuFrame.StatusTrackingFrame:IsShown()
        or false
    Compass:InitializeDiscovery()
    Compass:RefreshRange()

    local parent = ConsoleMenuFrame
    local frame = CreateFrame("Frame", "CompassFrame", parent)
    frame:SetSize(C.WIDTH, C.HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(parent:GetFrameLevel() + 1)
    frame:SetClampedToScreen(true)
    frame:SetClipsChildren(false)
    frame:SetPoint("TOP", parent, "TOP", 0, DefaultOffsetY())
    frame:EnableMouse(false)
    frame:Hide()
    ConsoleMenuFrame.CompassFrame = frame
    Compass.frame = frame
    ConsoleMenu:InitFadeAnimations(frame, 0.2)

    Compass:CreateView()
    Compass:StyleView()

    frame:SetScript("OnHide", function()
        Compass:HidePeek()
        Compass:HideDetail(true)
        Compass:SetLabelShadowShown(false, true)
    end)
    frame:SetScript("OnShow", function()
        if Compass.inInstance or Compass.hiddenByGame then
            frame:Hide()
        else
            Compass:RefreshPeekModifier()
            Compass.renderDirty = true
        end
    end)
    frame:SetScript("OnSizeChanged", function()
        Compass:LayoutArtwork()
    end)

    local events = CreateFrame("Frame")
    Compass.events = events
    for _, eventName in ipairs(EVENTS) do
        events:RegisterEvent(eventName)
    end
    events:RegisterUnitEvent("UNIT_PHASE", "player")
    events:SetScript("OnEvent", function(_, event, payload)
        Compass:OnEvent(event, payload)
    end)

    Compass:RefreshInstanceState()
end
