-- Icon.lua
-- Библиотека для работы с иконками по аналогии с WeakAuras Icon
--
-- Пример использования:
--   local icon = ConsoleMenu:CreateIcon(parentFrame, 64, 64, "Interface\\Icons\\Spell_Nature_HealingTouch", true)
--
--   -- Обновление иконки
--   icon:SetIcon("Interface\\Icons\\Spell_Fire_Fireball")
--   icon:SetZoom(0.2) -- Увеличение
--
--   -- Модификация существующей иконки
--   ConsoleMenu:ModifyIcon(icon, {
--       width = 128,
--       height = 128
--   })

local ConsoleMenu = _G.ConsoleMenu

-- Локальная функция для применения маски к текстуре
local function ApplyMaskToTexture(texture)
    if not texture or not texture:GetParent() then
        return
    end
    
    -- Проверка, существует ли уже маска
    if not texture.mask then
        -- Создаем маску
        local mask = texture:GetParent():CreateMaskTexture()
        
        -- Устанавливаем текстуру маски
        mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png")
        mask:SetAllPoints(texture)
        
        -- Применяем маску
        texture:AddMaskTexture(mask)
        
        -- Сохраняем ссылку на маску
        texture.mask = mask
    end
end

-- Функция для установки текстуры или атласа
local function SetTextureOrAtlas(texture, path)
    if not texture then
        return
    end
    
    if not path or path == "" then
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        return
    end
    
    -- Проверяем, является ли путь атласом
    local atlasInfo = C_Texture.GetAtlasInfo(path)
    if atlasInfo then
        texture:SetAtlas(path)
    else
        texture:SetTexture(path)
    end
end

-- Вычисление координат текстуры с учетом zoom и aspect ratio
local function GetTexCoord(region, texWidth, aspectRatio, xOffset, yOffset)
    region.currentCoord = region.currentCoord or {}
    
    -- Вычисляем растяжение на 4 пикселя
    -- Чтобы растянуть текстуру, нужно показать большую часть текстуры
    -- Для этого используем координаты, сжатые к центру
    local width = region.width * math.abs(region.scalex or 1)
    local height = region.height * math.abs(region.scaley or 1)
    local stretchX = width > 0 and (4 / (width + 4)) or 0.0588
    local stretchY = height > 0 and (4 / (height + 4)) or 0.0588
    
    -- Базовые координаты с растяжением на 4 пикселя
    -- Используем координаты внутри 0-1, но сжатые к центру, чтобы показать большую часть текстуры
    region.currentCoord[1], region.currentCoord[2], region.currentCoord[3], region.currentCoord[4],
    region.currentCoord[5], region.currentCoord[6], region.currentCoord[7], region.currentCoord[8]
    = stretchX, stretchY, stretchX, 1 - stretchY, 1 - stretchX, stretchY, 1 - stretchX, 1 - stretchY

    local xRatio = aspectRatio < 1 and aspectRatio or 1
    local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1
    
    for i, coord in ipairs(region.currentCoord) do
        if i % 2 == 1 then
            region.currentCoord[i] = (coord - 0.5) * texWidth * xRatio + 0.5 - (xOffset or 0)
        else
            region.currentCoord[i] = (coord - 0.5) * texWidth * yRatio + 0.5 - (yOffset or 0)
        end
    end

    return unpack(region.currentCoord)
end

