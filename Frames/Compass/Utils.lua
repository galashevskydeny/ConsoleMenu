-- Utils.lua
-- Безопасное чтение скрытых значений карты и сбор записи точки.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass

-- Проверяет, скрыто ли значение клиентом.
function Compass.IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

-- Возвращает значение, если его можно читать.
function Compass.Readable(value)
    if not Compass.IsSecret(value) then
        return value
    end
end

-- Возвращает конечное число или ничего.
function Compass.Number(value)
    value = Compass.Readable(value)
    if type(value) == "number" and value == value and math.abs(value) < math.huge then
        return value
    end
end

-- Читает пару координат из таблицы положения.
function Compass.ReadPosition(position)
    position = Compass.Readable(position)
    if type(position) == "table" then
        return Compass.Number(position.x), Compass.Number(position.y)
    end
end

-- Проверяет, что координаты лежат на карте.
function Compass.IsMapPosition(position)
    local x, y = Compass.ReadPosition(position)
    return x ~= nil and y ~= nil and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

-- Проверяет, включена ли стандартная навигация игры.
function Compass:IsGameNavigationEnabled()
    return self.Readable(C_CVar.GetCVarBool("showInGameNavigation")) == true
end

-- Проверяет, что игровой указатель сейчас доступен.
function Compass:IsGameNavigationPointerAvailable()
    local state = self.Number(C_Navigation.GetTargetState())
    return state == Enum.NavigationState.Occluded or state == Enum.NavigationState.InRange
end

-- Проверяет, нужно ли прятать выбранную цель с полосы.
function Compass:IsGameNavigationHidingTarget()
    return self:IsGameNavigationEnabled() and self:IsGameNavigationPointerAvailable()
end

-- Проверяет, совпадает ли точка с выбранной целью.
function Compass:IsTrackedPoint(marker, target)
    if not marker then
        return false
    end
    if marker.navigation then
        return true
    end
    if not target then
        return false
    end
    if marker.key == target.key or (marker.sourceKey or marker.key) == (target.sourceKey or target.key) then
        return true
    end
    local destination, tracked = marker.destination, target.destination
    if not destination or not tracked then
        return false
    end
    return destination.mapID == tracked.mapID
        and math.abs(destination.x - tracked.x) < self.Constants.PEEK_DESTINATION_EPSILON
        and math.abs(destination.y - tracked.y) < self.Constants.PEEK_DESTINATION_EPSILON
end

-- Решает, достаточно ли ярок значок, чтобы показать название и подпись.
function Compass:ShouldShowMarkerLabel(shown, alpha)
    local C = self.Constants
    alpha = alpha or 0
    if shown then
        return alpha >= C.LABEL_HIDE_ALPHA
    end
    return alpha >= C.LABEL_SHOW_ALPHA
end

-- Возвращает устойчивый логический признак: новое значение принимается после паузы.
local function SettleFlag(state, incoming, now, hold, force)
    if not state then
        return { value = incoming, wanted = incoming, since = now }
    end
    if force or state.value == nil then
        state.value, state.wanted, state.since = incoming, incoming, now
        return state
    end
    if state.value == incoming then
        state.wanted = incoming
        state.since = now
        return state
    end
    if state.wanted ~= incoming then
        state.wanted = incoming
        state.since = now
        return state
    end
    if now - state.since >= hold then
        state.value = incoming
        state.since = now
    end
    return state
end

-- Проверяет, стоит ли персонаж внутри области выполнения задания.
function Compass:IsInsideQuestArea(marker)
    local questID = marker and self.Number(marker.questID)
    if not questID then
        return false
    end
    local isInside = C_Minimap and C_Minimap.IsInsideQuestBlob
    local raw = isInside and self.Readable(isInside(questID)) == true
    local cache = self.questAreaState
    if not cache then
        cache = {}
        self.questAreaState = cache
    end
    local state = SettleFlag(cache[questID], raw, GetTime(), self.Constants.QUEST_AREA_HOLD)
    cache[questID] = state
    return state.value
end

-- Точка в радиусе прибытия или внутри области выполнения задания.
function Compass:IsNearbyCandidate(marker, limit)
    if not marker then
        return false
    end
    local distanceSquared = marker.distanceSquared
    if type(distanceSquared) == "number" and distanceSquared <= (limit or self.Constants.NEARBY_YARDS_SQUARED) then
        return true
    end
    return self:IsInsideQuestArea(marker)
end

-- Проверяет, что точку не следует рисовать из-за игрового указателя.
function Compass:ShouldHideNavigationMarker(marker)
    if self.hideNavigationOnBar ~= true or not self:IsTrackedPoint(marker, self.navigationTarget) then
        return false
    end
    -- Не прячем выбранное задание, если персонаж уже в области его выполнения.
    return not self:IsInsideQuestArea(marker)
end

