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

-- Проверяет, что точку не следует рисовать из-за игрового указателя.
function Compass:ShouldHideNavigationMarker(marker)
    return self.hideNavigationOnBar == true and self:IsTrackedPoint(marker, self.navigationTarget)
end

-- Обновляет признак скрытия выбранной цели и помечает полосу к перерисовке.
function Compass:RefreshNavigationHide()
    local hide = self:IsGameNavigationHidingTarget()
    if self.hideNavigationOnBar == hide then
        return false
    end
    self.hideNavigationOnBar = hide
    self.selectionDirty = true
    self.renderDirty = true
    self.bearingsDirty = true
    return true
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
    local marker = {
        key = key,
        x = x,
        y = y,
        name = name,
        atlas = atlas,
        sizeScale = C.MARKER_ATLAS_SCALES[atlas:lower()] or 1,
        offsetY = C.MARKER_ATLAS_OFFSETS[atlas:lower()] or 0,
        priority = priority,
        kind = kind,
        destination = destination or { mapID = self.mapID, x = x, y = y },
    }
    markers[#markers + 1] = marker
    return marker
end
