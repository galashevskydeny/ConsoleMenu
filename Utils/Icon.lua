-- Icon.lua
-- Библиотека для работы с иконками по аналогии с WeakAuras Icon
--
-- Пример использования:
--   local icon = ConsoleMenu:CreateIcon(parentFrame, {
--       id = "MyIcon",
--       width = 64,
--       height = 64,
--       displayIcon = "Interface\\Icons\\Spell_Nature_HealingTouch",
--       applyMask = true
--   })
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
        mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Mask")
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
    
    -- Базовые координаты (0,0,0,1,1,0,1,1)
    region.currentCoord[1], region.currentCoord[2], region.currentCoord[3], region.currentCoord[4],
    region.currentCoord[5], region.currentCoord[6], region.currentCoord[7], region.currentCoord[8]
    = 0, 0, 0, 1, 1, 0, 1, 1

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

-- Значения по умолчанию
local default = {
    icon = true,
    desaturate = false,
    iconSource = -1, -- Источник иконки: -1 = state.icon, 0 = displayIcon, >0 = states[triggernumber].icon
    width = 64,
    height = 64,
    selfPoint = "CENTER",
    anchorPoint = "CENTER",
    anchorFrameType = "SCREEN",
    xOffset = 0,
    yOffset = 0,
    zoom = 0,
    keepAspectRatio = false,
    cooldownTextDisabled = false,
    cooldownSwipe = true,
    cooldownEdge = false,
    useCooldownModRate = true,
    displayIcon = "Interface\\Icons\\INV_Misc_QuestionMark",
    applyMask = false
}

-- Создание иконки
function ConsoleMenu:CreateIcon(parent, data)
    data = data or {}
    
    -- Применяем значения по умолчанию
    for k, v in pairs(default) do
        if data[k] == nil then
            data[k] = v
        end
    end
    
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
    SetTextureOrAtlas(icon, data.displayIcon)
    
    -- Создание cooldown фрейма
    local frameId = (data.id or "Icon"):lower():gsub(" ", "_")
    if _G["ConsoleMenuCooldown"..frameId] then
        local baseFrameId = frameId
        local num = 2
        while _G["ConsoleMenuCooldown"..frameId] do
            frameId = baseFrameId..num
            num = num + 1
        end
    end
    region.frameId = frameId
    
    local cooldown = CreateFrame("Cooldown", "ConsoleMenuCooldown"..frameId, region, "CooldownFrameTemplate")
    region.cooldown = cooldown
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawBling(false)
    cooldown.SetDrawSwipeOrg = cooldown.SetDrawSwipe
    cooldown.SetDrawSwipe = function() end
    cooldown:Hide()
    
    -- Инициализация данных региона
    region.width = data.width
    region.height = data.height
    region.scalex = 1
    region.scaley = 1
    region.keepAspectRatio = data.keepAspectRatio
    region.zoom = data.zoom
    region.texXOffset = data.texXOffset or 0
    region.texYOffset = data.texYOffset or 0
    region.iconSource = data.iconSource
    region.displayIcon = data.displayIcon
    region.states = data.states or {}
    region.state = data.state or {}
    
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
        if data.applyMask then
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
    
    -- Функция установки cooldown swipe
    function region:SetCooldownSwipe(cooldownSwipe)
        self.cooldownSwipe = cooldownSwipe
        cooldown:SetDrawSwipeOrg(cooldownSwipe)
    end
    
    -- Функция установки cooldown edge
    function region:SetCooldownEdge(cooldownEdge)
        self.cooldownEdge = cooldownEdge
        cooldown:SetDrawEdge(cooldownEdge)
    end
    
    -- Функция скрытия текста cooldown
    function region:SetHideCountdownNumbers(cooldownTextDisabled)
        cooldown:SetHideCountdownNumbers(cooldownTextDisabled)
    end
    
    -- Функция установки inverse
    function region:SetInverse(inverse)
        if self.inverseDirection == inverse then
            return
        end
        self.inverseDirection = inverse
        self:UpdateEffectiveInverse()
    end
    
    function region:UpdateEffectiveInverse()
        local effectiveReverse = not self.inverseDirection == not cooldown.inverse
        cooldown:SetReverse(effectiveReverse)
        if (cooldown.expirationTime and cooldown.duration and cooldown:IsShown()) then
            cooldown:SetCooldown(0, 0)
            cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration,
                                 cooldown.duration,
                                 cooldown.useCooldownModRate and cooldown.modRate or nil)
        end
    end
    
    -- Инициализация cooldown
    cooldown.expirationTime = nil
    cooldown.duration = nil
    cooldown.modRate = nil
    cooldown.useCooldownModRate = data.useCooldownModRate
    
    -- Функции обновления cooldown
    if data.cooldown then
        function region:UpdateValue()
            cooldown.value = self.value
            cooldown.total = self.total
            cooldown.modRate = nil
            if (self.value >= 0 and self.value <= self.total) then
                cooldown:Show()
                cooldown:SetCooldown(GetTime() - (self.total - self.value), self.total)
                cooldown:Pause()
            else
                cooldown:Hide()
            end
        end
        
        function region:UpdateTime()
            if self.paused then
                cooldown:Pause()
            else
                cooldown:Resume()
            end
            if (self.duration > 0 and self.expirationTime > GetTime() and self.expirationTime ~= math.huge) then
                cooldown:Show()
                cooldown.expirationTime = self.expirationTime
                cooldown.duration = self.duration
                cooldown.modRate = self.modRate
                cooldown.inverse = self.inverse
                self:UpdateEffectiveInverse()
                cooldown:SetCooldown(self.expirationTime - self.duration, self.duration,
                                     cooldown.useCooldownModRate and self.modRate or nil)
            else
                cooldown.expirationTime = self.expirationTime
                cooldown.duration = self.duration
                cooldown.modRate = self.modRate
                cooldown:Hide()
            end
        end
        
        function region:PreShow()
            if (cooldown.duration and cooldown.duration > 0.01 and cooldown.duration ~= math.huge and cooldown.expirationTime ~= math.huge) then
                cooldown:Show()
                cooldown:SetCooldown(cooldown.expirationTime - cooldown.duration,
                                     cooldown.duration,
                                     cooldown.useCooldownModRate and cooldown.modRate or nil)
                cooldown:Resume()
            end
        end
    end
    
    -- Применение начальных настроек
    region:SetDesaturated(data.desaturate)
    region:SetInverse(data.inverse)
    region:SetHideCountdownNumbers(data.cooldownTextDisabled)
    region:SetCooldownSwipe(data.cooldownSwipe)
    region:SetCooldownEdge(data.cooldownEdge)
    region:UpdateSize()
    region:UpdateIcon()
    
    -- Установка точки привязки
    if data.anchorPoint and data.selfPoint then
        region:SetPoint(data.selfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset)
    end
    
    -- Установка слоя
    region:SetFrameStrata(data.frameStrata or "MEDIUM")
    
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
    if data.inverse ~= nil then
        region:SetInverse(data.inverse)
    end
    if data.cooldownTextDisabled ~= nil then
        region:SetHideCountdownNumbers(data.cooldownTextDisabled)
    end
    if data.cooldownSwipe ~= nil then
        region:SetCooldownSwipe(data.cooldownSwipe)
    end
    if data.cooldownEdge ~= nil then
        region:SetCooldownEdge(data.cooldownEdge)
    end
    
    region:UpdateSize()
    region:UpdateIcon()
end