-- Обновляет признак скрытия выбранной цели и помечает полосу к перерисовке.
function Compass:RefreshNavigationHide(force)
    local hide = self:IsGameNavigationHidingTarget()
    local state = SettleFlag(
        self.hideNavigationState,
        hide,
        GetTime(),
        self.Constants.NAVIGATION_HIDE_HOLD,
        force
    )
    self.hideNavigationState = state
    hide = state.value and true or false
    if self.hideNavigationOnBar == hide then
        return false
    end
    self.hideNavigationOnBar = hide
    self.selectionDirty = true
    self.renderDirty = true
    self.bearingsDirty = true
    return true
end

-- Возвращает ширину и высоту значка по атласу с учётом заданного размера или запасной величины.
function Compass.AtlasSize(atlas)
    local fallback = Compass.Constants.ICON_SIZE
    if type(atlas) ~= "string" or atlas == "" then
        return fallback, fallback
    end
    local width, height
    local info = Compass.Readable(C_Texture.GetAtlasInfo(atlas))
    if type(info) == "table" then
        width, height = Compass.Number(info.width), Compass.Number(info.height)
    end
    if not width or not height or width <= 0 or height <= 0 then
        width, height = fallback, fallback
    end
    local size = Compass.Constants.MARKER_ATLAS_SIZES[atlas:lower()]
    if not size or size <= 0 then
        return width, height
    end
    local longest = math.max(width, height)
    local fit = size / longest
    return width * fit, height * fit
end

-- Ставит запасной размер, когда вместо атласа используется текстура.
function Compass:UseTextureSize(marker)
    if not marker then
        return
    end
    local size = self.Constants.ICON_SIZE
    marker.iconWidth, marker.iconHeight = size, size
end

-- Возвращает круг точки на карте для класса задания.
function Compass.QuestPinBackground(classification)
    local C = Compass.Constants
    return C.QUEST_PIN_BACKGROUNDS[classification] or C.QUEST_PIN_BACKGROUND
end

-- Возвращает жёлтый круг выбранного задания в процессе.
function Compass.QuestPinBackgroundFocused(classification)
    local C = Compass.Constants
    return C.QUEST_PIN_BACKGROUNDS_FOCUSED[classification] or C.QUEST_PIN_BACKGROUND_FOCUSED
end

-- Назначает символу круглую подложку, выбранный круг и, при необходимости, рамку вокруг круга.
function Compass:ApplyQuestPinArt(marker, innerAtlas, backgroundAtlas, underlayAtlas, innerWidth, innerHeight, focusedBackground)
    if not marker then
        return
    end
    if type(innerAtlas) == "string" and innerAtlas ~= "" then
        marker.atlas = innerAtlas
        if innerWidth and innerHeight and innerWidth > 0 and innerHeight > 0 then
            marker.iconWidth, marker.iconHeight = innerWidth, innerHeight
        else
            marker.iconWidth, marker.iconHeight = self.AtlasSize(innerAtlas)
        end
    end
    if type(backgroundAtlas) == "string" and backgroundAtlas ~= "" then
        marker.backgroundAtlas = backgroundAtlas
        marker.backgroundWidth, marker.backgroundHeight = self.AtlasSize(backgroundAtlas)
    else
        marker.backgroundAtlas, marker.backgroundWidth, marker.backgroundHeight = nil, nil, nil
    end
    if type(focusedBackground) == "string" and focusedBackground ~= "" then
        marker.backgroundAtlasFocused = focusedBackground
        marker.backgroundWidthFocused, marker.backgroundHeightFocused = self.AtlasSize(focusedBackground)
    else
        marker.backgroundAtlasFocused, marker.backgroundWidthFocused, marker.backgroundHeightFocused = nil, nil, nil
    end
    if type(underlayAtlas) == "string" and underlayAtlas ~= "" then
        marker.underlayAtlas = underlayAtlas
        marker.underlayWidth, marker.underlayHeight = self.AtlasSize(underlayAtlas)
    else
        marker.underlayAtlas, marker.underlayWidth, marker.underlayHeight = nil, nil, nil
    end
end

-- Добавляет точку на полосу, если у неё есть имя и координаты.
function Compass:AddMarker(markers, key, position, name, atlas, priority, kind, destination)
    local C = self.Constants
    local x, y = self.ReadPosition(position)
    name, atlas = self.Readable(name), self.Readable(atlas)
    if not x or not y or type(name) ~= "string" or name == "" then
        return
    end
    if type(atlas) ~= "string" or atlas == "" then
        atlas = C.FALLBACK_ATLAS
    end
    local iconWidth, iconHeight = self.AtlasSize(atlas)
    local marker = {
        key = key,
        x = x,
        y = y,
        name = name,
        atlas = atlas,
        iconWidth = iconWidth,
        iconHeight = iconHeight,
        priority = priority,
        kind = kind,
        destination = destination or { mapID = self.mapID, x = x, y = y },
    }
    markers[#markers + 1] = marker
    return marker
end
