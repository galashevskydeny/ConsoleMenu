-- Position.lua
-- Положение игрока на карте и перевод точек с других карт.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local Number = Compass.Number
local ReadPosition = Compass.ReadPosition

-- Читает положение игрока: мир непрерывно, карта — раз в секунду.
function Compass:ReadPositionOnMap()
    local C = self.Constants
    local north, west, _, instance = UnitPosition("player")
    north, west, instance = Number(north), Number(west), Number(instance)
    if not north or not west or not instance then
        self.positionInstance = nil
        return ReadPosition(C_Map.GetPlayerMapPosition(self.mapID, "player"))
    end
    if self.positionInstance ~= instance or self.discoveryClock >= self.positionNextSync then
        if Number(C_Map.GetBestMapForUnit("player")) ~= self.mapID then
            self.discoveryDirty = true
            return
        end
        local x, y = ReadPosition(C_Map.GetPlayerMapPosition(self.mapID, "player"))
        self.positionNextSync = self.discoveryClock + C.POSITION_SYNC_INTERVAL
        if x and y then
            self.positionInstance = instance
            self.positionMapX, self.positionMapY = x, y
            self.positionNorth, self.positionWest = north, west
        elseif self.positionInstance ~= instance then
            return
        end
    end
    if self.positionMapX and self.positionMapY then
        return self.positionMapX - (west - self.positionWest) / self.mapWidth,
            self.positionMapY - (north - self.positionNorth) / self.mapHeight
    end
end

-- Переносит точку с другой карты на текущую через мировые координаты.
function Compass:ProjectDestination(mapID, x, y)
    if mapID == self.mapID then
        return { x = x, y = y }
    end
    local continent, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    local ownContinent = C_Map.GetWorldPosFromMapPos(self.mapID, CreateVector2D(0, 0))
    continent, ownContinent = Number(continent), Number(ownContinent)
    local worldX, worldY = ReadPosition(world)
    if not continent or continent ~= ownContinent or not worldX or not worldY then
        return
    end
    local projectedMap, position = C_Map.GetMapPosFromWorldPos(continent, CreateVector2D(worldX, worldY), self.mapID)
    if Number(projectedMap) == self.mapID then
        x, y = ReadPosition(position)
        if x and y then
            return { x = x, y = y }
        end
    end
end

-- Обновляет идентификатор и размеры текущей карты.
function Compass:RefreshMap()
    self.bearingsDirty = true
    wipe(self.markers)
    self.mapID = Number(C_Map.GetBestMapForUnit("player"))
    self.mapWidth, self.mapHeight = nil, nil
    self.positionInstance = nil
    if not self.mapID then
        return
    end
    local width, height = C_Map.GetMapWorldSize(self.mapID)
    width, height = Number(width), Number(height)
    if not width or not height or width <= 0 or height <= 0 then
        return
    end
    self.mapWidth, self.mapHeight = width, height
end
