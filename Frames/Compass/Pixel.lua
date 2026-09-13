-- Pixel.lua
-- Привязка координат полосы к пиксельной сетке экрана.

local ConsoleMenu = _G.ConsoleMenu
local Compass = ConsoleMenu.Compass
local REFERENCE_HEIGHT = 768

-- Служба округления к пикселям экрана.
local Pixel = {}
Compass.Pixel = Pixel

-- Текущий шаг пикселя относительно эталонной высоты.
local screenScale = 1

-- Пересчитывает шаг пикселя по физической высоте экрана.
local function UpdateScreenScale()
    local _, physicalHeight = GetPhysicalScreenSize()
    if not physicalHeight or physicalHeight == 0 then
        screenScale = REFERENCE_HEIGHT / 1080
    else
        screenScale = REFERENCE_HEIGHT / physicalHeight
    end
end

-- Возвращает текущий шаг пикселя.
function Pixel:GetScale()
    return screenScale
end

-- Округляет значение к ближайшему пикселю.
function Pixel:Snap(value, scale)
    if not value then
        return 0
    end
    if Compass.IsSecret(value) then
        return value
    end
    local frameScale = scale or 1
    if frameScale < 0.01 then
        frameScale = 1
    end
    local step = screenScale / frameScale
    return math.floor(value / step + 0.5) * step
end

-- Переводит целое число пикселей в координаты интерфейса.
function Pixel:Multiple(count, scale)
    local n = count or 0
    if Compass.IsSecret(n) then
        return n
    end
    if n == 0 then
        return 0
    end
    local sign = n > 0 and 1 or -1
    local frameScale = scale or 1
    if frameScale < 0.01 then
        frameScale = 1
    end
    local step = screenScale / frameScale
    return sign * math.max(math.floor(math.abs(n) + 0.5), 1) * step
end

-- Переводит координату обратно в целое число пикселей.
function Pixel:ToCount(value, scale)
    if not value or Compass.IsSecret(value) then
        return 0
    end
    local frameScale = scale or 1
    if frameScale < 0.01 then
        frameScale = 1
    end
    local count = value / (screenScale / frameScale)
    local sign = count < 0 and -1 or 1
    return sign * math.floor(math.abs(count) + 0.5)
end

-- Создаёт слушатель смены разрешения и масштаба.
function Compass:InitPixel()
    UpdateScreenScale()
    if self.pixelEvents then
        return
    end
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    frame:RegisterEvent("UI_SCALE_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function()
        UpdateScreenScale()
        self.headingsDirty = true
        self.renderDirty = true
        if self.frame then
            self:LayoutArtwork()
        end
    end)
    self.pixelEvents = frame
end