-- Создание иконки
function ConsoleMenu:CreateIcon(parent, width, height, displayIcon, applyMask)
    width = width or 64
    height = height or 64
    displayIcon = displayIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    applyMask = applyMask or true
    
    local region = CreateFrame("Frame", nil, parent)
    region.regionType = "icon"
    region:SetMovable(true)
    region:SetResizable(true)
    region:SetResizeBounds(1, 1)
    
    -- Создание текстуры иконки
    local icon = region:CreateTexture(nil, "BACKGROUND")
    icon:SetSnapToPixelGrid(false)
    icon:SetTexelSnappingBias(0)
    icon:SetAllPoints(region)
    region.icon = icon
    
    -- Установка текстуры по умолчанию
    SetTextureOrAtlas(icon, displayIcon)
    
    -- Инициализация данных региона
    region.width = width
    region.height = height
    region.scalex = 1
    region.scaley = 1
    region.keepAspectRatio = false
    region.zoom = 0
    region.texXOffset = 0
    region.texYOffset = 0
    region.iconSource = -1
    region.displayIcon = displayIcon
    region.states = {}
    region.state = {}
    region.applyMask = applyMask
    
    -- Функция обновления размера
    function region:UpdateSize()
        local width = self.width * math.abs(self.scalex)
        local height = self.height * math.abs(self.scaley)
        self:SetWidth(width)
        self:SetHeight(height)
        self:UpdateTexCoords()
    end
    
    -- Функция обновления координат текстуры
    function region:UpdateTexCoords()
        local mirror_h = self.scalex < 0
        local mirror_v = self.scaley < 0
        
        local texWidth = 1 - 0.5 * self.zoom
        local aspectRatio
        
        if not self.keepAspectRatio then
            aspectRatio = 1
        else
            local width = self.width * math.abs(self.scalex)
            local height = self.height * math.abs(self.scaley)
            
            if width == 0 or height == 0 then
                aspectRatio = 1
            else
                aspectRatio = width / height
            end
        end
        
        local ulx, uly, llx, lly, urx, ury, lrx, lry
            = GetTexCoord(self, texWidth, aspectRatio, self.texXOffset, -self.texYOffset)
        
        if mirror_h then
            if mirror_v then
                icon:SetTexCoord(lrx, lry, urx, ury, llx, lly, ulx, uly)
            else
                icon:SetTexCoord(urx, ury, lrx, lry, ulx, uly, llx, lly)
            end
        else
            if mirror_v then
                icon:SetTexCoord(llx, lly, ulx, uly, lrx, lry, urx, ury)
            else
                icon:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
            end
        end
    end
    
    -- Функция установки иконки
    function region:SetIcon(iconPath)
        if self.displayIcon == iconPath then
            return
        end
        self.displayIcon = iconPath
        self:UpdateIcon()
    end
    
    -- Функция установки источника иконки
    function region:SetIconSource(source)
        if self.iconSource == source then
            return
        end
        self.iconSource = source
        self:UpdateIcon()
    end
    
    -- Функция обновления иконки
    function region:UpdateIcon()
        local iconPath
        
        if self.iconSource == -1 then
            iconPath = self.state.icon
        elseif self.iconSource == 0 then
            iconPath = self.displayIcon
        else
            local triggernumber = self.iconSource
            if triggernumber and self.states[triggernumber] then
                iconPath = self.states[triggernumber].icon
            end
        end
        
        iconPath = iconPath or self.displayIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
        SetTextureOrAtlas(icon, iconPath)
        
        -- Применение маски, если требуется
        if self.applyMask then
            ApplyMaskToTexture(icon)
        end
    end
    
    -- Функция установки десатурации
    function region:SetDesaturated(b)
        icon:SetDesaturated(b)
    end
    
    -- Функция установки размера
    function region:SetRegionWidth(width)
        self.width = width
        self:UpdateSize()
    end
    
    function region:SetRegionHeight(height)
        self.height = height
        self:UpdateSize()
    end
    
    -- Функция масштабирования
    function region:Scale(scalex, scaley)
        if self.scalex == scalex and self.scaley == scaley then
            return
        end
        self.scalex = scalex
        self.scaley = scaley
        self:UpdateSize()
    end
    
    -- Функция установки zoom
    function region:SetZoom(zoom)
        self.zoom = zoom
        self:UpdateTexCoords()
    end
    
    -- Применение начальных настроек
    region:SetDesaturated(false)
    region:UpdateSize()
    region:UpdateIcon()
    
    -- Установка слоя
    region:SetFrameStrata("MEDIUM")
    
    return region
end

-- Модификация существующей иконки
function ConsoleMenu:ModifyIcon(region, data)
    if not region or region.regionType ~= "icon" then
        return
    end
    
    data = data or {}
    
    -- Обновление данных
    if data.width then
        region.width = data.width
    end
    if data.height then
        region.height = data.height
    end
    if data.keepAspectRatio ~= nil then
        region.keepAspectRatio = data.keepAspectRatio
    end
    if data.zoom ~= nil then
        region.zoom = data.zoom
    end
    if data.texXOffset ~= nil then
        region.texXOffset = data.texXOffset
    end
    if data.texYOffset ~= nil then
        region.texYOffset = data.texYOffset
    end
    if data.iconSource ~= nil then
        region.iconSource = data.iconSource
    end
    if data.displayIcon ~= nil then
        region.displayIcon = data.displayIcon
    end
    if data.states then
        region.states = data.states
    end
    if data.state then
        region.state = data.state
    end
    
    -- Применение изменений
    if data.desaturate ~= nil then
        region:SetDesaturated(data.desaturate)
    end
    
    region:UpdateSize()
    region:UpdateIcon()
end
